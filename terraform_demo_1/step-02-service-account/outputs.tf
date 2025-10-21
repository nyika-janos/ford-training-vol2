output "service_account_email" {
  value       = google_service_account.demo_sa.email
  description = "The email address of the created Service Account"
}
