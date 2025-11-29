# Enable required APIs
resource "google_project_service" "services" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "secretmanager.googleapis.com",
  ])
  project             = var.project_id
  service             = each.key
  disable_on_destroy  = false
}

# Artifact Registry repo
resource "google_artifact_registry_repository" "repo" {
  project       = var.project_id
  location      = var.region
  repository_id = var.repository_id
  description   = "Docker images for Hello API"
  format        = "DOCKER"
  depends_on    = [google_project_service.services]
}

# Service account for Cloud Run deploy/runtime
resource "google_service_account" "deployer" {
  project      = var.project_id
  account_id   = "cloud-run-deployer"
  display_name = "Cloud Run Deployer"
}

# IAM roles for deployer SA
resource "google_project_iam_member" "deployer_roles" {
  for_each = toset([
    "roles/run.admin",
    "roles/artifactregistry.reader",
    "roles/iam.serviceAccountUser",
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.deployer.email}"
}

# Cloud Run service
resource "google_cloud_run_v2_service" "hello_api" {
  name     = var.service_name
  location = var.region
  project  = var.project_id
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.deployer.email
    timeout         = "30s"

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repository_id}/${var.service_name}:${var.image_tag}"

      resources {
        cpu_idle = true
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
      }

      dynamic "env" {
        for_each = var.env
        content {
          name  = env.key
          value = env.value
        }
      }
      ports {
        container_port = 8000
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 5
    }
  }

  depends_on = [
    google_artifact_registry_repository.repo,
    google_project_service.services,
    google_project_iam_member.deployer_roles
  ]
}

# Allow unauthenticated (optional)
resource "google_cloud_run_v2_service_iam_policy" "public" {
  count   = var.allow_unauth ? 1 : 0
  project = var.project_id
  location = var.region
  name    = google_cloud_run_v2_service.hello_api.name

  policy_data = jsonencode({
    bindings = [
      {
        role    = "roles/run.invoker"
        members = ["allUsers"]
      }
    ]
  })
}
