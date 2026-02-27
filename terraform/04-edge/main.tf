# ---------------------------------------------------------------------------------------------------------------------
# PHASE 4: GLOBAL EDGE
# Global HTTP(S) Load Balancer, SSL, and Cloud Armor (WAF)
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
    prefix = "edge"
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
data "terraform_remote_state" "compute" {
  backend = "gcs"
  config = {
    bucket = "synapse-tf-state-project-3a5ecdcf"
    prefix = "compute"
  }
}

# 2. GLOBAL IP ADDRESS
resource "google_compute_global_address" "lb_ip" {
  name = "${local.prefix}-lb-ip"
}

# 3. CLOUD ARMOR (WAF)
resource "google_compute_security_policy" "waf" {
  name        = "${local.prefix}-waf-policy"
  description = "Basic WAF protection - SQLi and XSS"

  # Default rule (allow)
  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "default rule"
  }

  # Prevent SQL Injection
  rule {
    action   = "deny(403)"
    priority = "1000"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-v33-stable')"
      }
    }
    description = "Deny SQL Injection"
  }

  # Prevent Cross-Site Scripting
  rule {
    action   = "deny(403)"
    priority = "1001"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-v33-stable')"
      }
    }
    description = "Deny XSS"
  }
}

# 4. SERVERLESS NEGs (The adapters for Cloud Run)
resource "google_compute_region_network_endpoint_group" "fe_neg" {
  name                  = "${local.prefix}-fe-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = data.terraform_remote_state.compute.outputs.frontend_service_name
  }
}

resource "google_compute_region_network_endpoint_group" "be_neg" {
  name                  = "${local.prefix}-be-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = data.terraform_remote_state.compute.outputs.backend_service_name
  }
}

# 5. BACKEND SERVICES (The LB internal targets)
resource "google_compute_backend_service" "fe_backend" {
  name                  = "${local.prefix}-fe-backend"
  protocol              = "HTTPS"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  security_policy       = google_compute_security_policy.waf.id

  backend {
    group = google_compute_region_network_endpoint_group.fe_neg.id
  }
}

resource "google_compute_backend_service" "be_backend" {
  name                  = "${local.prefix}-be-backend"
  protocol              = "HTTPS"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  security_policy       = google_compute_security_policy.waf.id

  backend {
    group = google_compute_region_network_endpoint_group.be_neg.id
  }
}

# 6. URL MAP (Routing Logic - Path-Based for IP-only setup)
resource "google_compute_url_map" "url_map" {
  name            = "${local.prefix}-url-map"
  default_service = google_compute_backend_service.fe_backend.id

  # Path-Based Routing (Used when you have NO DOMAIN)
  host_rule {
    hosts        = ["*"]
    path_matcher = "all-paths"
  }

  path_matcher {
    name            = "all-paths"
    default_service = google_compute_backend_service.fe_backend.id

    path_rule {
      paths   = ["/api/*"]
      service = google_compute_backend_service.be_backend.id
      route_action {
        url_rewrite {
          path_prefix_rewrite = "/"
        }
      }
    }
  }
}

# 7. HTTP PROXY & FORWARDING RULE
resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "${local.prefix}-http-proxy"
  url_map = google_compute_url_map.url_map.id
}

resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  name                  = "${local.prefix}-http-rule"
  target                = google_compute_target_http_proxy.http_proxy.id
  port_range            = "80"
  ip_address            = google_compute_global_address.lb_ip.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
}
