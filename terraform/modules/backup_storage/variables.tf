variable "project_id" { type = string }
variable "region"     { type = string }
variable "application_name" { type = string }

variable "sql_sa_email" {
  description = "The Cloud SQL instance's own service account email (for backup IAM binding)"
  type        = string
}

variable "backup_retention_days" {
  description = "Number of days to retain backup files in GCS before auto-deletion"
  type        = number
  default     = 30
}
