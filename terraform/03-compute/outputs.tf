output "backend_service_name" {
  value = google_cloud_run_v2_service.backend.name
}

output "frontend_service_name" {
  value = google_cloud_run_v2_service.frontend.name
}

output "worker_service_name" {
  value = google_cloud_run_v2_service.worker.name
}
