# ---------------------------------------------------------------------------------------------------------------------
# MODULE: redis
# Creates a Memorystore Redis instance on the private VPC.
# ---------------------------------------------------------------------------------------------------------------------

resource "google_project_service" "redis" {
  service            = "redis.googleapis.com"
  disable_on_destroy = false
}

resource "google_redis_instance" "redis" {
  name           = "${var.application_name}-redis"
  tier           = var.tier
  memory_size_gb = var.memory_size_gb
  region         = var.region
  location_id    = "${var.region}-a"
  redis_version  = var.redis_version

  authorized_network = var.vpc_id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"

  depends_on = [google_project_service.redis]
}
