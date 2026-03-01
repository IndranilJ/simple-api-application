output "sa_email" {
  description = "Email of the runtime service account"
  value       = google_service_account.sa.email
}

output "sa_id" {
  value = google_service_account.sa.id
}
