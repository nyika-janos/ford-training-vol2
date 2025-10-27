output "cloud_run_url" {
  description = "CSV Browser website URL"
  value       = google_cloud_run_service.csv_browser.status[0].url
}

output "service_name" {
  description = "Cloud Run service neve"
  value       = google_cloud_run_service.csv_browser.name
}

output "docker_image" {
  description = "Docker image URL"
  value       = local.docker_image
}

output "csv_bucket_name" {
  description = "CSV export bucket neve"
  value       = data.google_storage_bucket.csv_export_bucket.name
}
