"""
Cloud Function: File Processor for Google Drive Push Notifications

Exclusively handles Google Drive Push Notifications.
Processes CSV files from a monitored Drive folder.
"""

import os
import json
import tempfile
from datetime import datetime
from google.cloud import storage, bigquery, pubsub_v1
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
MONITORED_FOLDER_ID = os.environ.get('MONITORED_FOLDER_ID', '')


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


def get_drive_service():
    """Get Drive service using default credentials"""
    return build('drive', 'v3')


def is_file_in_monitored_folder(drive_service, file_id):
    """Check if file is in the monitored folder"""
    if not MONITORED_FOLDER_ID:
        return True  # If no folder specified, accept all files
    
    try:
        file = drive_service.files().get(
            fileId=file_id,
            fields="parents"
        ).execute()
        
        parents = file.get('parents', [])
        return MONITORED_FOLDER_ID in parents
    except Exception as e:
        log_to_bigquery("ERROR", f"Error checking file parents: {e}", additional_info={"file_id": file_id})
        return False


def download_from_drive(file_id, file_name):
    """Download file from Google Drive"""
    try:
        drive_service = get_drive_service()
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
        
        # Define schema with proper field configurations
        schema = [
            bigquery.SchemaField("row_id", "INTEGER", mode="REQUIRED"),
            bigquery.SchemaField("order_id", "STRING", mode="REQUIRED"),
            bigquery.SchemaField("order_date", "STRING", mode="REQUIRED"),  # STRING instead of DATE
            bigquery.SchemaField("ship_date", "STRING", mode="REQUIRED"),   # STRING instead of DATE
            bigquery.SchemaField("ship_mode", "STRING", mode="REQUIRED"),
            bigquery.SchemaField("customer_id", "STRING", mode="REQUIRED"),
            bigquery.SchemaField("customer_name", "STRING", mode="REQUIRED"),
            bigquery.SchemaField("segment", "STRING", mode="REQUIRED"),
            bigquery.SchemaField("country", "STRING", mode="REQUIRED"),
            bigquery.SchemaField("city", "STRING", mode="REQUIRED"),
            bigquery.SchemaField("state", "STRING", mode="REQUIRED"),
            bigquery.SchemaField("postal_code", "FLOAT", mode="NULLABLE"),
            bigquery.SchemaField("region", "STRING", mode="REQUIRED"),
            bigquery.SchemaField("product_id", "STRING", mode="REQUIRED"),
            bigquery.SchemaField("category", "STRING", mode="REQUIRED"),
            bigquery.SchemaField("sub_category", "STRING", mode="REQUIRED"),
            bigquery.SchemaField("product_name", "STRING", mode="REQUIRED"),
            bigquery.SchemaField("sales", "FLOAT", mode="REQUIRED"),
        ]
        
        job_config = bigquery.LoadJobConfig(
            source_format=bigquery.SourceFormat.CSV,
            skip_leading_rows=1,
            schema=schema,
            write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
        )
        
        load_job = client.load_table_from_uri(
            gcs_uri,
            table_ref,
            job_config=job_config
        )
        
        load_job.result()
        
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


def process_single_file(file_id, file_name):
    """Process a single file (download → GCS → BigQuery → Pub/Sub)"""
    log_to_bigquery("INFO", f"Processing file: {file_name}", additional_info={"file_id": file_id})
    
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
        "file_id": file_id,
        "file_name": file_name,
        "gcs_uri": gcs_uri,
        "rows_loaded": rows_loaded
    }


def process_file(request):
    """
    Cloud Function entry point
    
    Handles ONLY Google Drive Push Notifications.
    """
    try:
        # Extract Drive notification headers
        channel_id = request.headers.get('X-Goog-Channel-ID', 'unknown')
        resource_state = request.headers.get('X-Goog-Resource-State', 'unknown')
        resource_id = request.headers.get('X-Goog-Resource-ID', 'unknown')
        
        log_to_bigquery("INFO", "Drive notification received", 
                       additional_info={
                           "channel_id": channel_id, 
                           "state": resource_state,
                           "resource_id": resource_id
                       })
        
        # Only process 'change' and 'add' notifications
        if resource_state not in ['change', 'add']:
            log_to_bigquery("INFO", f"Ignoring notification state: {resource_state}")
            return {"status": "ignored", "reason": f"state={resource_state}"}, 200
        
        # Get Drive service
        drive_service = get_drive_service()
        
        # Get recent files from monitored folder (simpler approach)
        try:
            # Query files in the monitored folder
            query = f"'{MONITORED_FOLDER_ID}' in parents and mimeType='text/csv' and trashed=false"
            
            results = drive_service.files().list(
                q=query,
                pageSize=10,
                fields="files(id, name, mimeType, modifiedTime)",
                orderBy="modifiedTime desc"
            ).execute()
            
            files = results.get('files', [])
            log_to_bigquery("INFO", f"Found {len(files)} CSV files in monitored folder")
            
            processed_files = []
            
            for file in files:
                file_id = file['id']
                file_name = file['name']
                
                # Process the file
                log_to_bigquery("INFO", f"Processing file from Drive notification: {file_name}", 
                               additional_info={"file_id": file_id})
                
                result = process_single_file(file_id, file_name)
                processed_files.append(result)
            
            log_to_bigquery("INFO", f"Drive notification processed: {len(processed_files)} files")
            
            return {
                "status": "success",
                "processed_files": len(processed_files),
                "files": processed_files
            }, 200
            
        except Exception as e:
            log_to_bigquery("ERROR", f"Failed to process Drive notification: {e}")
            return {"error": str(e)}, 500
            
    except Exception as e:
        log_to_bigquery("ERROR", f"Function failed: {str(e)}")
        return {"error": str(e)}, 500