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
import google.auth
import base64

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
        
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }
        
        # STEP 1: Create compilation result from workspace
        compilation_url = (
            f"https://dataform.googleapis.com/v1beta1/"
            f"projects/{PROJECT_ID}/locations/{REGION}/"
            f"repositories/{DATAFORM_REPOSITORY}/"
            f"compilationResults"
        )
        
        # Teljes workspace path kell!
        workspace_path = (
            f"projects/{PROJECT_ID}/locations/{REGION}/"
            f"repositories/{DATAFORM_REPOSITORY}/workspaces/{DATAFORM_WORKSPACE}"
        )
        
        compilation_body = {
            "workspace": workspace_path
        }
        
        compilation_response = requests.post(compilation_url, json=compilation_body, headers=headers)
        
        if compilation_response.status_code not in [200, 201]:
            error_msg = f"Failed to create compilation: {compilation_response.status_code} - {compilation_response.text}"
            log_to_bigquery("ERROR", error_msg)
            return False
        
        compilation_result = compilation_response.json()
        compilation_name = compilation_result.get('name')
        log_to_bigquery("INFO", f"Compilation created: {compilation_name}")
        
        # STEP 2: Create workflow invocation with compilation result
        invocation_url = (
            f"https://dataform.googleapis.com/v1beta1/"
            f"projects/{PROJECT_ID}/locations/{REGION}/"
            f"repositories/{DATAFORM_REPOSITORY}/"
            f"workflowInvocations"
        )
        
        invocation_body = {
            "compilationResult": compilation_name
        }
        
        invocation_response = requests.post(invocation_url, json=invocation_body, headers=headers)
        
        if invocation_response.status_code in [200, 201]:
            result = invocation_response.json()
            invocation_name = result.get('name', 'unknown')
            log_to_bigquery("INFO", f"Dataform workflow triggered successfully: {invocation_name}")
            return True
        else:
            error_msg = f"Failed to trigger workflow: {invocation_response.status_code} - {invocation_response.text}"
            log_to_bigquery("ERROR", error_msg)
            return False
            
    except Exception as e:
        log_to_bigquery("ERROR", f"Error triggering Dataform workflow: {str(e)}")
        return False

# ... existing code up to line 127 ...

def dataform_trigger(event, context):
    """
    Cloud Function entry point (Pub/Sub triggered)
    
    Args:
        event: Pub/Sub message event data (base64 encoded)
        context: Event context
    """
    try:
        log_to_bigquery("INFO", f"=== Dataform Trigger Function started with RUN_ID: {RUN_ID} ===")
        
        # Decode Pub/Sub message (base64 encoded)
        pubsub_message = base64.b64decode(event['data']).decode('utf-8')
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
        
        return ("OK", 200)
        
    except Exception as e:
        log_to_bigquery("ERROR", f"Function failed: {str(e)}")
        print(f"ERROR: {str(e)}")
        return ("Error", 500)