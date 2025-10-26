#!/usr/bin/env python3
"""
Stop Google Drive Push Notification Webhook

Leállítja a korábban regisztrált webhook-ot.
"""

import os
import json
from google.oauth2 import service_account
from googleapiclient.discovery import build
from dotenv import load_dotenv

load_dotenv()

SA_KEY_FILE = os.getenv('SA_KEY_FILE', 'demo-sa-key.json')
SCOPES = ['https://www.googleapis.com/auth/drive.readonly']


def get_drive_service():
    """Initialize Google Drive service"""
    credentials = service_account.Credentials.from_service_account_file(
        SA_KEY_FILE, scopes=SCOPES
    )
    return build('drive', 'v3', credentials=credentials)


def stop_webhook():
    """Stop the webhook"""
    # Load channel info
    if not os.path.exists('channel_info.json'):
        print("❌ Error: channel_info.json not found")
        print("   You need the channel info from registration to stop the webhook.")
        print("   If you lost it, the webhook will expire automatically in 24 hours.")
        exit(1)
    
    with open('channel_info.json', 'r') as f:
        channel_info = json.load(f)
    
    channel_id = channel_info.get('channel_id')
    resource_id = channel_info.get('resource_id')
    function_url = channel_info.get('function_url', 'N/A')
    registered_at = channel_info.get('registered_at', 'N/A')
    
    print("=" * 60)
    print("Google Drive Push Notification Webhook Removal")
    print("=" * 60 + "\n")
    
    print(f"🛑 Stopping webhook...")
    print(f"🔑 Channel ID: {channel_id}")
    print(f"📍 Resource ID: {resource_id}")
    print(f"🔗 Function URL: {function_url}")
    print(f"📅 Registered at: {registered_at}\n")
    
    service = get_drive_service()
    
    try:
        # Stop the channel
        service.channels().stop(body={
            'id': channel_id,
            'resourceId': resource_id
        }).execute()
        
        print("✅ Webhook stopped successfully!")
        
        # Archive channel info (don't delete, might be useful for debugging)
        archive_name = f"channel_info_stopped_{channel_id[:8]}.json"
        os.rename('channel_info.json', archive_name)
        print(f"💾 Channel info archived to: {archive_name}\n")
        
        print("🎉 Done! The webhook has been stopped.")
        print("   Drive will no longer send notifications to your Cloud Function.")
        
    except Exception as e:
        print(f"❌ Error stopping webhook: {e}")
        print("\n🔍 Possible reasons:")
        print("1. The webhook might have already expired")
        print("2. The channel ID or resource ID might be invalid")
        print("3. Network or permission issues")
        raise


if __name__ == "__main__":
    # Validate
    if not os.path.exists(SA_KEY_FILE):
        print(f"❌ Error: Service Account key file not found: {SA_KEY_FILE}")
        print("   Please ensure the SA key file is in this directory")
        exit(1)
    
    try:
        stop_webhook()
    except Exception as e:
        print(f"\n❌ Stop operation failed: {e}")
        exit(1)