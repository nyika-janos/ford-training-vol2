output "service_account_email" {
  value       = data.google_service_account.demo_sa.email
  description = "The email address of the Service Account (from step-02)"
}

output "bucket_name" {
  value       = data.google_storage_bucket.demo_bucket.name
  description = "The name of the Storage Bucket (from step-03)"
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
