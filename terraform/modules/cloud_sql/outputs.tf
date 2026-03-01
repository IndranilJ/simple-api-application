output "instance_name" {
  value = google_sql_database_instance.db.name
}

output "private_ip" {
  description = "Private IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.db.private_ip_address
}

output "db_name" {
  value = google_sql_database.database.name
}

output "db_user" {
  value = google_sql_user.user.name
}

output "db_password" {
  description = "The database password (generated or provided). Used by the secret module to build DATABASE_URL."
  value       = local.db_password
  sensitive   = true
}

output "sa_email" {
  description = "The Cloud SQL instance's own service account email (for backup bucket IAM)"
  value       = google_sql_database_instance.db.service_account_email_address
}
