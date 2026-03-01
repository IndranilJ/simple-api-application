variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "name" {
  type        = string
  description = "Cloud Run service name"
}

variable "image" {
  type        = string
  description = "Full container image URI"
}

variable "connector_id" {
  type        = string
  description = "Serverless VPC Connector ID"
}

variable "sa_email" {
  type        = string
  description = "Runtime service account email"
}

variable "port" {
  description = "Container port to expose"
  type        = number
  default     = 8080
}

variable "command" {
  description = "Override the container entrypoint command. Leave null to use the image default."
  type        = list(string)
  default     = null
}

variable "env_secrets" {
  description = "Map of ENV_VAR_NAME => Secret Manager secret ID. Mounted as env vars at runtime."
  type        = map(string)
  default     = {}
}

variable "env_vars" {
  description = "Map of plain (non-sensitive) environment variables"
  type        = map(string)
  default     = {}
}

variable "make_public" {
  description = "Allow unauthenticated (public) invocations. Set to false for internal services."
  type        = bool
  default     = true
}

variable "cpu" {
  type    = string
  default = "1"
}

variable "memory" {
  type    = string
  default = "512Mi"
}

variable "cpu_idle" {
  type    = bool
  default = true
}

variable "min_instances" {
  type    = number
  default = 0
}

variable "max_instances" {
  type    = number
  default = 5
}

variable "timeout" {
  type    = string
  default = "60s"
}
