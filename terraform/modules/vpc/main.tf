# ---------------------------------------------------------------------------------------------------------------------
# MODULE: vpc
# Creates the full private network: VPC, Subnet, Service Peering, VPC Connector, and a stability wait.
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
    time   = { source = "hashicorp/time",   version = "~> 0.9" }
  }
}

# Enable required APIs (idempotent — safe to call multiple times)
resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com",
    "vpcaccess.googleapis.com",
    "servicenetworking.googleapis.com",
  ])
  service            = each.key
  disable_on_destroy = false
}

resource "google_compute_network" "vpc" {
  name                    = "${var.application_name}-vpc"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.apis]
}

resource "google_compute_subnetwork" "subnet" {
  name                     = "${var.application_name}-subnet-${var.region}"
  ip_cidr_range            = var.subnet_cidr
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true # Allows VMs to reach Google APIs without external IPs
}

# Private Service Access (required for Cloud SQL private IP)
resource "google_compute_global_address" "private_ip_range" {
  name          = "${var.application_name}-private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "peering" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
  update_on_creation_fail = true # handles "already allocated" error on re-create
  depends_on              = [google_project_service.apis]
}

# CRITICAL: GCP peering propagation can take up to 60s.
# Without this pause, downstream resources (Cloud SQL, Redis) fail to connect.
resource "time_sleep" "wait_for_peering" {
  depends_on      = [google_service_networking_connection.peering]
  create_duration = "60s"
}

# Serverless VPC Connector — allows Cloud Run to reach private resources
resource "google_vpc_access_connector" "connector" {
  name          = "${var.application_name}-connector"
  region        = var.region
  ip_cidr_range = var.connector_cidr
  network       = google_compute_network.vpc.name
  min_instances = 2
  max_instances = 3
  depends_on    = [google_project_service.apis, google_compute_network.vpc]
}
