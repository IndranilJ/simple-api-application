output "sa_email"    { value = module.service_account.sa_email }
output "repo_url"    { value = module.artifact_registry.repo_url }
output "bucket_name" { value = module.backup_storage.bucket_name }
output "bucket_url"  { value = module.backup_storage.bucket_url }
