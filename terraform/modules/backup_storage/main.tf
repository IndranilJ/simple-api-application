# ---------------------------------------------------------------------------------------------------------------------
# MODULE: backup_storage
# Creates the GCS backup bucket and grants the Cloud SQL SA permissions to import/export.
# force_destroy=true ensures the bucket doesn't block terraform destroy.
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.5" }
  }
}

# Random suffix ensures bucket name is globally unique and avoids reuse conflicts
resource "random_id" "suffix" {
  byte_length = 4
}

resource "google_storage_bucket" "backups" {
  name                        = "${var.application_name}-backups-${random_id.suffix.hex}"
  location                    = var.region
  force_destroy               = true # Essential: prevents bucket from blocking terraform destroy
  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true

  lifecycle_rule {
    condition { age = var.backup_retention_days }
    action    { type = "Delete" }
  }
}

# Grant Cloud SQL's own service account write access so it can export/import to this bucket
resource "google_storage_bucket_iam_member" "sql_backup_writer" {
  bucket = google_storage_bucket.backups.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.sql_sa_email}"
}
