output "ip_address" {
  description = "The public IP of the global load balancer"
  value       = google_compute_global_address.lb_ip.address
}

output "backend_service_ids" {
  description = "Map of backend service resource IDs keyed by route name"
  value       = { for k, v in google_compute_backend_service.backends : k => v.id }
}
