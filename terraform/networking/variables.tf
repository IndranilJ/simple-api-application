variable "project_id"     { type = string }
variable "region"         { type = string }
variable "application_name" { type = string }

variable "subnet_cidr" {
  type    = string
  default = "10.0.0.0/24"
}

variable "connector_cidr" {
  type    = string
  default = "10.8.0.0/28"
}
