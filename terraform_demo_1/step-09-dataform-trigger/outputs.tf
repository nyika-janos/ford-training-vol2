output "dataform_trigger_function_name" {
  description = "Dataform trigger Cloud Function neve"
  value       = google_cloudfunctions2_function.dataform_trigger.name
}

output "pubsub_topic_name" {
  description = "Pub/Sub topic amit figyel"
  value       = data.google_pubsub_topic.demo_topic.name
}

output "dataform_repository" {
  description = "Dataform repository név"
  value       = var.dataform_repository
}

output "dataform_workspace" {
  description = "Dataform workspace név"
  value       = var.dataform_workspace
}
