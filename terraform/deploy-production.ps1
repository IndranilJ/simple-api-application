# ==============================================================================
# 🧩 Configuration
# ==============================================================================
$ProjectId = "project-3a5ecdcf-cc00-4004-a9d"
$Region = "us-central1"
$Bucket = "synapse-tf-state-project-3a5ecdcf"
$TF = "$PSScriptRoot"

Write-Host "`nSynapse Production Deploy (Static TFVARS)" -ForegroundColor Cyan

$CredFile = "$PSScriptRoot/gcpcred.json"
if (Test-Path $CredFile) {
    $env:GOOGLE_APPLICATION_CREDENTIALS = $CredFile
    Write-Host "[auth] Service account credentials loaded." -ForegroundColor Green
}

# Helper: update a key=value line in a terraform.tfvars file
function Set-TfVar {
    param([string]$File, [string]$Key, [string]$Value)
    if (-not (Test-Path $File)) { throw "TfVars file not found: $File" }
    $content = Get-Content $File
    $content = $content -replace "^$Key\s*=.*", "$Key = `"$Value`""
    Set-Content $File $content
    Write-Host "  [set] $Key -> $(Split-Path $File -Leaf)" -ForegroundColor Gray
}

# Helper: init + apply a single domain
function Invoke-TerraformApply {
    param([string]$Dir)
    $name = Split-Path $Dir -Leaf
    Write-Host "`n----- Applying: $name -----" -ForegroundColor Cyan
    Push-Location $Dir
    terraform init -reconfigure -upgrade -input=false
    if ($LASTEXITCODE -ne 0) { Pop-Location; throw "Init failed: $Dir" }
    terraform apply -auto-approve -input=false
    if ($LASTEXITCODE -ne 0) { Pop-Location; throw "Apply failed: $Dir" }
    Pop-Location
    Write-Host "[done] $name" -ForegroundColor Green
}

# Ensure state bucket exists
$exists = gcloud storage buckets list --filter="name:$Bucket" --format="value(name)" 2>$null
if (-not $exists) {
    gcloud storage buckets create "gs://$Bucket" --project=$ProjectId --location=$Region
    Write-Host "[bootstrap] Created state bucket $Bucket" -ForegroundColor Green
}

# ==============================================================================
# 1. NETWORKING
# ==============================================================================
Invoke-TerraformApply "$TF/networking"

Write-Host "[wire] networking -> data, compute" -ForegroundColor Yellow
Push-Location "$TF/networking"
$vpc_id = terraform output -raw vpc_id
$connector_id = terraform output -raw connector_id
Pop-Location

Set-TfVar "$TF/data/terraform.tfvars"    "vpc_id"       $vpc_id
Set-TfVar "$TF/compute/terraform.tfvars" "connector_id" $connector_id

# ==============================================================================
# 2. DATA
# ==============================================================================
Invoke-TerraformApply "$TF/data"

Write-Host "[wire] data -> identity, compute" -ForegroundColor Yellow
Push-Location "$TF/data"
$sql_sa_email = terraform output -raw sql_sa_email
$secret_db_url_id = terraform output -raw secret_db_url_id
$secret_redis_url_id = terraform output -raw secret_redis_url_id
$secret_jwt_id = terraform output -raw secret_jwt_id
Pop-Location

Set-TfVar "$TF/identity/terraform.tfvars" "sql_sa_email"        $sql_sa_email
Set-TfVar "$TF/compute/terraform.tfvars"  "secret_db_url_id"    $secret_db_url_id
Set-TfVar "$TF/compute/terraform.tfvars"  "secret_redis_url_id" $secret_redis_url_id
Set-TfVar "$TF/compute/terraform.tfvars"  "secret_jwt_id"       $secret_jwt_id

# ==============================================================================
# 3. IDENTITY
# ==============================================================================
Invoke-TerraformApply "$TF/identity"

Write-Host "[wire] identity -> compute" -ForegroundColor Yellow
Push-Location "$TF/identity"
$sa_email = terraform output -raw sa_email
$RepoUrl = terraform output -raw repo_url
Pop-Location

Set-TfVar "$TF/compute/terraform.tfvars" "sa_email" $sa_email

# ==============================================================================
# 3.5 DOCKER BUILD & PUSH
# ==============================================================================
Write-Host "`n[docker] Building & Pushing Images..." -ForegroundColor Cyan
$RegistryHost = ($RepoUrl -split "/")[0]
gcloud auth configure-docker $RegistryHost --quiet

$AppRoot = Split-Path $TF -Parent

# Backend
$BackendImage = "$RepoUrl/backend:latest"
Push-Location "$AppRoot/api"
docker build -t $BackendImage .
docker push $BackendImage
Pop-Location

# Frontend
$FrontendImage = "$RepoUrl/frontend:latest"
Push-Location "$AppRoot/ui"
docker build -t $FrontendImage --build-arg VITE_API_URL=/api .
docker push $FrontendImage
Pop-Location

Set-TfVar "$TF/compute/terraform.tfvars" "backend_image"  $BackendImage
Set-TfVar "$TF/compute/terraform.tfvars" "frontend_image" $FrontendImage

# ==============================================================================
# 4. COMPUTE
# ==============================================================================
Invoke-TerraformApply "$TF/compute"

Write-Host "[wire] compute -> edge" -ForegroundColor Yellow
Push-Location "$TF/compute"
$backend_service_name = terraform output -raw backend_service_name
$frontend_service_name = terraform output -raw frontend_service_name
Pop-Location

Set-TfVar "$TF/edge/terraform.tfvars" "backend_service_name"  $backend_service_name
Set-TfVar "$TF/edge/terraform.tfvars" "frontend_service_name" $frontend_service_name

# ==============================================================================
# 5. EDGE
# ==============================================================================
Invoke-TerraformApply "$TF/edge"

# ==============================================================================
# POST-DEPLOY: restore backup if one exists
# ==============================================================================
Write-Host "`n[post] Checking for SQL backup to restore..." -ForegroundColor Cyan

Push-Location "$TF/data"
$SqlInstance = terraform output -raw db_instance_name 2>$null
$DbName = terraform output -raw db_name 2>$null
Pop-Location

Push-Location "$TF/identity"
$BackupBucket = terraform output -raw bucket_name 2>$null
Pop-Location

if ($SqlInstance -and $BackupBucket) {
    $BackupFile = "gs://$BackupBucket/backup.sql"
    $fileExists = gcloud storage objects list $BackupFile --format="value(name)" 2>$null
    if ($fileExists) {
        Write-Host "[restore] Restoring $DbName from $BackupFile..." -ForegroundColor Green
        gcloud sql import sql $SqlInstance $BackupFile --database=$DbName --quiet
    }
}

Push-Location "$TF/edge"
$LbIp = terraform output -raw lb_ip 2>$null
Pop-Location

Write-Host "`nDeployment complete! LB IP: $LbIp" -ForegroundColor Green
