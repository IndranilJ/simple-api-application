# ---------------------------------------------------------------------------------------------------------------------
# MODULE: secret
# Generic, smart secret module.
# - If `value` is provided, stores it in Secret Manager.
# - If `value` is empty (""), auto-generates a cryptographically secure random password.
# This pattern means secrets are ALWAYS managed — never optional or forgotten.
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.5" }
  }
}

resource "google_project_service" "secretmanager" {
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

# Conditionally generate a password — only when the caller did not provide one
resource "random_password" "generated" {
  count   = var.value == "" ? 1 : 0
  length  = 32
  special = var.allow_special_chars
  # Exclude chars that commonly cause parsing issues in connection strings
  override_special = "!#$%^&*()-_=+[]{}|;:,.<>?"
}

locals {
  # Use the provided value if available, otherwise use the auto-generated one
  secret_value = var.value != "" ? var.value : random_password.generated[0].result
}

resource "google_secret_manager_secret" "secret" {
  secret_id = var.secret_id
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "version" {
  secret      = google_secret_manager_secret.secret.id
  secret_data = local.secret_value
}
