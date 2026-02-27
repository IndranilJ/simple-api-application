# ---------------------------------------------------------------------------------------------------------------------
# PHASE 3: COMPUTE
# Cloud Run Services (Backend, Worker, Frontend) and DB Migrations
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  backend "gcs" {
    bucket = "synapse-tf-state-project-3a5ecdcf"
    prefix = "compute"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  prefix = "synapse"
}

# 1. READ REMOTE STATES
data "terraform_remote_state" "foundation" {
  backend = "gcs"
  config = {
    bucket = "synapse-tf-state-project-3a5ecdcf"
    prefix = "foundation"
  }
}

data "terraform_remote_state" "persistence" {
  backend = "gcs"
  config = {
    bucket = "synapse-tf-state-project-3a5ecdcf"
    prefix = "persistence"
  }
}

# 2. CLOUD RUN: BACKEND API
resource "google_cloud_run_v2_service" "backend" {
  name     = "${local.prefix}-backend"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER" # Locked to LB

  template {
    service_account = data.terraform_remote_state.foundation.outputs.runtime_sa_email
    
    vpc_access {
      connector = data.terraform_remote_state.foundation.outputs.connector_id
      egress    = "ALL_TRAFFIC"
    }

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${local.prefix}-repo/backend:${var.image_tag}"
      ports {
        container_port = 8004
      }
      
      # Secrets injection
      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = "DATABASE_URL"
            version = "latest"
          }
        }
      }
      env {
        name = "REDIS_URL"
        value_source {
          secret_key_ref {
            secret  = "REDIS_URL"
            version = "latest"
          }
        }
      }
      env {
        name = "JWT_SECRET_KEY"
        value_source {
          secret_key_ref {
            secret  = "JWT_SECRET_KEY"
            version = "latest"
          }
        }
      }
      env {
        name  = "ROOT_PATH"
        value = "/api"
      }
    }
  }

  # Explicit dependency to ensure secret versions exist before service deployment
  depends_on = [
    data.terraform_remote_state.persistence
  ]
}

# 3. CLOUD RUN: CELERY WORKER
resource "google_cloud_run_v2_service" "worker" {
  name     = "${local.prefix}-worker"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY" # No LB access required

  template {
    service_account = data.terraform_remote_state.foundation.outputs.runtime_sa_email
    
    vpc_access {
      connector = data.terraform_remote_state.foundation.outputs.connector_id
      egress    = "ALL_TRAFFIC"
    }

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${local.prefix}-repo/backend:${var.image_tag}"
      command = ["python", "run_worker.py"]
      
      ports {
        container_port = 8080
      }

      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = "DATABASE_URL"
            version = "latest"
          }
        }
      }
      env {
        name = "REDIS_URL"
        value_source {
          secret_key_ref {
            secret  = "REDIS_URL"
            version = "latest"
          }
        }
      }
      env {
        name = "JWT_SECRET_KEY"
        value_source {
          secret_key_ref {
            secret  = "JWT_SECRET_KEY"
            version = "latest"
          }
        }
      }
      env {
        name  = "ROOT_PATH"
        value = "/api"
      }
    }
    
    scaling {
      min_instance_count = 1 # Keep warm for tasks
    }
  }

  depends_on = [
    data.terraform_remote_state.persistence
  ]
}

# 4. CLOUD RUN: FRONTEND
resource "google_cloud_run_v2_service" "frontend" {
  name     = "${local.prefix}-frontend"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${local.prefix}-repo/frontend:${var.image_tag}"
      ports {
        container_port = 80
      }
    }
  }
}

# 5. DB MIGRATION JOB
resource "google_cloud_run_v2_job" "db_init" {
  name     = "${local.prefix}-db-init"
  location = var.region

  template {
    template {
      service_account = data.terraform_remote_state.foundation.outputs.runtime_sa_email
      
      vpc_access {
        connector = data.terraform_remote_state.foundation.outputs.connector_id
        egress    = "ALL_TRAFFIC"
      }

      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/${local.prefix}-repo/backend:${var.image_tag}"
        command = ["python", "-c", "from app.db import init_db; import asyncio; asyncio.run(init_db())"]
        
        env {
          name = "DATABASE_URL"
          value_source {
            secret_key_ref {
              secret  = "DATABASE_URL"
              version = "latest"
            }
          }
        }
      }
    }
  }

  depends_on = [
    data.terraform_remote_state.persistence
  ]
}

# 6. IAM: PUBLIC INVOKER (For LB access)
resource "google_cloud_run_v2_service_iam_member" "backend_invoker" {
  location = var.region
  name     = google_cloud_run_v2_service.backend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_v2_service_iam_member" "frontend_invoker" {
  location = var.region
  name     = google_cloud_run_v2_service.frontend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
