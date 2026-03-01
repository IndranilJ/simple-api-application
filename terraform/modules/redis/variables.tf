variable "project_id"     { type = string }
variable "region"         { type = string }
variable "application_name" { type = string }

variable "vpc_id" {
  type        = string
  description = "VPC network ID"
}

variable "tier" {
  type    = string
  default = "BASIC"
  validation {
    condition     = contains(["BASIC", "STANDARD_HA"], var.tier)
    error_message = "Redis tier must be BASIC or STANDARD_HA."
  }
}

variable "memory_size_gb" {
  type    = number
  default = 1
}

variable "redis_version" {
  type    = string
  default = "REDIS_7_0"
}
