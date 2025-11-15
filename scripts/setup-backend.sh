#!/bin/bash
# Setup Terraform backend infrastructure (S3 + DynamoDB)

set -e

BUCKET_NAME="cloud-infra-terraform-state"
DYNAMODB_TABLE="cloud-infra-terraform-locks"
REGION="ap-southeast-1"

echo "=========================================="
echo "Setting up Terraform Backend Infrastructure"
echo "=========================================="

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed"
    exit 1
fi

# Check AWS credentials
echo "Checking AWS credentials..."
aws sts get-caller-identity > /dev/null || {
    echo "Error: AWS credentials not configured"
    exit 1
}

# Create S3 bucket for Terraform state
echo "Creating S3 bucket: $BUCKET_NAME"
if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$REGION" \
        --create-bucket-configuration LocationConstraint="$REGION"
    
    echo "Enabling versioning on S3 bucket..."
    aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled
    
    echo "Enabling encryption on S3 bucket..."
    aws s3api put-bucket-encryption \
        --bucket "$BUCKET_NAME" \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }'
    
    echo "Blocking public access to S3 bucket..."
    aws s3api put-public-access-block \
        --bucket "$BUCKET_NAME" \
        --public-access-block-configuration \
            "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    
    echo "Adding lifecycle policy to S3 bucket..."
    aws s3api put-bucket-lifecycle-configuration \
        --bucket "$BUCKET_NAME" \
        --lifecycle-configuration '{
            "Rules": [{
                "Id": "DeleteOldVersions",
                "Status": "Enabled",
                "NoncurrentVersionExpiration": {
                    "NoncurrentDays": 90
                }
            }]
        }'
    
    echo "✅ S3 bucket created successfully"
else
    echo "✅ S3 bucket already exists"
fi

# Create DynamoDB table for state locking
echo "Creating DynamoDB table: $DYNAMODB_TABLE"
if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$REGION" 2>&1 | grep -q 'ResourceNotFoundException'; then
    aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$REGION" \
        --tags Key=Project,Value=cloud-infra Key=ManagedBy,Value=Script
    
    echo "Waiting for DynamoDB table to be active..."
    aws dynamodb wait table-exists \
        --table-name "$DYNAMODB_TABLE" \
        --region "$REGION"
    
    echo "✅ DynamoDB table created successfully"
else
    echo "✅ DynamoDB table already exists"
fi

echo ""
echo "=========================================="
echo "Backend Infrastructure Setup Complete!"
echo "=========================================="
echo "S3 Bucket: $BUCKET_NAME"
echo "DynamoDB Table: $DYNAMODB_TABLE"
echo "Region: $REGION"
echo ""
echo "To use this backend, run:"
echo "  cd terraform"
echo "  terraform init -backend-config=backend/dev.conf"
echo "=========================================="
