# =====================================================================================================================
# NETWORKING — Independent Terraform root, own state file (prefix: "networking")
# Calls: vpc, nat modules
# Upstream dependencies: none
# =====================================================================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
    time   = { source = "hashicorp/time",   version = "~> 0.9" }
  }
  backend "gcs" {
    bucket = "synapse-tf-state-project-3a5ecdcf"
    prefix = "networking"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com",
    "vpcaccess.googleapis.com",
    "servicenetworking.googleapis.com",
  ])
  service            = each.key
  disable_on_destroy = false
}

module "vpc" {
  source         = "../modules/vpc"
  project_id     = var.project_id
  region         = var.region
  application_name = var.application_name
  subnet_cidr    = var.subnet_cidr
  connector_cidr = var.connector_cidr
  depends_on     = [google_project_service.apis]
}

module "nat" {
  source   = "../modules/nat"
  application_name = var.application_name
  region   = var.region
  vpc_name = module.vpc.vpc_name
}
