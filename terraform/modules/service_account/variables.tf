variable "project_id" { type = string }
variable "application_name" { type = string }

variable "roles" {
  description = "List of IAM roles to grant to the runtime service account."
  type        = list(string)
  default = [
    "roles/secretmanager.secretAccessor",
    "roles/cloudsql.client",
    "roles/artifactregistry.reader",
  ]
}
