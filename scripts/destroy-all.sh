#!/bin/bash
# Destroy all environments - Use with extreme caution!

set -e

ENVIRONMENTS=("dev" "staging" "prod")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"

echo "=========================================="
echo "⚠️  DESTROY ALL ENVIRONMENTS"
echo "=========================================="
echo ""
echo "This script will destroy infrastructure in:"
for env in "${ENVIRONMENTS[@]}"; do
    echo "  - $env"
done
echo ""
read -p "Are you absolutely sure you want to continue? (type 'yes' to confirm): " confirmation

if [ "$confirmation" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

echo ""
read -p "Type 'DESTROY' to proceed: " final_confirmation

if [ "$final_confirmation" != "DESTROY" ]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "=========================================="
echo "Starting destruction process..."
echo "=========================================="

cd "$TERRAFORM_DIR"

for env in "${ENVIRONMENTS[@]}"; do
    echo ""
    echo "==================== $env ===================="
    echo "Destroying $env environment..."
    
    if [ ! -f "env/$env.tfvars" ]; then
        echo "⚠️  Warning: env/$env.tfvars not found, skipping..."
        continue
    fi
    
    # Initialize Terraform
    echo "Initializing Terraform for $env..."
    terraform init -backend-config="backend/$env.conf" -reconfigure || {
        echo "❌ Failed to initialize Terraform for $env"
        continue
    }
    
    # Show what will be destroyed
    echo "Planning destruction for $env..."
    terraform plan -destroy -var-file="env/$env.tfvars" || {
        echo "❌ Failed to plan destroy for $env"
        continue
    }
    
    # Destroy
    echo "Destroying $env infrastructure..."
    terraform destroy -var-file="env/$env.tfvars" -auto-approve || {
        echo "❌ Failed to destroy $env"
        continue
    }
    
    echo "✅ $env environment destroyed"
done

echo ""
echo "=========================================="
echo "Destruction process completed!"
echo "=========================================="
echo ""
echo "Note: This script did not delete:"
echo "  - S3 bucket for Terraform state"
echo "  - DynamoDB table for state locking"
echo ""
echo "To remove backend resources, run:"
echo "  aws s3 rb s3://cloud-infra-terraform-state --force"
echo "  aws dynamodb delete-table --table-name cloud-infra-terraform-locks"
echo ""
