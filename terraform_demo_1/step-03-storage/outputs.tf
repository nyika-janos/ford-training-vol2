output "service_account_email" {
  value       = google_service_account.demo_sa.email
  description = "The email address of the created Service Account"
}

output "bucket_name" {
  value       = google_storage_bucket.demo_bucket.name
  description = "The name of the created Storage Bucket"
}
