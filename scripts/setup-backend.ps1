#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Setup Terraform backend (S3 + DynamoDB) for state management
.DESCRIPTION
    This script creates S3 bucket and DynamoDB table for Terraform remote state
    with versioning, encryption, and locking support.
.EXAMPLE
    .\setup-backend.ps1
#>

# Exit on any error
$ErrorActionPreference = "Stop"

# Color output functions
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Success { Write-ColorOutput $args[0] "Green" }
function Write-Info { Write-ColorOutput $args[0] "Cyan" }
function Write-Warning { Write-ColorOutput $args[0] "Yellow" }
function Write-Error { Write-ColorOutput $args[0] "Red" }

# Header
Write-Host ""
Write-Info "=========================================="
Write-Info "  Terraform Backend Setup (S3 + DynamoDB)"
Write-Info "=========================================="
Write-Host ""

# Check AWS CLI installed
Write-Info "Checking AWS CLI installation..."
try {
    $awsVersion = aws --version 2>&1
    Write-Success "✓ AWS CLI found: $awsVersion"
} catch {
    Write-Error "✗ AWS CLI not found. Please install it first:"
    Write-Error "  https://aws.amazon.com/cli/"
    exit 1
}

# Check AWS credentials
Write-Info "Checking AWS credentials..."
try {
    $callerIdentity = aws sts get-caller-identity --output json | ConvertFrom-Json
    Write-Success "✓ AWS credentials configured"
    Write-Info "  Account ID: $($callerIdentity.Account)"
    Write-Info "  User ARN: $($callerIdentity.Arn)"
} catch {
    Write-Error "✗ AWS credentials not configured. Run:"
    Write-Error "  aws configure"
    exit 1
}

# Get AWS account ID
Write-Info "Getting AWS Account ID..."
$ACCOUNT_ID = $callerIdentity.Account
Write-Success "✓ Account ID: $ACCOUNT_ID"

# Configuration
$REGION = "ap-southeast-1"
$BUCKET_NAME = "cloud-infra-terraform-state-$ACCOUNT_ID"
$TABLE_NAME = "cloud-infra-lock"

Write-Host ""
Write-Info "Configuration:"
Write-Info "  Region: $REGION"
Write-Info "  Bucket: $BUCKET_NAME"
Write-Info "  Table:  $TABLE_NAME"
Write-Host ""

# Create S3 bucket
Write-Info "Creating S3 bucket for Terraform state..."
try {
    # Check if bucket exists
    $bucketExists = $false
    try {
        aws s3api head-bucket --bucket $BUCKET_NAME --region $REGION 2>$null
        $bucketExists = $true
        Write-Warning "⚠ Bucket already exists: $BUCKET_NAME"
    } catch {
        # Bucket doesn't exist, create it
    }

    if (-not $bucketExists) {
        # Create bucket with location constraint
        aws s3api create-bucket `
            --bucket $BUCKET_NAME `
            --region $REGION `
            --create-bucket-configuration LocationConstraint=$REGION `
            --output json | Out-Null

        Write-Success "✓ S3 bucket created: $BUCKET_NAME"
    }

    # Enable versioning
    Write-Info "Enabling versioning..."
    aws s3api put-bucket-versioning `
        --bucket $BUCKET_NAME `
        --versioning-configuration Status=Enabled `
        --region $REGION
    Write-Success "✓ Versioning enabled"

    # Enable encryption
    Write-Info "Enabling encryption..."
    aws s3api put-bucket-encryption `
        --bucket $BUCKET_NAME `
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                },
                "BucketKeyEnabled": true
            }]
        }' `
        --region $REGION
    Write-Success "✓ Encryption enabled (AES-256)"

    # Block public access
    Write-Info "Blocking public access..."
    aws s3api put-public-access-block `
        --bucket $BUCKET_NAME `
        --public-access-block-configuration '{
            "BlockPublicAcls": true,
            "IgnorePublicAcls": true,
            "BlockPublicPolicy": true,
            "RestrictPublicBuckets": true
        }' `
        --region $REGION
    Write-Success "✓ Public access blocked"

} catch {
    Write-Error "✗ Failed to create S3 bucket: $_"
    exit 1
}

# Create DynamoDB table
Write-Host ""
Write-Info "Creating DynamoDB table for state locking..."
try {
    # Check if table exists
    $tableExists = $false
    try {
        aws dynamodb describe-table `
            --table-name $TABLE_NAME `
            --region $REGION `
            --output json | Out-Null
        $tableExists = $true
        Write-Warning "⚠ Table already exists: $TABLE_NAME"
    } catch {
        # Table doesn't exist, create it
    }

    if (-not $tableExists) {
        aws dynamodb create-table `
            --table-name $TABLE_NAME `
            --attribute-definitions AttributeName=LockID,AttributeType=S `
            --key-schema AttributeName=LockID,KeyType=HASH `
            --billing-mode PAY_PER_REQUEST `
            --region $REGION `
            --output json | Out-Null

        Write-Success "✓ DynamoDB table created: $TABLE_NAME"

        # Wait for table to be active
        Write-Info "Waiting for table to be active..."
        aws dynamodb wait table-exists `
            --table-name $TABLE_NAME `
            --region $REGION
        Write-Success "✓ Table is active"
    }

} catch {
    Write-Error "✗ Failed to create DynamoDB table: $_"
    exit 1
}

# Summary
Write-Host ""
Write-Success "=========================================="
Write-Success "  Backend Setup Complete! ✓"
Write-Success "=========================================="
Write-Host ""
Write-Info "Backend configuration created:"
Write-Host ""
Write-Host "  Region:       $REGION" -ForegroundColor White
Write-Host "  S3 Bucket:    $BUCKET_NAME" -ForegroundColor White
Write-Host "  DynamoDB:     $TABLE_NAME" -ForegroundColor White
Write-Host ""
Write-Info "Features enabled:"
Write-Host "  ✓ S3 versioning (can recover previous states)" -ForegroundColor Green
Write-Host "  ✓ S3 encryption (AES-256)" -ForegroundColor Green
Write-Host "  ✓ Public access blocked" -ForegroundColor Green
Write-Host "  ✓ State locking (prevents concurrent modifications)" -ForegroundColor Green
Write-Host ""
Write-Warning "Next steps:"
Write-Host ""
Write-Host "1. Initialize Terraform with backend:" -ForegroundColor Yellow
Write-Host "   cd terraform" -ForegroundColor White
Write-Host "   terraform init -backend-config=`"backend/dev.conf`"" -ForegroundColor White
Write-Host ""
Write-Host "2. Verify backend configuration:" -ForegroundColor Yellow
Write-Host "   terraform workspace list" -ForegroundColor White
Write-Host ""
Write-Host "3. Apply infrastructure:" -ForegroundColor Yellow
Write-Host "   terraform plan -var-file=`"env/dev.tfvars`"" -ForegroundColor White
Write-Host "   terraform apply -var-file=`"env/dev.tfvars`"" -ForegroundColor White
Write-Host ""
Write-Info "Backend config files:"
Write-Host "  - terraform/backend/dev.conf" -ForegroundColor White
Write-Host "  - terraform/backend/staging.conf" -ForegroundColor White
Write-Host "  - terraform/backend/prod.conf" -ForegroundColor White
Write-Host ""
Write-Success "Happy Terraforming! 🚀"
Write-Host ""
