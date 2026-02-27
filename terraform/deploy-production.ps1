$ProjectID = "project-3a5ecdcf-cc00-4004-a9d"
$BucketName = "synapse-tf-state-project-3a5ecdcf"
$CredFile = "$PSScriptRoot/gcpcred.json"

Write-Host "🚀 Starting Synapse Production Deployment..." -ForegroundColor Cyan

# 0. AUTHENTICATION: Check for Service Account Key
if (Test-Path $CredFile) {
    Write-Host "🔐 Found gcpcred.json. Setting as active credentials..." -ForegroundColor Green
    $env:GOOGLE_APPLICATION_CREDENTIALS = $CredFile
}
else {
    Write-Host "ℹ️ No gcpcred.json found. Falling back to Application Default Credentials (ADC)..." -ForegroundColor Yellow
}

# 1. BOOTSTRAP: Create State Bucket
Write-Host "📦 Phase 0: Checking GCS State Bucket..." -ForegroundColor Yellow
$bucketExists = gcloud storage buckets list --filter="name:$BucketName" --format="value(name)"
if (-not $bucketExists) {
    Write-Host "Creating bucket $BucketName in $ProjectID..."
    gcloud storage buckets create gs://$BucketName --project=$ProjectID --location=asia-south1
}
else {
    Write-Host "Bucket $BucketName already exists."
}

# Define the phases in order
$Phases = @("01-foundation", "02-persistence", "03-compute", "04-edge")

foreach ($Phase in $Phases) {
    Write-Host "`n🏗️  Deploying Phase: $Phase..." -ForegroundColor Green
    Push-Location "terraform/$Phase"
    
    Write-Host "Initializing..."
    terraform init -reconfigure # Ensure it picks up bucket correctly
    
    Write-Host "Applying..."
    # We set enable_deletion_protection = true for persistence in production
    if ($Phase -eq "02-persistence") {
        terraform apply -var="enable_deletion_protection=true" -auto-approve
        
        # --- NEW: Automated Restore ---
        Write-Host "`n🔄 Checking for database backups to restore..." -ForegroundColor Cyan
        $backupBucket = terraform output -raw backup_bucket_name
        $sqlInstance = terraform output -raw db_instance_name
        $dbName = terraform output -raw db_name
        
        $backupFile = "gs://$backupBucket/backup.sql"
        Write-Host "Checking for $backupFile..."
        $exists = gcloud storage objects list $backupFile --format="value(name)"
        
        if ($exists) {
            Write-Host "📦 Backup found! Importing into $sqlInstance..." -ForegroundColor Green
            gcloud sql import sql $sqlInstance $backupFile --database=$dbName --quiet
        }
        else {
            Write-Host "ℹ️ No backup found. Starting with a clean database." -ForegroundColor Gray
        }
        # ------------------------------
    }
    else {
        terraform apply -auto-approve
    }
    
    Pop-Location
}

Write-Host "`n✅ Full Infrastructure Deployment Complete!" -ForegroundColor Green
Write-Host "Note: It may take 10-15 minutes for the Global Load Balancer propagation." -ForegroundColor Cyan
