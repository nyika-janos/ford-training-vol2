#!/usr/bin/env python3
"""
Register Google Drive Push Notification Webhook

Regisztrálja a Cloud Function-t mint Drive API webhook endpoint-ot.
"""

import os
import uuid
import json
from datetime import datetime, timedelta
from google.oauth2 import service_account
from googleapiclient.discovery import build
from dotenv import load_dotenv

load_dotenv()

# Configuration
FUNCTION_URL = os.getenv('FUNCTION_URL')
SA_KEY_FILE = os.getenv('SA_KEY_FILE', 'demo-sa-key.json')
CHANNEL_ID = str(uuid.uuid4())  # Unique channel ID
TOKEN = os.getenv('WEBHOOK_TOKEN', str(uuid.uuid4()))  # Optional security token

SCOPES = ['https://www.googleapis.com/auth/drive.readonly']


def get_drive_service():
    """Initialize Google Drive service"""
    credentials = service_account.Credentials.from_service_account_file(
        SA_KEY_FILE, scopes=SCOPES
    )
    return build('drive', 'v3', credentials=credentials)


def get_start_page_token(service):
    """Get the starting page token for changes"""
    try:
        response = service.changes().getStartPageToken().execute()
        return response.get('startPageToken')
    except Exception as e:
        print(f"⚠️  Warning: Could not get start page token: {e}")
        return '1'  # Default to '1' if we can't get the token


def register_webhook():
    """Register webhook with Drive API"""
    service = get_drive_service()
    
    # Get start page token
    page_token = get_start_page_token(service)
    print(f"📄 Start page token: {page_token}")
    
    # Calculate expiration (max 24 hours, we set 23 hours to be safe)
    expiration = int((datetime.utcnow() + timedelta(hours=23)).timestamp() * 1000)
    
    # Watch channel configuration
    body = {
        'id': CHANNEL_ID,
        'type': 'web_hook',
        'address': FUNCTION_URL,
        'token': TOKEN,
        'expiration': expiration
    }
    
    print("\n🚀 Registering Drive Push Notification webhook...")
    print(f"📍 Webhook URL: {FUNCTION_URL}")
    print(f"🔑 Channel ID: {CHANNEL_ID}")
    print(f"🔐 Token: {TOKEN[:10]}...")
    print(f"⏰ Expiration: {datetime.fromtimestamp(expiration/1000).isoformat()}\n")
    
    try:
        # Register the webhook
        response = service.changes().watch(
            body=body, 
            pageToken=page_token
        ).execute()
        
        print("✅ Webhook registered successfully!\n")
        print("📋 Response:")
        print(json.dumps(response, indent=2))
        
        # Save channel info for later (to stop it)
        channel_info = {
            'channel_id': CHANNEL_ID,
            'resource_id': response.get('resourceId'),
            'expiration': expiration,
            'page_token': page_token,
            'registered_at': datetime.now().isoformat(),
            'function_url': FUNCTION_URL,
            'token': TOKEN
        }
        
        with open('channel_info.json', 'w') as f:
            json.dump(channel_info, f, indent=2)
        
        print("\n💾 Channel info saved to: channel_info.json")
        print("⚠️  Save this file! You'll need it to stop the webhook.\n")
        
        print("🎉 Done! Drive will now send notifications to your Cloud Function.")
        print(f"⏰ Webhook will expire in 23 hours (at {datetime.fromtimestamp(expiration/1000).isoformat()})")
        print("🔄 Re-run this script before expiration to renew the webhook.\n")
        
        print("📝 Next steps:")
        print("1. Upload a CSV file to your monitored Drive folder")
        print("2. Check Cloud Function logs for processing")
        print("3. Verify data in BigQuery\n")
        
        return response
        
    except Exception as e:
        print(f"❌ Error registering webhook: {e}")
        print("\n🔍 Troubleshooting:")
        print("1. Check if Drive API is enabled")
        print("2. Verify Service Account has access to Drive")
        print("3. Ensure Cloud Function URL is correct and publicly accessible")
        print("4. Check Service Account key file is valid")
        raise


if __name__ == "__main__":
    print("=" * 60)
    print("Google Drive Push Notification Webhook Registration")
    print("=" * 60 + "\n")
    
    # Validate environment variables
    if not FUNCTION_URL:
        print("❌ Error: FUNCTION_URL not set in .env")
        print("   Please set the Cloud Function URL in .env file")
        exit(1)
    
    if not os.path.exists(SA_KEY_FILE):
        print(f"❌ Error: Service Account key file not found: {SA_KEY_FILE}")
        print("   Please upload the SA key file to this directory")
        exit(1)
    
    try:
        register_webhook()
    except Exception as e:
        print(f"\n❌ Registration failed: {e}")
        exit(1)