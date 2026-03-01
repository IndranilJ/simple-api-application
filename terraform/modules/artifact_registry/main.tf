# ---------------------------------------------------------------------------------------------------------------------
# MODULE: artifact_registry
# Creates a Docker repository for storing container images.
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
  }
}

resource "google_project_service" "artifactregistry" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "${var.application_name}-repo"
  description   = "Docker image repository for ${var.application_name}"
  format        = "DOCKER"
  depends_on    = [google_project_service.artifactregistry]
}
