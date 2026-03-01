# ---------------------------------------------------------------------------------------------------------------------
# MODULE: cloud_run_service
# Creates a single Cloud Run v2 service with VPC connector, env secrets, and IAM invoker.
# Set make_public=false for internal-only services (e.g. the Celery worker).
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
  }
}

resource "google_cloud_run_v2_service" "service" {
  name     = var.name
  location = var.region
  ingress  = var.make_public ? "INGRESS_TRAFFIC_ALL" : "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    service_account = var.sa_email
    timeout         = var.timeout

    containers {
      image   = var.image
      command = var.command != null ? var.command : []

      ports {
        container_port = var.port
      }

      resources {
        cpu_idle = var.cpu_idle
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
      }

      # Mount each secret as an environment variable
      dynamic "env" {
        for_each = var.env_secrets
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value
              version = "latest"
            }
          }
        }
      }

      # Mount plain (non-sensitive) environment variables
      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }
    }

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    vpc_access {
      connector = var.connector_id
      egress    = "PRIVATE_RANGES_ONLY"
    }
  }

  lifecycle {
    # Prevent image tag changes from being ignored — always redeploy on update
    ignore_changes = []
  }
}

# Allow public invocation (unauthenticated) — only when make_public = true
resource "google_cloud_run_v2_service_iam_member" "invoker" {
  count    = var.make_public ? 1 : 0
  location = google_cloud_run_v2_service.service.location
  name     = google_cloud_run_v2_service.service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
