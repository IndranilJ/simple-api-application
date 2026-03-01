output "host" {
  description = "Private IP of the Redis instance"
  value       = google_redis_instance.redis.host
}

output "port" {
  description = "Port of the Redis instance"
  value       = google_redis_instance.redis.port
}
