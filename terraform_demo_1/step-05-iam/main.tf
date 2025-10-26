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
# STEP 4: BigQuery dataset és tables
# ============================================================================

resource "google_bigquery_dataset" "demo_dataset" {
  dataset_id = "${local.name_with_underscore}_demo_dataset"
  location   = var.region
}

# Log table - alkalmazás log-ok tárolására
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

# Raw data table - superstore adatok tárolására
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

# Storage Bucket - Object Admin (teljes RW jogosultság az objektumokra)
resource "google_storage_bucket_iam_member" "bucket_admin" {
  bucket = google_storage_bucket.demo_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.demo_sa.email}"
}

# BigQuery Dataset - Data Editor (RW jogosultság az adatokra)
resource "google_bigquery_dataset_iam_member" "dataset_editor" {
  dataset_id = google_bigquery_dataset.demo_dataset.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.demo_sa.email}"
}
