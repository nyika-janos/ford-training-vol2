"""
Cloud Function: CSV Exporter

Triggered by Cloud Scheduler every hour.
Exports BigQuery aggregated tables to CSV in GCS.
"""

import os
import json
import uuid
from datetime import datetime
from google.cloud import bigquery
from google.cloud import storage
import pandas as pd
import functions_framework

# Environment variables
PROJECT_ID = os.environ.get('PROJECT_ID')
DATASET_ID = os.environ.get('DATASET_ID')
LOG_TABLE_ID = os.environ.get('LOG_TABLE_ID')
CSV_BUCKET = os.environ.get('CSV_BUCKET')
AGGREGATED_TABLES = os.environ.get('AGGREGATED_TABLES', '').split(',')

# Global run_id for this function execution
RUN_ID = str(uuid.uuid4())

def log_to_bigquery(log_level, message, source="csv_exporter", user_id=None, additional_info=None):
    """Log message to BigQuery log table"""
    try:
        client = bigquery.Client(project=PROJECT_ID)
        table_ref = f"{PROJECT_ID}.{DATASET_ID}.{LOG_TABLE_ID}"
        
        row = {
            "timestamp": datetime.utcnow().isoformat(),
            "run_id": RUN_ID,
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

def export_table_to_csv(table_id):
    """Export single BigQuery table to CSV in GCS"""
    try:
        # BigQuery client
        bq_client = bigquery.Client(project=PROJECT_ID)
        
        # Storage client
        storage_client = storage.Client(project=PROJECT_ID)
        bucket = storage_client.bucket(CSV_BUCKET)
        
        # Query all data from table
        query = f"SELECT * FROM `{PROJECT_ID}.{DATASET_ID}.{table_id}`"
        log_to_bigquery("INFO", f"Querying table: {table_id}")
        
        df = bq_client.query(query).to_dataframe()
        row_count = len(df)
        
        log_to_bigquery("INFO", f"Table {table_id} loaded: {row_count} rows")
        
        # Generate timestamp filename
        timestamp = datetime.now().strftime("%Y-%m-%d_%H%M%S")
        csv_filename = f"{timestamp}.csv"
        blob_path = f"{table_id}/{csv_filename}"
        
        # Convert DataFrame to CSV
        csv_data = df.to_csv(index=False)
        
        # Upload to GCS
        blob = bucket.blob(blob_path)
        blob.upload_from_string(csv_data, content_type='text/csv')
        
        log_to_bigquery("INFO", f"CSV uploaded: gs://{CSV_BUCKET}/{blob_path}", 
                       additional_info={"rows": row_count, "filename": csv_filename})
        
        return {
            "table": table_id,
            "rows": row_count,
            "path": f"gs://{CSV_BUCKET}/{blob_path}",
            "success": True
        }
        
    except Exception as e:
        log_to_bigquery("ERROR", f"Failed to export table {table_id}: {str(e)}")
        return {
            "table": table_id,
            "error": str(e),
            "success": False
        }

@functions_framework.http
def export_to_csv(request):
    """
    Cloud Function entry point (HTTP triggered by Cloud Scheduler)
    
    Args:
        request: HTTP request object
    """
    try:
        log_to_bigquery("INFO", f"=== CSV Export Function started with RUN_ID: {RUN_ID} ===")
        
        results = []
        
        # Export each aggregated table
        for table_id in AGGREGATED_TABLES:
            if table_id:  # Skip empty strings
                log_to_bigquery("INFO", f"Starting export for: {table_id}")
                result = export_table_to_csv(table_id)
                results.append(result)
        
        # Summary
        successful = sum(1 for r in results if r.get('success', False))
        failed = len(results) - successful
        
        log_to_bigquery("INFO", 
                       f"=== Export completed: {successful} successful, {failed} failed ===",
                       additional_info={"results": results})
        
        return {
            "status": "success",
            "run_id": RUN_ID,
            "exported": successful,
            "failed": failed,
            "results": results
        }, 200
        
    except Exception as e:
        log_to_bigquery("ERROR", f"Function failed: {str(e)}")
        print(f"ERROR: {str(e)}")
        return {"status": "error", "message": str(e)}, 500