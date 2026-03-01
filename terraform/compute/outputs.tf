output "backend_service_name"  { value = module.backend.service_name }
output "backend_service_url"   { value = module.backend.service_url }
output "worker_service_name"   { value = module.worker.service_name }
output "frontend_service_name" { value = module.frontend.service_name }
output "frontend_service_url"  { value = module.frontend.service_url }
