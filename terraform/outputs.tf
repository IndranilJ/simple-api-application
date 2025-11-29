output "service_url" {
  value = google_cloud_run_v2_service.hello_api.uri
}
output "artifact_repo" {
  value = google_artifact_registry_repository.repo.id
}
output "deployer_sa" {
  value = google_service_account.deployer.email
}
