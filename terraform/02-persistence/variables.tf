variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "db_password" {
  type      = string
  sensitive = true
  default   = "" # Use random if empty
}

variable "enable_deletion_protection" {
  type    = bool
  default = false
}
