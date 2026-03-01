# ==============================================================================
# 🧩 Configuration
# ==============================================================================
$ProjectId = "project-3a5ecdcf-cc00-4004-a9d"
$TF = "$PSScriptRoot"

Write-Host "`nWARNING: This will DESTROY the Synapse Production Infrastructure!" -ForegroundColor Red
Write-Host "Project: $ProjectId" -ForegroundColor Yellow
$confirm = Read-Host "Type 'DESTROY' to confirm"
if ($confirm -ne "DESTROY") { Write-Host "Aborted."; exit }

$CredFile = "$PSScriptRoot/gcpcred.json"
if (Test-Path $CredFile) { $env:GOOGLE_APPLICATION_CREDENTIALS = $CredFile }

# Helper: update a key=value line in a terraform.tfvars file
function Set-TfVar {
    param([string]$File, [string]$Key, [string]$Value)
    if (-not (Test-Path $File)) { throw "TfVars file not found: $File" }
    $content = Get-Content $File
    $content = $content -replace "^$Key\s*=.*", "$Key = `"$Value`""
    Set-Content $File $content
    Write-Host "  [set] $Key -> $(Split-Path $File -Leaf)" -ForegroundColor Gray
}

# Helper: init + destroy a single domain
function Invoke-TerraformDestroy {
    param([string]$Dir, [string]$ExtraArgs = "")
    Write-Host "`n----- Destroying: $Dir -----" -ForegroundColor Red
    Push-Location $Dir
    terraform init -reconfigure
    if ($LASTEXITCODE -ne 0) { Pop-Location; exit 1 }
    
    $cmd = "terraform destroy -auto-approve $ExtraArgs"
    Invoke-Expression $cmd
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n[ERROR] terraform destroy failed" -ForegroundColor White -BackgroundColor Red
        Pop-Location
        exit 1
    }
    Pop-Location
}

# -- Pre-destroy backup --------------------------------------------------------
Write-Host "`n[BACKUP] Taking SQL backup before destroy..." -ForegroundColor Cyan
try {
    Push-Location "$TF/data"
    terraform init -reconfigure > $null
    $SqlInstance = terraform output -raw db_instance_name 2>$null
    $DbName = terraform output -raw db_name 2>$null
    Pop-Location

    Push-Location "$TF/identity"
    terraform init -reconfigure > $null
    $BackupBucket = terraform output -raw bucket_name 2>$null
    Pop-Location

    if ($SqlInstance -and $BackupBucket) {
        Write-Host "   Exporting $DbName -> gs://$BackupBucket/backup.sql"
        gcloud sql export sql $SqlInstance "gs://$BackupBucket/backup.sql" --database=$DbName --quiet
        
        if (!(Test-Path "$PSScriptRoot/backups")) { New-Item -ItemType Directory -Path "$PSScriptRoot/backups" }
        gcloud storage cp "gs://$BackupBucket/backup.sql" "$PSScriptRoot/backups/backup.sql"
        Write-Host "[SUCCESS] Local backup saved to terraform/backups/backup.sql" -ForegroundColor Green
    }
}
catch {
    Write-Host "[INFO] Could not back up database. Proceeding." -ForegroundColor Gray
    Pop-Location # Ensure we pop if try fails inside a Push
}

# -- Disable SQL deletion protection first -------------------------------------
Write-Host "`n[UNLOCK] Disabling deletion protection on SQL..." -ForegroundColor Yellow
Set-TfVar "$TF/data/terraform.tfvars" "deletion_protection" "false"
Push-Location "$TF/data"
terraform init -reconfigure > $null
terraform apply -target=module.cloud_sql -auto-approve
Pop-Location

# -- Destroy in reverse order --------------------------------------------------
Invoke-TerraformDestroy "$TF/edge"
Invoke-TerraformDestroy "$TF/compute"
Invoke-TerraformDestroy "$TF/data"
Invoke-TerraformDestroy "$TF/identity"

Write-Host "`n[WAIT] Waiting 120s for GCP to purge peering connections..." -ForegroundColor Yellow
Start-Sleep -Seconds 120

Invoke-TerraformDestroy "$TF/networking"

Write-Host "`n[SUCCESS] All resources destroyed." -ForegroundColor Green
