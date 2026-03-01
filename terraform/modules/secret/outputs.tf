output "secret_id" {
  description = "The Secret Manager secret ID (reference for IAM and env bindings)"
  value       = google_secret_manager_secret.secret.id
}

output "secret_name" {
  description = "The resource name of the secret (projects/PROJECT/secrets/SECRET_ID)"
  value       = google_secret_manager_secret.secret.name
}

output "version_id" {
  description = "The resource name of the secret version"
  value       = google_secret_manager_secret_version.version.id
}
