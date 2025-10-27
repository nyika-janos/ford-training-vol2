# ============================================================================
# DATA SOURCES - Már létező resource-ok
# ============================================================================

data "google_service_account" "demo_sa" {
  account_id = "terraform-demo-sa-${local.name_with_hyphen}"
}

data "google_bigquery_dataset" "demo_dataset" {
  dataset_id = "${local.name_with_underscore}_demo_dataset"
}

data "google_bigquery_table" "log_table" {
  dataset_id = data.google_bigquery_dataset.demo_dataset.dataset_id
  table_id   = "${local.name_with_hyphen}-log-table"
}

# Aggregált táblák (step-08-ból)
data "google_bigquery_table" "monthly_orders_by_ship_mode" {
  dataset_id = data.google_bigquery_dataset.demo_dataset.dataset_id
  table_id   = "monthly_orders_by_ship_mode"
}

data "google_bigquery_table" "monthly_orders_us_state" {
  dataset_id = data.google_bigquery_dataset.demo_dataset.dataset_id
  table_id   = "monthly_orders_us_state"
}

data "google_bigquery_table" "monthly_favorite_product" {
  dataset_id = data.google_bigquery_dataset.demo_dataset.dataset_id
  table_id   = "monthly_favorite_product"
}

data "google_bigquery_table" "monthly_customer_segment_analysis" {
  dataset_id = data.google_bigquery_dataset.demo_dataset.dataset_id
  table_id   = "monthly_customer_segment_analysis"
}

data "google_bigquery_table" "monthly_category_revenue_trend" {
  dataset_id = data.google_bigquery_dataset.demo_dataset.dataset_id
  table_id   = "monthly_category_revenue_trend"
}

data "google_project" "project" {
  project_id = var.project_id
}

# ============================================================================
# STEP 10: Scheduled CSV Export
# ============================================================================

# CSV export bucket
resource "google_storage_bucket" "csv_export_bucket" {
  name     = "${var.project_id}-${local.name_with_hyphen}-csv-exports"
  location = var.region

  # Optional: lifecycle rule - 30 napos retention
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

# Storage bucket a Cloud Function kódjának
resource "google_storage_bucket" "export_function_bucket" {
  name     = "${var.project_id}-${local.name_with_hyphen}-export-function"
  location = var.region
}

# ZIP-eljük a function source code-ot
data "archive_file" "export_function_source" {
  type        = "zip"
  source_dir  = "${path.module}/function_source"
  output_path = "${path.module}/export_function_source.zip"
}

# Feltöltjük a ZIP-et a bucket-be
resource "google_storage_bucket_object" "export_function_zip" {
  name   = "function-source-${data.archive_file.export_function_source.output_md5}.zip"
  bucket = google_storage_bucket.export_function_bucket.name
  source = data.archive_file.export_function_source.output_path
}

# Cloud Function Gen2 - HTTP trigger
resource "google_cloudfunctions2_function" "csv_exporter" {
  name        = "${local.name_with_hyphen}-csv-exporter"
  location    = var.region
  description = "Exports BigQuery aggregated tables to CSV"

  build_config {
    runtime     = "python312"
    entry_point = "export_to_csv"
    source {
      storage_source {
        bucket = google_storage_bucket.export_function_bucket.name
        object = google_storage_bucket_object.export_function_zip.name
      }
    }
  }

  service_config {
    max_instance_count    = 1
    min_instance_count    = 0
    available_memory      = "512M"
    timeout_seconds       = 300
    service_account_email = data.google_service_account.demo_sa.email

    environment_variables = {
      PROJECT_ID   = var.project_id
      DATASET_ID   = data.google_bigquery_dataset.demo_dataset.dataset_id
      LOG_TABLE_ID = data.google_bigquery_table.log_table.table_id
      CSV_BUCKET   = google_storage_bucket.csv_export_bucket.name
      AGGREGATED_TABLES = join(",", [
        data.google_bigquery_table.monthly_orders_by_ship_mode.table_id,
        data.google_bigquery_table.monthly_orders_us_state.table_id,
        data.google_bigquery_table.monthly_favorite_product.table_id,
        data.google_bigquery_table.monthly_customer_segment_analysis.table_id,
        data.google_bigquery_table.monthly_category_revenue_trend.table_id
      ])
    }
  }
}

# Cloud Scheduler Job - óránként
resource "google_cloud_scheduler_job" "csv_export_schedule" {
  name             = "${local.name_with_hyphen}-csv-export-schedule"
  description      = "Triggers CSV export every hour"
  schedule         = "0 * * * *"
  time_zone        = "Europe/Budapest"
  attempt_deadline = "320s"

  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions2_function.csv_exporter.service_config[0].uri

    oidc_token {
      service_account_email = data.google_service_account.demo_sa.email
    }
  }

  retry_config {
    retry_count = 3
  }
}

# ============================================================================
# IAM Bindings
# ============================================================================

# Cloud Run Invoker - Cloud Scheduler SA -> Function
resource "google_cloud_run_service_iam_member" "scheduler_invoker" {
  project  = google_cloudfunctions2_function.csv_exporter.project
  location = google_cloudfunctions2_function.csv_exporter.location
  service  = google_cloudfunctions2_function.csv_exporter.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${data.google_service_account.demo_sa.email}"
}

# Storage Object Admin - CSV bucket írás
resource "google_storage_bucket_iam_member" "csv_bucket_admin" {
  bucket = google_storage_bucket.csv_export_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${data.google_service_account.demo_sa.email}"
}

# BigQuery Data Viewer - táblák olvasása (ha még nincs meg)
resource "google_bigquery_dataset_iam_member" "dataset_viewer" {
  dataset_id = data.google_bigquery_dataset.demo_dataset.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${data.google_service_account.demo_sa.email}"
}
