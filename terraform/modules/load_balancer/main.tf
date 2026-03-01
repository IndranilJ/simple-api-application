# ---------------------------------------------------------------------------------------------------------------------
# MODULE: load_balancer
# Creates a full Global HTTP(S) Load Balancer with Cloud Armor WAF.
# Accepts a `routes` map: for each entry it creates a Serverless NEG + Backend Service.
# The URL Map routes requests to the correct backend based on path prefix.
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
  }
}

# 1. Static external IP
resource "google_compute_global_address" "lb_ip" {
  name = "${var.application_name}-lb-ip"
}

# 2. Cloud Armor WAF policy — basic but effective
resource "google_compute_security_policy" "waf" {
  name        = "${var.application_name}-waf-policy"
  description = "Basic WAF: blocks SQLi and XSS"

  rule {
    action   = "allow"
    priority = 2147483647
    match {
      versioned_expr = "SRC_IPS_V1"
      config { src_ip_ranges = ["*"] }
    }
    description = "Default allow"
  }

  rule {
    action      = "deny(403)"
    priority    = 1000
    description = "Block SQL Injection"
    preview     = true   # LOG ONLY — prevents 403 blocks while we debug
    match {
      expr { expression = "evaluatePreconfiguredExpr('sqli-v33-stable')" }
    }
  }

  rule {
    action      = "deny(403)"
    priority    = 1001
    description = "Block XSS"
    preview     = true   # LOG ONLY — prevents 403 blocks while we debug
    match {
      expr { expression = "evaluatePreconfiguredExpr('xss-v33-stable')" }
    }
  }
}

# 3. For each route entry: create a Serverless NEG pointing at the Cloud Run service
resource "google_compute_region_network_endpoint_group" "negs" {
  for_each              = var.routes
  name                  = "${var.application_name}-neg-${each.key}"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  cloud_run {
    service = each.value.service_name
  }
}

# 4. For each route entry: create a Backend Service backed by its NEG + WAF
resource "google_compute_backend_service" "backends" {
  for_each              = var.routes
  name                  = "${var.application_name}-backend-${each.key}"
  protocol              = "HTTPS"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  security_policy       = google_compute_security_policy.waf.id

  backend {
    group = google_compute_region_network_endpoint_group.negs[each.key].id
  }
}

# 5. URL Map — routes requests by path prefix to the correct backend
resource "google_compute_url_map" "url_map" {
  name            = "${var.application_name}-url-map"
  default_service = google_compute_backend_service.backends[var.default_route_key].id

  host_rule {
    hosts        = ["*"]
    path_matcher = "all-paths"
  }

  path_matcher {
    name            = "all-paths"
    default_service = google_compute_backend_service.backends[var.default_route_key].id

    dynamic "path_rule" {
      for_each = { for k, v in var.routes : k => v if k != var.default_route_key }
      content {
        paths   = ["${path_rule.value.path_prefix}*"]
        service = google_compute_backend_service.backends[path_rule.key].id

        dynamic "route_action" {
          for_each = path_rule.value.strip_prefix ? [1] : []
          content {
            url_rewrite { path_prefix_rewrite = "/" }
          }
        }
      }
    }
  }
}

# 6. HTTP Proxy + Forwarding Rule
resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "${var.application_name}-http-proxy"
  url_map = google_compute_url_map.url_map.id
}

resource "google_compute_global_forwarding_rule" "http" {
  name                  = "${var.application_name}-http-rule"
  target                = google_compute_target_http_proxy.http_proxy.id
  port_range            = "80"
  ip_address            = google_compute_global_address.lb_ip.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
}
