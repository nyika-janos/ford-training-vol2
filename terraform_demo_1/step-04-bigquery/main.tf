# ============================================================================
# STEP 2: Service Account létrehozása
# ============================================================================

resource "google_service_account" "demo_sa" {
  account_id   = "terraform-demo-sa-${local.name_with_hyphen}"
  display_name = "Terraform Demo Service Account for ${var.user_name}"
}

# ============================================================================
# STEP 3: Storage bucket létrehozása
# ============================================================================

resource "google_storage_bucket" "demo_bucket" {
  name     = "${var.project_id}-${local.name_with_hyphen}-demo-bucket"
  location = var.region
}

# ============================================================================
# STEP 4: BigQuery dataset és table
# ============================================================================

resource "google_bigquery_dataset" "demo_dataset" {
  dataset_id = "${local.name_with_underscore}_demo_dataset"
  location   = var.region
}

resource "google_bigquery_table" "demo_table" {
  dataset_id = google_bigquery_dataset.demo_dataset.dataset_id
  table_id   = "${local.name_with_hyphen}-demo_table"

  schema = jsonencode([
    {
      name = "id"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "timestamp"
      type = "TIMESTAMP"
      mode = "NULLABLE"
    }
  ])
}
