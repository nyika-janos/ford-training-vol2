"""
Cloud Function: File Processor

Processes files from Google Drive:
1. Downloads file from Drive
2. Uploads to Cloud Storage
3. Loads to BigQuery
4. Logs each step
5. Publishes Pub/Sub message
"""

import os
import json
import tempfile
from datetime import datetime
from google.cloud import storage, bigquery, pubsub_v1
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload
import io


# Environment variables
PROJECT_ID = os.environ.get('PROJECT_ID')
BUCKET_NAME = os.environ.get('BUCKET_NAME')
DATASET_ID = os.environ.get('DATASET_ID')
LOG_TABLE_ID = os.environ.get('LOG_TABLE_ID')
RAW_DATA_TABLE_ID = os.environ.get('RAW_DATA_TABLE_ID')
PUBSUB_TOPIC = os.environ.get('PUBSUB_TOPIC')


def log_to_bigquery(log_level, message, source="cloud_function", user_id=None, additional_info=None):
    """Log message to BigQuery log table"""
    try:
        client = bigquery.Client(project=PROJECT_ID)
        table_ref = f"{PROJECT_ID}.{DATASET_ID}.{LOG_TABLE_ID}"
        
        row = {
            "timestamp": datetime.utcnow().isoformat(),
            "log_level": log_level,
            "message": message,
            "source": source,
            "user_id": user_id,
            "additional_info": json.dumps(additional_info) if additional_info else None
        }
        
        errors = client.insert_rows_json(table_ref, [row])
        if errors:
            print(f"BigQuery log error: {errors}")
    except Exception as e:
        print(f"Failed to log to BigQuery: {e}")


def download_from_drive(file_id, file_name):
    """Download file from Google Drive"""
    try:
        # Use default credentials (Service Account from function runtime)
        drive_service = build('drive', 'v3')
        
        request = drive_service.files().get_media(fileId=file_id)
        
        temp_file = tempfile.NamedTemporaryFile(delete=False, suffix=f"_{file_name}")
        fh = io.FileIO(temp_file.name, 'wb')
        downloader = MediaIoBaseDownload(fh, request)
        
        done = False
        while not done:
            status, done = downloader.next_chunk()
        
        fh.close()
        return temp_file.name
        
    except Exception as e:
        log_to_bigquery("ERROR", f"Failed to download from Drive: {e}", additional_info={"file_id": file_id})
        raise


def upload_to_gcs(local_file_path, gcs_file_name):
    """Upload file to Cloud Storage"""
    try:
        client = storage.Client(project=PROJECT_ID)
        bucket = client.bucket(BUCKET_NAME)
        blob = bucket.blob(gcs_file_name)
        
        blob.upload_from_filename(local_file_path)
        
        log_to_bigquery("INFO", f"File uploaded to GCS: {gcs_file_name}")
        return f"gs://{BUCKET_NAME}/{gcs_file_name}"
        
    except Exception as e:
        log_to_bigquery("ERROR", f"Failed to upload to GCS: {e}")
        raise


def load_to_bigquery(gcs_uri, file_name):
    """Load CSV from GCS to BigQuery"""
    try:
        client = bigquery.Client(project=PROJECT_ID)
        table_ref = f"{PROJECT_ID}.{DATASET_ID}.{RAW_DATA_TABLE_ID}"
        
        job_config = bigquery.LoadJobConfig(
            source_format=bigquery.SourceFormat.CSV,
            skip_leading_rows=1,
            autodetect=False,  # Use table schema
            write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
        )
        
        load_job = client.load_table_from_uri(
            gcs_uri,
            table_ref,
            job_config=job_config
        )
        
        load_job.result()  # Wait for job to complete
        
        log_to_bigquery("INFO", f"Data loaded to BigQuery from {file_name}")
        return load_job.output_rows
        
    except Exception as e:
        log_to_bigquery("ERROR", f"Failed to load to BigQuery: {e}")
        raise


def publish_pubsub_message(message_data):
    """Publish message to Pub/Sub topic"""
    try:
        publisher = pubsub_v1.PublisherClient()
        
        message_json = json.dumps(message_data)
        message_bytes = message_json.encode('utf-8')
        
        future = publisher.publish(PUBSUB_TOPIC, message_bytes)
        future.result()
        
        log_to_bigquery("INFO", "Pub/Sub message published", additional_info=message_data)
        
    except Exception as e:
        log_to_bigquery("ERROR", f"Failed to publish Pub/Sub message: {e}")
        raise


def process_file(request):
    """
    Cloud Function entry point
    Triggered by HTTP POST from Drive webhook
    """
    try:
        # Parse request
        request_json = request.get_json(silent=True)
        
        if not request_json:
            return {"error": "Invalid request"}, 400
        
        file_id = request_json.get('file_id')
        file_name = request_json.get('file_name', 'unknown.csv')
        
        if not file_id:
            return {"error": "file_id required"}, 400
        
        log_to_bigquery("INFO", f"Function triggered for file: {file_name}", additional_info={"file_id": file_id})
        
        # Step 1: Download from Drive
        log_to_bigquery("INFO", "Downloading file from Google Drive...")
        local_file = download_from_drive(file_id, file_name)
        log_to_bigquery("INFO", f"File downloaded: {file_name}")
        
        # Step 2: Upload to GCS
        log_to_bigquery("INFO", "Uploading file to Cloud Storage...")
        gcs_uri = upload_to_gcs(local_file, file_name)
        log_to_bigquery("INFO", f"File uploaded to GCS: {gcs_uri}")
        
        # Step 3: Load to BigQuery
        log_to_bigquery("INFO", "Loading data to BigQuery...")
        rows_loaded = load_to_bigquery(gcs_uri, file_name)
        log_to_bigquery("INFO", f"Data loaded to BigQuery: {rows_loaded} rows")
        
        # Step 4: Publish Pub/Sub message
        log_to_bigquery("INFO", "Publishing Pub/Sub message...")
        pubsub_data = {
            "file_id": file_id,
            "file_name": file_name,
            "gcs_uri": gcs_uri,
            "rows_loaded": rows_loaded,
            "timestamp": datetime.utcnow().isoformat()
        }
        publish_pubsub_message(pubsub_data)
        log_to_bigquery("INFO", "Pub/Sub message published")
        
        # Cleanup
        os.unlink(local_file)
        
        log_to_bigquery("INFO", f"File processing completed successfully: {file_name}")
        
        return {
            "status": "success",
            "file_name": file_name,
            "gcs_uri": gcs_uri,
            "rows_loaded": rows_loaded
        }, 200
        
    except Exception as e:
        log_to_bigquery("ERROR", f"Function failed: {str(e)}")
        return {"error": str(e)}, 500