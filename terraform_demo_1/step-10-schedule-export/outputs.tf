output "csv_export_bucket_name" {
  description = "CSV export bucket neve"
  value       = google_storage_bucket.csv_export_bucket.name
}

output "csv_exporter_function_name" {
  description = "CSV exporter Cloud Function neve"
  value       = google_cloudfunctions2_function.csv_exporter.name
}

output "csv_exporter_function_url" {
  description = "CSV exporter Cloud Function URL"
  value       = google_cloudfunctions2_function.csv_exporter.service_config[0].uri
}

output "scheduler_job_name" {
  description = "Cloud Scheduler job neve"
  value       = google_cloud_scheduler_job.csv_export_schedule.name
}

output "schedule" {
  description = "Export ütemezés (cron)"
  value       = google_cloud_scheduler_job.csv_export_schedule.schedule
}
