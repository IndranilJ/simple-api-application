# Static configuration - us-central1
project_id       = "project-3a5ecdcf-cc00-4004-a9d"
region           = "us-central1"
application_name = "synapse"

# Set by deploy script
vpc_id = "projects/project-3a5ecdcf-cc00-4004-a9d/global/networks/synapse-vpc"

db_name          = "appdb"
db_user          = "appuser"
db_password      = "supersecretpassword123"
jwt_secret_key   = "another-secret-key-456"

deletion_protection = false
sql_tier            = "db-f1-micro"
redis_memory_size_gb = 1
