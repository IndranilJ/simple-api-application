variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "domain" {
  description = "The root domain (e.g. synapse-app.com)"
  type        = string
}
