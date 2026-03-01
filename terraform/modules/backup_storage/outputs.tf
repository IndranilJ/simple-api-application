output "bucket_name" {
  description = "Name of the backup GCS bucket"
  value       = google_storage_bucket.backups.name
}

output "bucket_url" {
  description = "gs:// URI of the backup bucket"
  value       = "gs://${google_storage_bucket.backups.name}"
}
