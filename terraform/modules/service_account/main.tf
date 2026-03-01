# ---------------------------------------------------------------------------------------------------------------------
# MODULE: service_account
# Creates a runtime service account and grants it a configurable list of IAM roles.
# ---------------------------------------------------------------------------------------------------------------------

resource "google_service_account" "sa" {
  account_id   = "${var.application_name}-runtime-sa"
  display_name = "${var.application_name} Runtime Service Account"
  project      = var.project_id
}

# Grant each role in the provided list — fully dynamic
resource "google_project_iam_member" "roles" {
  for_each = toset(var.roles)
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.sa.email}"
}
