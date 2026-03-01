variable "project_id" { type = string }
variable "region"     { type = string }
variable "application_name" { type = string }

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_user" {
  type    = string
  default = "appuser"
}

variable "db_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "sql_tier" {
  type    = string
  default = "db-f1-micro"
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "redis_memory_size_gb" {
  type    = number
  default = 1
}

variable "jwt_secret_key" {
  type      = string
  default   = ""
  sensitive = true
}

# --- Upstream from networking layer (set by deploy script after networking apply) ---
variable "vpc_id" {
  type        = string
  description = "VPC ID — copy from: cd networking && terraform output -raw vpc_id"
}
