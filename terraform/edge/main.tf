# =====================================================================================================================
# EDGE — Independent Terraform root, own state file (prefix: "edge")
# Calls: load_balancer module
# Upstream values: backend/frontend service names — written to terraform.tfvars by deploy script
# =====================================================================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
  }
  backend "gcs" {
    bucket = "synapse-tf-state-project-3a5ecdcf"
    prefix = "edge"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "load_balancer" {
  source            = "../modules/load_balancer"
  project_id        = var.project_id
  region            = var.region
  application_name  = var.application_name
  default_route_key = "frontend"

  routes = {
    frontend = {
      service_name = var.frontend_service_name
      path_prefix  = "/"
      strip_prefix = false
    }
    backend = {
      service_name = var.backend_service_name
      path_prefix  = "/api"
      strip_prefix = true
    }
  }
}
