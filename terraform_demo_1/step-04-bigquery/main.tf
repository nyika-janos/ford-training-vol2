# ============================================================================
# DATA SOURCES - Már létező resource-ok (step-02 és step-03-ból)
# ============================================================================

data "google_service_account" "demo_sa" {
  account_id = "terraform-demo-sa-${local.name_with_hyphen}"
}

data "google_storage_bucket" "demo_bucket" {
  name = "${var.project_id}-${local.name_with_hyphen}-demo-bucket"
}

# ============================================================================
# STEP 4: ÚJ resource-ok - BigQuery dataset és tables
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
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Rendelés dátuma (M/D/YYYY formátum)"
    },
    {
      name        = "ship_date"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Szállítás dátuma (M/D/YYYY formátum)"
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

# Processed files tracking table
resource "google_bigquery_table" "processed_files_table" {
  dataset_id = google_bigquery_dataset.demo_dataset.dataset_id
  table_id   = "${local.name_with_hyphen}-processed-files"

  schema = jsonencode([
    {
      name        = "file_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Google Drive fájl egyedi azonosítója"
    },
    {
      name        = "file_name"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Fájl neve"
    },
    {
      name        = "processed_at"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "Feldolgozás időpontja"
    },
    {
      name        = "gcs_uri"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "GCS tárolási hely"
    },
    {
      name        = "rows_loaded"
      type        = "INTEGER"
      mode        = "NULLABLE"
      description = "Betöltött sorok száma"
    }
  ])
}
