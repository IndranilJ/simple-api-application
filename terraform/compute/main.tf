# =====================================================================================================================
# COMPUTE — Independent Terraform root, own state file (prefix: "compute")
# Calls: cloud_run_service module (backend, worker, frontend)
# Upstream values: connector_id, sa_email, secret IDs — written to terraform.tfvars by deploy script
# =====================================================================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
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

resource "google_project_service" "run" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

module "backend" {
  source       = "../modules/cloud_run_service"
  project_id   = var.project_id
  region       = var.region
  name         = "${var.application_name}-backend"
  image        = var.backend_image
  port         = 8004
  connector_id = var.connector_id
  sa_email     = var.sa_email
  make_public  = true
  env_secrets = {
    DATABASE_URL   = var.secret_db_url_id
    REDIS_URL      = var.secret_redis_url_id
    JWT_SECRET_KEY = var.secret_jwt_id
  }
  env_vars    = { ROOT_PATH = "/api" }
  depends_on  = [google_project_service.run]
}

module "worker" {
  source       = "../modules/cloud_run_service"
  project_id   = var.project_id
  region       = var.region
  name         = "${var.application_name}-worker"
  image        = var.backend_image
  port         = 8080
  connector_id = var.connector_id
  sa_email     = var.sa_email
  make_public   = false
  command       = ["python", "run_worker.py"]
  min_instances = 1
  cpu_idle      = false
  env_secrets = {
    DATABASE_URL   = var.secret_db_url_id
    REDIS_URL      = var.secret_redis_url_id
    JWT_SECRET_KEY = var.secret_jwt_id
  }
  depends_on = [google_project_service.run]
}

module "frontend" {
  source       = "../modules/cloud_run_service"
  project_id   = var.project_id
  region       = var.region
  name         = "${var.application_name}-frontend"
  image        = var.frontend_image
  port         = 80
  connector_id = var.connector_id
  sa_email     = var.sa_email
  make_public  = true
  depends_on   = [google_project_service.run]
}
