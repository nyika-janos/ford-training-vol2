import os
from flask import Flask, render_template, redirect, url_for, Response
from google.cloud import storage
from datetime import datetime, timedelta
import logging

app = Flask(__name__)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

PROJECT_ID = os.environ.get('PROJECT_ID', 'ford-training-430008')
BUCKET_NAME = os.environ.get('BUCKET_NAME', 'csv-exports')
PORT = int(os.environ.get('PORT', 8080))

logger.info(f"=== APP STARTED ===")
logger.info(f"PROJECT_ID: {PROJECT_ID}")
logger.info(f"BUCKET_NAME: {BUCKET_NAME}")

try:
    storage_client = storage.Client(project=PROJECT_ID)
    bucket = storage_client.bucket(BUCKET_NAME)
    logger.info(f"Storage client initialized successfully")
except Exception as e:
    logger.error(f"Failed to initialize storage client: {e}")
    bucket = None

def get_folder_structure(prefix=''):
    """Mappa struktúra lekérése - MINDENT listázunk, mi szűrünk"""
    logger.info(f"=== get_folder_structure called with prefix: '{prefix}' ===")
    
    if bucket is None:
        logger.error("Bucket is None!")
        return [], []
    
    try:
        # Listázunk MINDENT a prefix alatt - NINCS delimiter!
        blobs = list(bucket.list_blobs(prefix=prefix))
        logger.info(f"Total blobs found: {len(blobs)}")
        
        folders_set = set()
        files = []
        
        for blob in blobs:
            path = blob.name
            
            # Ha prefix-szel kezdünk, távolítsuk el
            if prefix and path.startswith(prefix):
                relative_path = path[len(prefix):]
            else:
                relative_path = path
            
            # Daraboljuk fel '/' mentén
            parts = relative_path.split('/')
            
            # Ha több mint 1 rész van, akkor van almappa
            if len(parts) > 1 and parts[0]:
                folder_name = parts[0]
                folders_set.add(folder_name)
            
            # Ha CSV fájl és közvetlenül ebben a mappában van
            elif path.endswith('.csv') and len(parts) == 1:
                files.append({
                    'name': parts[0],
                    'path': path,
                    'size': blob.size,
                    'updated': blob.updated
                })
        
        folders = [{'name': f, 'path': f"{prefix}{f}" if prefix else f} for f in sorted(folders_set)]
        
        logger.info(f"Result: {len(folders)} folders, {len(files)} files")
        
        return folders, files
        
    except Exception as e:
        logger.error(f"Error in get_folder_structure: {e}", exc_info=True)
        return [], []

@app.route('/')
def index():
    logger.info("=== INDEX route called ===")
    folders, files = get_folder_structure('')
    return render_template('index.html', 
                         folders=folders, 
                         files=files, 
                         current_path='',
                         breadcrumbs=[])

@app.route('/folder/<path:folder_path>')
def folder_view(folder_path):
    logger.info(f"=== FOLDER route called with path: {folder_path} ===")
    
    # Prefix legyen a folder_path + '/'
    prefix = folder_path + '/' if not folder_path.endswith('/') else folder_path
    folders, files = get_folder_structure(prefix)
    
    # Breadcrumb
    breadcrumbs = []
    path_parts = folder_path.split('/')
    current_path = ''
    
    for part in path_parts:
        if part:
            current_path += part
            breadcrumbs.append({'name': part, 'path': current_path})
            current_path += '/'
    
    return render_template('index.html', 
                         folders=folders, 
                         files=files, 
                         current_path=folder_path,
                         breadcrumbs=breadcrumbs)

@app.route('/download/<path:file_path>')
def download_file(file_path):
    """Stream fájl közvetlenül a bucket-ből"""
    logger.info(f"=== DOWNLOAD route called for: {file_path} ===")
    
    if bucket is None:
        return "Error: Bucket not initialized", 500
    
    try:
        blob = bucket.blob(file_path)
        
        # Ellenőrizzük, hogy létezik-e a blob
        if not blob.exists():
            logger.error(f"Blob not found: {file_path}")
            return "File not found", 404
        
        # Stream-eljük a tartalmat
        logger.info(f"Streaming file: {file_path}")
        
        # Fájl tartalom letöltése
        file_content = blob.download_as_bytes()
        
        # Fájlnév a letöltéshez
        filename = file_path.split('/')[-1]
        
        # Response létrehozása
        response = Response(
            file_content,
            mimetype='text/csv',
            headers={
                'Content-Disposition': f'attachment; filename={filename}',
                'Content-Type': 'text/csv; charset=utf-8'
            }
        )
        
        logger.info(f"File streamed successfully: {filename}")
        return response
        
    except Exception as e:
        logger.error(f"Error downloading file: {e}", exc_info=True)
        return f"Error: {e}", 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=PORT, debug=False)