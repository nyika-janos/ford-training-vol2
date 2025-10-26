# ============================================================================
# DATA SOURCES - Már létező resource-ok (step-02, 03, 04, 05-ből)
# ============================================================================

data "google_service_account" "demo_sa" {
  account_id = "terraform-demo-sa-${local.name_with_hyphen}"
}

data "google_storage_bucket" "demo_bucket" {
  name = "${var.project_id}-${local.name_with_hyphen}-demo-bucket"
}

data "google_bigquery_dataset" "demo_dataset" {
  dataset_id = "${local.name_with_underscore}_demo_dataset"
}

data "google_bigquery_table" "log_table" {
  dataset_id = data.google_bigquery_dataset.demo_dataset.dataset_id
  table_id   = "${local.name_with_hyphen}-log-table"
}

data "google_bigquery_table" "raw_data_table" {
  dataset_id = data.google_bigquery_dataset.demo_dataset.dataset_id
  table_id   = "${local.name_with_hyphen}-raw-data-table"
}

# ============================================================================
# STEP 6: ÚJ resource-ok - Pub/Sub Topic és Cloud Function Gen2
# ============================================================================

# Pub/Sub Topic
resource "google_pubsub_topic" "demo_topic" {
  name = "${local.name_with_hyphen}-demo-topic-raw"
}

# Pub/Sub Publisher role a Service Account-nak (PROJECT szintű)
resource "google_project_iam_member" "pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_service_account.demo_sa.email}"
}

# Storage bucket a Cloud Function kódjának
resource "google_storage_bucket" "function_bucket" {
  name     = "${var.project_id}-${local.name_with_hyphen}-function-source"
  location = var.region
}

# ZIP-eljük a function source code-ot
data "archive_file" "function_source" {
  type        = "zip"
  source_dir  = "${path.module}/function_source"
  output_path = "${path.module}/function_source.zip"
}

# Feltöltjük a ZIP-et a bucket-be
resource "google_storage_bucket_object" "function_zip" {
  name   = "function-source-${data.archive_file.function_source.output_md5}.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = data.archive_file.function_source.output_path
}

# Cloud Function Gen2
resource "google_cloudfunctions2_function" "file_processor" {
  name        = "${local.name_with_hyphen}-file-processor"
  location    = var.region
  description = "Processes files from Google Drive (Gen2)"

  build_config {
    runtime     = "python312"
    entry_point = "process_file"
    source {
      storage_source {
        bucket = google_storage_bucket.function_bucket.name
        object = google_storage_bucket_object.function_zip.name
      }
    }
  }

  service_config {
    max_instance_count    = 3
    min_instance_count    = 0
    available_memory      = "256M"
    timeout_seconds       = 60
    service_account_email = data.google_service_account.demo_sa.email

    environment_variables = {
      PROJECT_ID          = var.project_id
      BUCKET_NAME         = data.google_storage_bucket.demo_bucket.name
      DATASET_ID          = data.google_bigquery_dataset.demo_dataset.dataset_id
      LOG_TABLE_ID        = data.google_bigquery_table.log_table.table_id
      RAW_DATA_TABLE_ID   = data.google_bigquery_table.raw_data_table.table_id
      PUBSUB_TOPIC        = google_pubsub_topic.demo_topic.id
      MONITORED_FOLDER_ID = var.monitored_folder_id
    }
  }
}

# Allow unauthenticated invocations (Gen2 uses Cloud Run IAM)
resource "google_cloud_run_service_iam_member" "invoker" {
  project  = google_cloudfunctions2_function.file_processor.project
  location = google_cloudfunctions2_function.file_processor.location
  service  = google_cloudfunctions2_function.file_processor.name

  role   = "roles/run.invoker"
  member = "allUsers"
}
