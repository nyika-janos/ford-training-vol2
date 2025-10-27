"""
Cloud Function: Dataform Workflow Trigger

Triggered by Pub/Sub when a file is processed.
Starts Dataform workflow to refresh aggregated tables.
"""

import os
import json
import uuid
from datetime import datetime
from google.cloud import bigquery
import requests
from google.auth.transport.requests import Request
from google.oauth2 import service_account
import google.auth

# Environment variables
PROJECT_ID = os.environ.get('PROJECT_ID')
REGION = os.environ.get('REGION', 'europe-west1')
DATASET_ID = os.environ.get('DATASET_ID')
LOG_TABLE_ID = os.environ.get('LOG_TABLE_ID')
DATAFORM_REPOSITORY = os.environ.get('DATAFORM_REPOSITORY')
DATAFORM_WORKSPACE = os.environ.get('DATAFORM_WORKSPACE')

# Global run_id for this function execution
RUN_ID = str(uuid.uuid4())

def log_to_bigquery(log_level, message, source="dataform_trigger", user_id=None, additional_info=None):
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

def get_access_token():
    """Get access token for Dataform API"""
    credentials, project = google.auth.default()
    credentials.refresh(Request())
    return credentials.token

def trigger_dataform_workflow():
    """Trigger Dataform workflow execution using REST API"""
    try:
        log_to_bigquery("INFO", "Starting Dataform workflow trigger...")
        
        # Get access token
        access_token = get_access_token()
        
        # Dataform API endpoint
        api_url = (
            f"https://dataform.googleapis.com/v1beta1/"
            f"projects/{PROJECT_ID}/locations/{REGION}/"
            f"repositories/{DATAFORM_REPOSITORY}/"
            f"workflowInvocations"
        )
        
        # Request body - use workspace compilation
        request_body = {
            "compilationResult": f"projects/{PROJECT_ID}/locations/{REGION}/repositories/{DATAFORM_REPOSITORY}/workspaces/{DATAFORM_WORKSPACE}/compilationResults/latest"
        }
        
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }
        
        # Make API call
        response = requests.post(api_url, json=request_body, headers=headers)
        
        if response.status_code in [200, 201]:
            result = response.json()
            invocation_name = result.get('name', 'unknown')
            log_to_bigquery("INFO", f"Dataform workflow triggered successfully: {invocation_name}")
            return True
        else:
            error_msg = f"Failed to trigger Dataform workflow: {response.status_code} - {response.text}"
            log_to_bigquery("ERROR", error_msg)
            return False
            
    except Exception as e:
        log_to_bigquery("ERROR", f"Error triggering Dataform workflow: {str(e)}")
        return False

def dataform_trigger(cloud_event):
    """
    Cloud Function entry point (Pub/Sub triggered)
    
    Args:
        cloud_event: CloudEvent object from Pub/Sub
    """
    try:
        log_to_bigquery("INFO", f"=== Dataform Trigger Function started with RUN_ID: {RUN_ID} ===")
        
        # Decode Pub/Sub message
        import base64
        pubsub_message = base64.b64decode(cloud_event.data["message"]["data"]).decode('utf-8')
        message_data = json.loads(pubsub_message)
        
        log_to_bigquery("INFO", "Pub/Sub message received", additional_info=message_data)
        
        # Extract file information
        file_name = message_data.get('file_name', 'unknown')
        rows_loaded = message_data.get('rows_loaded', 0)
        
        log_to_bigquery("INFO", f"Processing trigger for file: {file_name} ({rows_loaded} rows)")
        
        # Trigger Dataform workflow
        success = trigger_dataform_workflow()
        
        if success:
            log_to_bigquery("INFO", f"=== Dataform workflow triggered successfully for {file_name} ===")
        else:
            log_to_bigquery("ERROR", f"=== Failed to trigger Dataform workflow for {file_name} ===")
        
        log_to_bigquery("INFO", f"=== Function completed with RUN_ID: {RUN_ID} ===")
        
    except Exception as e:
        log_to_bigquery("ERROR", f"Function failed: {str(e)}")
        raise