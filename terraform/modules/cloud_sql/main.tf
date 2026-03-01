# ---------------------------------------------------------------------------------------------------------------------
# MODULE: cloud_sql
# Creates a Cloud SQL (PostgreSQL) instance with private IP, a database, and a user.
# Uses random_id suffix to bypass GCP's 1-week name reuse limitation after deletion.
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.5" }
  }
}

# Random suffix = instance can be recreated immediately after a destroy
resource "random_id" "instance_suffix" {
  byte_length = 4
}

# Auto-generate a DB password if one is not provided
resource "random_password" "db_password" {
  count   = var.db_password == "" ? 1 : 0
  length  = 24
  special = false # Avoid chars that break connection strings
}

locals {
  db_password   = var.db_password != "" ? var.db_password : random_password.db_password[0].result
  instance_name = "${var.application_name}-db-${random_id.instance_suffix.hex}"
}

resource "google_sql_database_instance" "db" {
  name                = local.instance_name
  database_version    = var.database_version
  region              = var.region
  deletion_protection = var.deletion_protection

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_autoresize   = true
    disk_size         = var.disk_size_gb

    ip_configuration {
      ipv4_enabled                                  = false # Private IP only — no public exposure
      private_network                               = var.vpc_id
      enable_private_path_for_google_cloud_services = true
    }

    backup_configuration {
      enabled            = true
      binary_log_enabled = false # Not supported for Postgres
      start_time         = "03:00" # Run backups at 3am
    }

    insights_config {
      query_insights_enabled = true
    }
  }
}

resource "google_sql_database" "database" {
  name     = var.db_name
  instance = google_sql_database_instance.db.name
}

resource "google_sql_user" "user" {
  name     = var.db_user
  instance = google_sql_database_instance.db.name
  password = local.db_password
}
