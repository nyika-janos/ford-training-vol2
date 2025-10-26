output "service_account_email" {
  value       = google_service_account.demo_sa.email
  description = "The email address of the created Service Account"
}

output "bucket_name" {
  value       = google_storage_bucket.demo_bucket.name
  description = "The name of the created Storage Bucket"
}

output "dataset_id" {
  value       = google_bigquery_dataset.demo_dataset.dataset_id
  description = "The BigQuery dataset ID"
}

output "log_table_id" {
  value       = google_bigquery_table.log_table.table_id
  description = "The BigQuery log table ID"
}

output "raw_data_table_id" {
  value       = google_bigquery_table.raw_data_table.table_id
  description = "The BigQuery raw data table ID"
}

output "pubsub_topic_name" {
  value       = google_pubsub_topic.demo_topic.name
  description = "The Pub/Sub topic name"
}

output "cloud_function_url" {
  value       = google_cloudfunctions_function.file_processor.https_trigger_url
  description = "The Cloud Function HTTPS trigger URL (használd a Drive webhook-ban!)"
}
