output "repo_id"  { value = google_artifact_registry_repository.repo.id }
output "repo_url" {
  description = "Base URL for pushing/pulling images: e.g. REGION-docker.pkg.dev/PROJECT/REPO"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.repository_id}"
}
