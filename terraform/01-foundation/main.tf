# ---------------------------------------------------------------------------------------------------------------------
# PHASE 1: FOUNDATION
# APIs, Networking (VPC + Peering), Identity, and Artifact Registry
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
  backend "gcs" {
    bucket = "synapse-tf-state-project-3a5ecdcf"
    prefix = "foundation"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  prefix = "synapse"
}

# 1. ENABLE SERVICES
resource "google_project_service" "services" {
  for_each = toset([
    "compute.googleapis.com",
    "run.googleapis.com",
    "sqladmin.googleapis.com",
    "redis.googleapis.com",
    "secretmanager.googleapis.com",
    "vpcaccess.googleapis.com",
    "servicenetworking.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
  ])
  service            = each.key
  disable_on_destroy = false
}

# 2. NETWORKING
resource "google_compute_network" "vpc" {
  name                    = "${local.prefix}-vpc"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.services]
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${local.prefix}-subnet-${var.region}"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Private Service Access (Required for Private IP Cloud SQL)
resource "google_compute_global_address" "private_ip_address" {
  name          = "${local.prefix}-private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# CRITICAL: Pause to allow GCP peering to propagate. 
# Prevents downstream "Network not found" or "Peering not ready" errors.
resource "time_sleep" "wait_for_peering" {
  depends_on = [google_service_networking_connection.private_vpc_connection]
  create_duration = "60s"
}

# Serverless VPC Access Connector (For Cloud Run -> Redis/DB)
resource "google_vpc_access_connector" "connector" {
  name          = "${local.prefix}-connector"
  region        = var.region
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.vpc.name
  depends_on    = [google_project_service.services]
}

# 3. IDENTITY (Service Account)
resource "google_service_account" "runtime_sa" {
  account_id   = "${local.prefix}-runtime-sa"
  display_name = "Synapse Runtime Service Account"
}

resource "google_project_iam_member" "runtime_sa_secrets" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.runtime_sa.email}"
}

resource "google_project_iam_member" "runtime_sa_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.runtime_sa.email}"
}

# 4. ARTIFACT REGISTRY
resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "${local.prefix}-repo"
  description   = "Docker repository for Synapse images"
  format        = "DOCKER"
  depends_on    = [google_project_service.services]
}

# 5. BACKUP STORAGE
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "google_storage_bucket" "backups" {
  name          = "${local.prefix}-backups-${random_id.bucket_suffix.hex}"
  location      = var.region
  force_destroy = true # Essential for automated teardowns
  
  public_access_prevention = "enforced"
}

# 6. CLOUD NAT (For outbound internet access from private VPC)
resource "google_compute_router" "router" {
  name    = "${local.prefix}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${local.prefix}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
