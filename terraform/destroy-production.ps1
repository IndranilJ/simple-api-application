# Synapse Production Destruction Script (Reverse Waterfall)
# ---------------------------------------------------------------------------------------------------------------------
# This script tears down the infrastructure in the correct order to avoid dependency locks.
# ---------------------------------------------------------------------------------------------------------------------

$ProjectID = "project-3a5ecdcf-cc00-4004-a9d"
$BucketName = "synapse-tf-state-project-3a5ecdcf"

Write-Host "⚠️  WARNING: You are about to DESTROY the Synapse Production Infrastructure!" -ForegroundColor Red
Write-Host "This will permanently delete all data in Cloud SQL and Redis." -ForegroundColor Yellow
$confirm = Read-Host "Type 'DESTROY' to confirm"
if ($confirm -ne "DESTROY") {
    Write-Host "Aborted."
    exit
}

Write-Host "🚀 Starting Teardown..." -ForegroundColor Cyan

# Define the phases in reverse order
$Phases = @("04-edge", "03-compute", "02-persistence", "01-foundation")

foreach ($Phase in $Phases) {
    Write-Host "`n🔥 Destroying Phase: $Phase..." -ForegroundColor Yellow
    Push-Location "terraform/$Phase"
    
    terraform init -reconfigure
    
    if ($Phase -eq "02-persistence") {
        # --- NEW: Automated Backup ---
        Write-Host "`n📦 Creating database backup before destruction..." -ForegroundColor Cyan
        try {
            # Attempt to get instance info. If it's already gone, catch the error.
            $backupBucket = terraform output -raw backup_bucket_name
            $sqlInstance = terraform output -raw db_instance_name
            $dbName = terraform output -raw db_name
            
            if ($sqlInstance) {
                $backupFile = "gs://$backupBucket/backup.sql"
                Write-Host "Exporting $dbName from $sqlInstance to $backupFile..."
                gcloud sql export sql $sqlInstance $backupFile --database=$dbName --quiet
                Write-Host "✅ Backup complete." -ForegroundColor Green
            }
        }
        catch {
            Write-Host "ℹ️ Database instance not found or already deleted. Skipping backup." -ForegroundColor Gray
        }
        # -----------------------------

        Write-Host "Disabling deletion protection for Cloud SQL..." -ForegroundColor Gray
        terraform destroy -var="enable_deletion_protection=false" -auto-approve
    }
    else {
        terraform destroy -auto-approve
    }
    
    Pop-Location

    if ($Phase -eq "02-persistence") {
        Write-Host "⏳ Waiting 60 seconds for GCP networking locks to release before cleaning up Foundation..." -ForegroundColor Gray
        Start-Sleep -Seconds 60
    }
}

Write-Host "`n✅ Infrastructure Successfully Teardown!" -ForegroundColor Green
