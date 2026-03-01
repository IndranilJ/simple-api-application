output "vpc_id"           { value = module.vpc.vpc_id }
output "vpc_name"         { value = module.vpc.vpc_name }
output "subnet_id"        { value = module.vpc.subnet_id }
output "connector_id"     { value = module.vpc.connector_id }
output "peering_complete" { value = module.vpc.peering_complete }
