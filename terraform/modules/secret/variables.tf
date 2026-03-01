variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "secret_id" {
  description = "The name/ID of the secret in Secret Manager"
  type        = string
}

variable "value" {
  description = "The secret value. Leave empty ('') to auto-generate a secure random password."
  type        = string
  default     = ""
  sensitive   = true
}

variable "allow_special_chars" {
  description = "Allow special characters in auto-generated passwords. Set to false for connection strings."
  type        = bool
  default     = false
}
