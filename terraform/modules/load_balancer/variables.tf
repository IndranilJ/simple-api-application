variable "project_id" { type = string }
variable "region"     { type = string }
variable "application_name" { type = string }

variable "routes" {
  description = <<EOT
Map of named route entries. Each creates one NEG + Backend Service.
Example:
  routes = {
    frontend = { service_name = "synapse-frontend", path_prefix = "/",    strip_prefix = false }
    backend  = { service_name = "synapse-backend",  path_prefix = "/api", strip_prefix = true  }
  }
EOT
  type = map(object({
    service_name  = string
    path_prefix   = string
    strip_prefix  = optional(bool, false)
  }))
}

variable "default_route_key" {
  description = "The key in `routes` that is used as the LB default service (catch-all)."
  type        = string
  default     = "frontend"
}
