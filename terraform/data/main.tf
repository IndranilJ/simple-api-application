# =====================================================================================================================
# DATA — Independent Terraform root, own state file (prefix: "data")
# Calls: cloud_sql, redis, secret modules
# Upstream values passed explicitly via terraform.tfvars (vpc_id from networking outputs)
# =====================================================================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.5" }
  }
  backend "gcs" {
    bucket = "synapse-tf-state-project-3a5ecdcf"
    prefix = "data"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_service" "apis" {
  for_each = toset([
    "sqladmin.googleapis.com",
    "redis.googleapis.com",
    "secretmanager.googleapis.com",
  ])
  service            = each.key
  disable_on_destroy = false
}

module "cloud_sql" {
  source              = "../modules/cloud_sql"
  project_id          = var.project_id
  region              = var.region
  application_name    = var.application_name
  vpc_id              = var.vpc_id
  db_name             = var.db_name
  db_user             = var.db_user
  db_password         = var.db_password
  deletion_protection = var.deletion_protection
  tier                = var.sql_tier
  depends_on          = [google_project_service.apis]
}

module "redis" {
  source         = "../modules/redis"
  project_id     = var.project_id
  region         = var.region
  application_name = var.application_name
  vpc_id         = var.vpc_id
  memory_size_gb = var.redis_memory_size_gb
  depends_on     = [google_project_service.apis]
}

# Secrets assembled from raw connection data
module "secret_db_url" {
  source     = "../modules/secret"
  project_id = var.project_id
  secret_id  = "DATABASE_URL"
  value      = "postgresql+asyncpg://${module.cloud_sql.db_user}:${module.cloud_sql.db_password}@${module.cloud_sql.private_ip}:5432/${module.cloud_sql.db_name}"
}

module "secret_redis_url" {
  source     = "../modules/secret"
  project_id = var.project_id
  secret_id  = "REDIS_URL"
  value      = "redis://${module.redis.host}:${module.redis.port}/0"
}

module "secret_jwt" {
  source     = "../modules/secret"
  project_id = var.project_id
  secret_id  = "JWT_SECRET_KEY"
  value      = var.jwt_secret_key   # empty = auto-generated inside module
}
