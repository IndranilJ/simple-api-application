variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "application_name" {
  description = "Resource name prefix (e.g. 'synapse')"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR range for the primary subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "connector_cidr" {
  description = "CIDR range for the Serverless VPC Connector (/28 required)"
  type        = string
  default     = "10.8.0.0/28"
}
