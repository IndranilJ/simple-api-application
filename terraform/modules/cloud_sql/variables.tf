variable "project_id" { type = string }
variable "region"     { type = string }
variable "application_name" { type = string }

variable "vpc_id" {
  type        = string
  description = "VPC network ID for private IP"
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_user" {
  type    = string
  default = "appuser"
}

variable "db_password" {
  description = "Database password. Leave empty to auto-generate."
  type        = string
  default     = ""
  sensitive   = true
}

variable "database_version" {
  type    = string
  default = "POSTGRES_15"
}

variable "tier" {
  description = "Cloud SQL machine tier"
  type        = string
  default     = "db-f1-micro"
}

variable "availability_type" {
  description = "ZONAL or REGIONAL (HA)"
  type        = string
  default     = "ZONAL"
  validation {
    condition     = contains(["ZONAL", "REGIONAL"], var.availability_type)
    error_message = "availability_type must be ZONAL or REGIONAL."
  }
}

variable "disk_size_gb" {
  type    = number
  default = 10
}

variable "deletion_protection" {
  description = "Prevent accidental database deletion. Set to false for teardown."
  type        = bool
  default     = false
}
