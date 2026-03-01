output "service_name" {
  description = "The Cloud Run service name"
  value       = google_cloud_run_v2_service.service.name
}

output "service_url" {
  description = "The HTTPS URL of the deployed service"
  value       = google_cloud_run_v2_service.service.uri
}
