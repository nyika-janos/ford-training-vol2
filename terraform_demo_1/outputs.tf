output "bucket_name" {
  value = google_storage_bucket.demo_bucket.name
}

output "dataset_id" {
  value = google_bigquery_dataset.demo_dataset.dataset_id
}

output "service_account_email" {
  value = google_service_account.demo_sa.email
}
