# Előző step-ek resource-ai (data sources)
output "service_account_email" {
  value       = data.google_service_account.demo_sa.email
  description = "The email address of the Service Account (from step-02)"
}

output "bucket_name" {
  value       = data.google_storage_bucket.demo_bucket.name
  description = "The name of the data Storage Bucket (from step-03)"
}

output "dataset_id" {
  value       = data.google_bigquery_dataset.demo_dataset.dataset_id
  description = "The BigQuery dataset ID (from step-04)"
}

output "log_table_id" {
  value       = data.google_bigquery_table.log_table.table_id
  description = "The BigQuery log table ID (from step-04)"
}

output "raw_data_table_id" {
  value       = data.google_bigquery_table.raw_data_table.table_id
  description = "The BigQuery raw data table ID (from step-04)"
}

output "processed_files_table_id" {
  value       = data.google_bigquery_table.processed_files_table.table_id
  description = "The BigQuery processed files table ID (from step-04)"
}

output "pubsub_topic_name" {
  value       = data.google_pubsub_topic.demo_topic.name
  description = "The Pub/Sub topic name (from step-06)"
}

output "cloud_function_url" {
  value       = data.google_cloudfunctions2_function.file_processor.service_config[0].uri
  description = "The Cloud Function Gen2 HTTPS trigger URL (from step-06)"
}

output "aggregated_tables" {
  description = "Létrehozott aggregált táblák"
  value = [
    google_bigquery_table.monthly_orders_by_ship_mode.table_id,
    google_bigquery_table.monthly_orders_us_state.table_id,
    google_bigquery_table.monthly_favorite_product.table_id,
    google_bigquery_table.monthly_customer_segment_analysis.table_id,
    google_bigquery_table.monthly_category_revenue_trend.table_id
  ]
}

output "generated_dataform_path" {
  description = "Generált Dataform fájlok helye"
  value       = "${path.module}/generated_dataform/"
}
