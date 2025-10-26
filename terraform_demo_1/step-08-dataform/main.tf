# ============================================================================
# DATA SOURCES - Már létező resource-ok (step-02, 03, 04, 05, 06-ból)
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

data "google_bigquery_table" "processed_files_table" {
  dataset_id = data.google_bigquery_dataset.demo_dataset.dataset_id
  table_id   = "${local.name_with_hyphen}-processed-files"
}

data "google_pubsub_topic" "demo_topic" {
  name = "${local.name_with_hyphen}-demo-topic-raw"
}

data "google_cloudfunctions2_function" "file_processor" {
  name     = "${local.name_with_hyphen}-file-processor"
  location = var.region
}

# ============================================================================
# STEP 8: ÚJ resource-ok - Dataform Repository, Workspace és Aggregált táblák
# ============================================================================

# Dataform Repository
resource "google_dataform_repository" "demo_repository" {
  name   = "${local.name_with_hyphen}-dataform-repo"
  region = var.region

  service_account = data.google_service_account.demo_sa.email
}

# Dataform Workspace
resource "google_dataform_repository_workspace" "demo_workspace" {
  provider = google-beta

  repository = google_dataform_repository.demo_repository.name
  name       = "${local.name_with_hyphen}-workspace"
  region     = var.region
}

# Aggregált táblák sémája a BigQuery-ben
resource "google_bigquery_table" "monthly_orders_by_ship_mode" {
  dataset_id          = data.google_bigquery_dataset.demo_dataset.dataset_id
  table_id            = "monthly_orders_by_ship_mode"
  deletion_protection = false

  schema = jsonencode([
    { name = "year_month", type = "STRING", mode = "REQUIRED" },
    { name = "ship_mode", type = "STRING", mode = "REQUIRED" },
    { name = "total_sales", type = "FLOAT", mode = "REQUIRED" },
    { name = "order_count", type = "INTEGER", mode = "REQUIRED" }
  ])
}

resource "google_bigquery_table" "monthly_orders_us_state" {
  dataset_id          = data.google_bigquery_dataset.demo_dataset.dataset_id
  table_id            = "monthly_orders_us_state"
  deletion_protection = false

  schema = jsonencode([
    { name = "year_month", type = "STRING", mode = "REQUIRED" },
    { name = "state", type = "STRING", mode = "REQUIRED" },
    { name = "order_count", type = "INTEGER", mode = "REQUIRED" }
  ])
}

resource "google_bigquery_table" "monthly_favorite_product" {
  dataset_id          = data.google_bigquery_dataset.demo_dataset.dataset_id
  table_id            = "monthly_favorite_product"
  deletion_protection = false

  schema = jsonencode([
    { name = "year_month", type = "STRING", mode = "REQUIRED" },
    { name = "product_name", type = "STRING", mode = "REQUIRED" },
    { name = "order_count", type = "INTEGER", mode = "REQUIRED" },
    { name = "total_sales", type = "FLOAT", mode = "REQUIRED" },
    { name = "rank", type = "INTEGER", mode = "REQUIRED" }
  ])
}

resource "google_bigquery_table" "monthly_customer_segment_analysis" {
  dataset_id          = data.google_bigquery_dataset.demo_dataset.dataset_id
  table_id            = "monthly_customer_segment_analysis"
  deletion_protection = false

  schema = jsonencode([
    { name = "year_month", type = "STRING", mode = "REQUIRED" },
    { name = "segment", type = "STRING", mode = "REQUIRED" },
    { name = "order_count", type = "INTEGER", mode = "REQUIRED" },
    { name = "total_sales", type = "FLOAT", mode = "REQUIRED" },
    { name = "avg_order_value", type = "FLOAT", mode = "REQUIRED" },
    { name = "unique_customers", type = "INTEGER", mode = "REQUIRED" }
  ])
}

resource "google_bigquery_table" "monthly_category_revenue_trend" {
  dataset_id          = data.google_bigquery_dataset.demo_dataset.dataset_id
  table_id            = "monthly_category_revenue_trend"
  deletion_protection = false

  schema = jsonencode([
    { name = "year_month", type = "STRING", mode = "REQUIRED" },
    { name = "category", type = "STRING", mode = "REQUIRED" },
    { name = "sub_category", type = "STRING", mode = "REQUIRED" },
    { name = "total_sales", type = "FLOAT", mode = "REQUIRED" },
    { name = "order_count", type = "INTEGER", mode = "REQUIRED" },
    { name = "category_share", type = "FLOAT", mode = "REQUIRED" }
  ])
}

# IAM - Dataform Service Account jogosultságok
resource "google_bigquery_dataset_iam_member" "dataform_editor" {
  dataset_id = data.google_bigquery_dataset.demo_dataset.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${data.google_service_account.demo_sa.email}"
}

resource "google_bigquery_dataset_iam_member" "dataform_job_user" {
  dataset_id = data.google_bigquery_dataset.demo_dataset.dataset_id
  role       = "roles/bigquery.jobUser"
  member     = "serviceAccount:${data.google_service_account.demo_sa.email}"
}

# Generált Dataform SQL fájlok
resource "local_file" "dataform_sql_files" {
  for_each = fileset("${path.module}/dataform_templates", "*.sqlx.tpl")

  filename = "${path.module}/generated_dataform/${replace(each.value, ".tpl", "")}"
  content = templatefile("${path.module}/dataform_templates/${each.value}", {
    project_id     = var.project_id
    dataset_name   = data.google_bigquery_dataset.demo_dataset.dataset_id
    raw_table_name = data.google_bigquery_table.raw_data_table.table_id
  })
}
