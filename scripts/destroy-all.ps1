# PowerShell script to destroy all environments
# Use with extreme caution!

$ErrorActionPreference = "Stop"

$ENVIRONMENTS = @("dev", "staging", "prod")
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$TERRAFORM_DIR = Join-Path $SCRIPT_DIR "..\terraform"

Write-Host "==========================================" -ForegroundColor Red
Write-Host "⚠️  DESTROY ALL ENVIRONMENTS" -ForegroundColor Red
Write-Host "==========================================" -ForegroundColor Red
Write-Host ""
Write-Host "This script will destroy infrastructure in:"
foreach ($env in $ENVIRONMENTS) {
    Write-Host "  - $env"
}
Write-Host ""

$confirmation = Read-Host "Are you absolutely sure you want to continue? (type 'yes' to confirm)"

if ($confirmation -ne "yes") {
    Write-Host "Aborted."
    exit 1
}

Write-Host ""
$finalConfirmation = Read-Host "Type 'DESTROY' to proceed"

if ($finalConfirmation -ne "DESTROY") {
    Write-Host "Aborted."
    exit 1
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Yellow
Write-Host "Starting destruction process..." -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Yellow

Set-Location $TERRAFORM_DIR

foreach ($env in $ENVIRONMENTS) {
    Write-Host ""
    Write-Host "==================== $env ====================" -ForegroundColor Cyan
    Write-Host "Destroying $env environment..." -ForegroundColor Cyan
    
    if (-not (Test-Path "env\$env.tfvars")) {
        Write-Host "⚠️  Warning: env\$env.tfvars not found, skipping..." -ForegroundColor Yellow
        continue
    }
    
    # Initialize Terraform
    Write-Host "Initializing Terraform for $env..."
    try {
        terraform init -backend-config="backend\$env.conf" -reconfigure
    }
    catch {
        Write-Host "❌ Failed to initialize Terraform for $env" -ForegroundColor Red
        continue
    }
    
    # Show what will be destroyed
    Write-Host "Planning destruction for $env..."
    try {
        terraform plan -destroy -var-file="env\$env.tfvars"
    }
    catch {
        Write-Host "❌ Failed to plan destroy for $env" -ForegroundColor Red
        continue
    }
    
    # Destroy
    Write-Host "Destroying $env infrastructure..."
    try {
        terraform destroy -var-file="env\$env.tfvars" -auto-approve
    }
    catch {
        Write-Host "❌ Failed to destroy $env" -ForegroundColor Red
        continue
    }
    
    Write-Host "✅ $env environment destroyed" -ForegroundColor Green
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Destruction process completed!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Note: This script did not delete:"
Write-Host "  - S3 bucket for Terraform state"
Write-Host "  - DynamoDB table for state locking"
Write-Host ""
Write-Host "To remove backend resources, run:"
Write-Host "  aws s3 rb s3://cloud-infra-terraform-state --force"
Write-Host "  aws dynamodb delete-table --table-name cloud-infra-terraform-locks --region ap-southeast-1"
Write-Host ""
