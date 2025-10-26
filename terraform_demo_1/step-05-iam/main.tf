# ============================================================================
# DATA SOURCES - Már létező resource-ok (step-02, step-03, step-04-ből)
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
# STEP 5: ÚJ resource-ok - IAM ROLE BINDINGS
# ============================================================================

# Storage Bucket - Object Admin (teljes RW jogosultság az objektumokra)
resource "google_storage_bucket_iam_member" "bucket_admin" {
  bucket = data.google_storage_bucket.demo_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${data.google_service_account.demo_sa.email}"
}

# BigQuery Dataset - Data Editor (RW jogosultság az adatokra)
resource "google_bigquery_dataset_iam_member" "dataset_editor" {
  dataset_id = data.google_bigquery_dataset.demo_dataset.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${data.google_service_account.demo_sa.email}"
}
