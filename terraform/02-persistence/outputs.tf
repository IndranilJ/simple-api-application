output "db_private_ip" {
  value = google_sql_database_instance.db_instance.private_ip_address
}

output "redis_host" {
  value = google_redis_instance.redis.host
}

output "db_instance_name" {
  value = google_sql_database_instance.db_instance.name
}

output "db_name" {
  value = google_sql_database.database.name
}
