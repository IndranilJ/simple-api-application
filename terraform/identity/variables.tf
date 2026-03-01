variable "project_id" { type = string }
variable "region"     { type = string }
variable "application_name" { type = string }

variable "backup_retention_days" {
  type    = number
  default = 30
}

variable "sa_roles" {
  description = "IAM roles to grant the runtime service account"
  type        = list(string)
  default = [
    "roles/secretmanager.secretAccessor",
    "roles/cloudsql.client",
    "roles/artifactregistry.reader",
  ]
}

# --- Upstream from data layer (set by deploy script after data apply) ---
variable "sql_sa_email" {
  type        = string
  description = "Cloud SQL instance SA email — copy from: cd ../data && terraform output -raw sql_sa_email"
}
