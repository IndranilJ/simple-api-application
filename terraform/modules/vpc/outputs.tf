output "vpc_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "subnet_id" {
  description = "The ID of the subnet"
  value       = google_compute_subnetwork.subnet.id
}

output "connector_id" {
  description = "The full resource ID of the Serverless VPC Connector"
  value       = google_vpc_access_connector.connector.id
}

output "private_range_name" {
  description = "The private IP range name reserved for peering"
  value       = google_compute_global_address.private_ip_range.name
}

output "peering_complete" {
  description = "A dependency handle — reference this to ensure peering is ready before creating SQL/Redis"
  value       = time_sleep.wait_for_peering.id
}
