variable "project_id" { type = string }
variable "region"     { type = string }
variable "application_name" { type = string }

# --- Upstream from compute layer (set by deploy script after compute apply) ---
variable "backend_service_name" {
  type        = string
  description = "Cloud Run backend service name — copy from: cd ../compute && terraform output -raw backend_service_name"
}

variable "frontend_service_name" {
  type        = string
  description = "Cloud Run frontend service name — copy from: cd ../compute && terraform output -raw frontend_service_name"
}
