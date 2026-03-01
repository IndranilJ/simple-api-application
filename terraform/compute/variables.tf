variable "project_id"     { type = string }
variable "region"         { type = string }
variable "application_name" { type = string }
variable "backend_image"  { type = string }
variable "frontend_image" { type = string }

# --- Upstream from networking layer ---
variable "connector_id" {
  type        = string
  description = "VPC Connector ID — copy from: cd ../networking && terraform output -raw connector_id"
}

# --- Upstream from identity layer ---
variable "sa_email" {
  type        = string
  description = "Runtime SA email — copy from: cd ../identity && terraform output -raw sa_email"
}

# --- Upstream from data layer ---
variable "secret_db_url_id" {
  type        = string
  description = "Secret ID — copy from: cd ../data && terraform output -raw secret_db_url_id"
}

variable "secret_redis_url_id" {
  type        = string
  description = "Secret ID — copy from: cd ../data && terraform output -raw secret_redis_url_id"
}

variable "secret_jwt_id" {
  type        = string
  description = "Secret ID — copy from: cd ../data && terraform output -raw secret_jwt_id"
}
