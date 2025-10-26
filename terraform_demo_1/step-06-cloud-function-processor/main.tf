# ============================================================================
# STEP 2: Service Account létrehozása
# ============================================================================

resource "google_service_account" "demo_sa" {
  account_id   = "terraform-demo-sa-${local.name_with_hyphen}"
  display_name = "Terraform Demo Service Account for ${var.user_name}"
}

# ============================================================================
# STEP 3: Storage bucket létrehozása (adatok tárolására)
# ============================================================================

resource "google_storage_bucket" "demo_bucket" {
  name     = "${var.project_id}-${local.name_with_hyphen}-demo-bucket"
  location = var.region
}

# ============================================================================
# STEP 4: BigQuery dataset és tables
# ============================================================================

resource "google_bigquery_dataset" "demo_dataset" {
  dataset_id = "${local.name_with_underscore}_demo_dataset"
  location   = var.region
}

resource "google_bigquery_table" "log_table" {
  dataset_id = google_bigquery_dataset.demo_dataset.dataset_id
  table_id   = "${local.name_with_hyphen}-log-table"

  schema = jsonencode([
    {
      name        = "timestamp"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "Log bejegyzés időpontja"
    },
    {
      name        = "log_level"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Log szint (INFO, WARNING, ERROR, DEBUG)"
    },
    {
      name        = "message"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Log üzenet szövege"
    },
    {
      name        = "source"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Log forrása (modul/komponens neve)"
    },
    {
      name        = "user_id"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Felhasználó azonosító (ha releváns)"
    },
    {
      name        = "additional_info"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "További információk (JSON formátumban)"
    }
  ])
}

resource "google_bigquery_table" "raw_data_table" {
  dataset_id = google_bigquery_dataset.demo_dataset.dataset_id
  table_id   = "${local.name_with_hyphen}-raw-data-table"

  schema = jsonencode([
    {
      name        = "row_id"
      type        = "INTEGER"
      mode        = "REQUIRED"
      description = "Sor azonosító"
    },
    {
      name        = "order_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Rendelés azonosító"
    },
    {
      name        = "order_date"
      type        = "DATE"
      mode        = "REQUIRED"
      description = "Rendelés dátuma"
    },
    {
      name        = "ship_date"
      type        = "DATE"
      mode        = "REQUIRED"
      description = "Szállítás dátuma"
    },
    {
      name        = "ship_mode"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Szállítási mód"
    },
    {
      name        = "customer_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Ügyfél azonosító"
    },
    {
      name        = "customer_name"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Ügyfél neve"
    },
    {
      name        = "segment"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Ügyfél szegmens"
    },
    {
      name        = "country"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Ország"
    },
    {
      name        = "city"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Város"
    },
    {
      name        = "state"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Állam/Megye"
    },
    {
      name        = "postal_code"
      type        = "FLOAT"
      mode        = "NULLABLE"
      description = "Irányítószám"
    },
    {
      name        = "region"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Régió"
    },
    {
      name        = "product_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Termék azonosító"
    },
    {
      name        = "category"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Termék kategória"
    },
    {
      name        = "sub_category"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Termék alkategória"
    },
    {
      name        = "product_name"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Termék neve"
    },
    {
      name        = "sales"
      type        = "FLOAT"
      mode        = "REQUIRED"
      description = "Eladási érték"
    }
  ])
}

# ============================================================================
# STEP 5: IAM ROLE BINDINGS
# ============================================================================

resource "google_storage_bucket_iam_member" "bucket_admin" {
  bucket = google_storage_bucket.demo_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.demo_sa.email}"
}

resource "google_bigquery_dataset_iam_member" "dataset_editor" {
  dataset_id = google_bigquery_dataset.demo_dataset.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.demo_sa.email}"
}

# ============================================================================
# STEP 6: Pub/Sub Topic és Cloud Function
# ============================================================================

# Pub/Sub Topic
resource "google_pubsub_topic" "demo_topic" {
  name = "${local.name_with_hyphen}-demo-topic-raw"
}

# Pub/Sub Publisher role a Service Account-nak
resource "google_project_iam_member" "pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.demo_sa.email}"
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

# Cloud Function
resource "google_cloudfunctions_function" "file_processor" {
  name        = "${local.name_with_hyphen}-file-processor"
  description = "Processes files from Google Drive"
  runtime     = "python39"

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.function_bucket.name
  source_archive_object = google_storage_bucket_object.function_zip.name
  trigger_http          = true
  entry_point           = "process_file"

  service_account_email = google_service_account.demo_sa.email

  environment_variables = {
    PROJECT_ID        = var.project_id
    BUCKET_NAME       = google_storage_bucket.demo_bucket.name
    DATASET_ID        = google_bigquery_dataset.demo_dataset.dataset_id
    LOG_TABLE_ID      = google_bigquery_table.log_table.table_id
    RAW_DATA_TABLE_ID = google_bigquery_table.raw_data_table.table_id
    PUBSUB_TOPIC      = google_pubsub_topic.demo_topic.id
  }
}

# Allow unauthenticated invocations (Drive webhook használja majd)
resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = google_cloudfunctions_function.file_processor.project
  region         = google_cloudfunctions_function.file_processor.region
  cloud_function = google_cloudfunctions_function.file_processor.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}
