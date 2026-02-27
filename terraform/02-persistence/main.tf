# ---------------------------------------------------------------------------------------------------------------------
# PHASE 2: PERSISTENCE
# Cloud SQL (Private), Memorystore Redis, and Secret Management
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
  backend "gcs" {
    bucket = "synapse-tf-state-project-3a5ecdcf"
    prefix = "persistence"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  prefix = "synapse"
}

# 1. READ REMOTE STATE FROM FOUNDATION
data "terraform_remote_state" "foundation" {
  backend = "gcs"
  config = {
    bucket = "synapse-tf-state-project-3a5ecdcf"
    prefix = "foundation"
  }
}

# 2. RANDOM GENERATORS
resource "random_id" "db_suffix" {
  byte_length = 4
}

resource "random_password" "db_pass" {
  count   = var.db_password == "" ? 1 : 0
  length  = 16
  special = false
}

resource "random_password" "jwt_secret" {
  length  = 32
  special = false
}

# 3. CLOUD SQL (PostgreSQL 15 - Private Only)
resource "google_sql_database_instance" "db_instance" {
  # Adding suffix allows immediate recreation after destroy (bypasses 1-week name reuse lock)
  name             = "${local.prefix}-db-${random_id.db_suffix.hex}"
  database_version = "POSTGRES_15"
  region           = var.region
  
  deletion_protection = var.enable_deletion_protection

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false
      private_network = data.terraform_remote_state.foundation.outputs.vpc_id
    }
    deletion_protection_enabled = var.enable_deletion_protection
  }
}

resource "google_sql_database" "database" {
  name     = "${local.prefix}_db"
  instance = google_sql_database_instance.db_instance.name
}

resource "google_sql_user" "db_user" {
  name     = "synapse"
  instance = google_sql_database_instance.db_instance.name
  password = var.db_password == "" ? random_password.db_pass[0].result : var.db_password
}

# 4. REDIS (Memorystore - Private Only)
resource "google_redis_instance" "redis" {
  name               = "${local.prefix}-redis"
  tier               = "BASIC"
  memory_size_gb     = 1
  region             = var.region
  authorized_network = data.terraform_remote_state.foundation.outputs.vpc_id
}

# 5. SECRETS (Generating and Storing connection strings)
resource "google_secret_manager_secret" "db_url" {
  secret_id = "DATABASE_URL"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_url_v1" {
  secret      = google_secret_manager_secret.db_url.id
  secret_data = "postgresql+asyncpg://synapse:${google_sql_user.db_user.password}@${google_sql_database_instance.db_instance.private_ip_address}/${google_sql_database.database.name}"
}

resource "google_secret_manager_secret" "redis_url" {
  secret_id = "REDIS_URL"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "redis_url_v1" {
  secret      = google_secret_manager_secret.redis_url.id
  secret_data = "redis://${google_redis_instance.redis.host}:6379/0"
}

resource "google_secret_manager_secret" "jwt_secret" {
  secret_id = "JWT_SECRET_KEY"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "jwt_secret_v1" {
  secret      = google_secret_manager_secret.jwt_secret.id
  secret_data = random_password.jwt_secret.result
}

# 6. BACKUP PERMISSIONS
# Grant the Cloud SQL service account access to the backup bucket for exports/imports
resource "google_storage_bucket_iam_member" "sql_backup_admin" {
  bucket = data.terraform_remote_state.foundation.outputs.backup_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_sql_database_instance.db_instance.service_account_email_address}"
}
