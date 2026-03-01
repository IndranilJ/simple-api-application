# ---------------------------------------------------------------------------------------------------------------------
# MODULE: nat
# Creates Cloud Router + Cloud NAT for outbound internet from private VPC.
# ---------------------------------------------------------------------------------------------------------------------

resource "google_compute_router" "router" {
  name    = "${var.application_name}-router"
  region  = var.region
  network = var.vpc_name
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.application_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
