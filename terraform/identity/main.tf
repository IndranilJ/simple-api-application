# =====================================================================================================================
# IDENTITY — Independent Terraform root, own state file (prefix: "identity")
# Calls: service_account, artifact_registry, backup_storage modules
# Upstream values: sql_sa_email from data layer outputs → written to terraform.tfvars by deploy script
# =====================================================================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.5" }
  }
  backend "gcs" {
    bucket = "synapse-tf-state-project-3a5ecdcf"
    prefix = "identity"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_service" "apis" {
  for_each = toset([
    "iam.googleapis.com",
    "artifactregistry.googleapis.com",
    "storage.googleapis.com",
  ])
  service            = each.key
  disable_on_destroy = false
}

module "service_account" {
  source     = "../modules/service_account"
  project_id = var.project_id
  application_name = var.application_name
  roles      = var.sa_roles
}

module "artifact_registry" {
  source     = "../modules/artifact_registry"
  project_id = var.project_id
  region     = var.region
  application_name = var.application_name
  depends_on = [google_project_service.apis]
}

module "backup_storage" {
  source                = "../modules/backup_storage"
  project_id            = var.project_id
  region                = var.region
  application_name      = var.application_name
  sql_sa_email          = var.sql_sa_email
  backup_retention_days = var.backup_retention_days
}
