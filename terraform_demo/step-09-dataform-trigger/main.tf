# ============================================================================
# DATA SOURCES - Már létező resource-ok
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

data "google_pubsub_topic" "demo_topic" {
  name = "${local.name_with_hyphen}-demo-topic-raw"
}

data "google_project" "project" {
  project_id = var.project_id
}

# ============================================================================
# STEP 9: Dataform Trigger Cloud Function
# ============================================================================

# Storage bucket a Cloud Function kódjának
resource "google_storage_bucket" "dataform_trigger_function_bucket" {
  name     = "${var.project_id}-${local.name_with_hyphen}-dataform-trigger"
  location = var.region
}

# ZIP-eljük a function source code-ot
data "archive_file" "dataform_trigger_source" {
  type        = "zip"
  source_dir  = "${path.module}/function_source"
  output_path = "${path.module}/dataform_trigger_source.zip"
}

# Feltöltjük a ZIP-et a bucket-be
resource "google_storage_bucket_object" "dataform_trigger_zip" {
  name   = "function-source-${data.archive_file.dataform_trigger_source.output_md5}.zip"
  bucket = google_storage_bucket.dataform_trigger_function_bucket.name
  source = data.archive_file.dataform_trigger_source.output_path
}

# Cloud Function Gen2 - Pub/Sub triggered
resource "google_cloudfunctions2_function" "dataform_trigger" {
  name        = "${local.name_with_hyphen}-dataform-trigger"
  location    = var.region
  description = "Triggers Dataform workflow when file is processed"

  build_config {
    runtime     = "python312"
    entry_point = "dataform_trigger"
    source {
      storage_source {
        bucket = google_storage_bucket.dataform_trigger_function_bucket.name
        object = google_storage_bucket_object.dataform_trigger_zip.name
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
      REGION              = var.region
      DATASET_ID          = data.google_bigquery_dataset.demo_dataset.dataset_id
      LOG_TABLE_ID        = data.google_bigquery_table.log_table.table_id
      DATAFORM_REPOSITORY = var.dataform_repository
      DATAFORM_WORKSPACE  = var.dataform_workspace
    }
  }

  event_trigger {
    trigger_region        = var.region
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic          = data.google_pubsub_topic.demo_topic.id
    retry_policy          = "RETRY_POLICY_RETRY"
    service_account_email = data.google_service_account.demo_sa.email
  }
}

# ============================================================================
# IAM Bindings
# ============================================================================

# IAM - Cloud Run Invoker a Pub/Sub service account-nak (aki push-olja a message-t)
resource "google_cloud_run_service_iam_member" "pubsub_invoker" {
  project  = google_cloudfunctions2_function.dataform_trigger.project
  location = google_cloudfunctions2_function.dataform_trigger.location
  service  = google_cloudfunctions2_function.dataform_trigger.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

# IAM - Cloud Run Invoker role projekt szinten a demo SA-nak
resource "google_project_iam_member" "demo_sa_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${data.google_service_account.demo_sa.email}"
}

resource "google_service_account_iam_member" "demo_sa_user" {
  service_account_id = data.google_service_account.demo_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${data.google_service_account.demo_sa.email}"
}

# IAM - Pub/Sub Subscriber role (Gen2 Pub/Sub trigger-hez)
resource "google_project_iam_member" "pubsub_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${data.google_service_account.demo_sa.email}"
}

# IAM - Dataform Editor role a Service Account-nak
resource "google_project_iam_member" "dataform_editor" {
  project = var.project_id
  role    = "roles/dataform.editor"
  member  = "serviceAccount:${data.google_service_account.demo_sa.email}"
}
