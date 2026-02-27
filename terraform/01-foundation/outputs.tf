output "vpc_id" {
  value = google_compute_network.vpc.id
}

output "vpc_name" {
  value = google_compute_network.vpc.name
}

output "subnet_id" {
  value = google_compute_subnetwork.subnet.id
}

output "connector_id" {
  value = google_vpc_access_connector.connector.id
}

output "runtime_sa_email" {
  value = google_service_account.runtime_sa.email
}

output "artifact_repo_id" {
  value = google_artifact_registry_repository.repo.id
}

output "backup_bucket_name" {
  value = google_storage_bucket.backups.name
}
