# Multi-Environment Deployment Guide

## 🏗️ Architecture Overview

This Terraform configuration supports **multi-environment** and **multi-cloud** deployments:

- **Environments**: `dev`, `staging`, `prod`, `dr` (Disaster Recovery)
- **Cloud Providers**: AWS, GCP, Azure (simultaneously)
- **State Management**: S3 backend with encryption, versioning, and state locking
- **FinOps**: Mandatory tagging strategy for cost tracking and governance

---

## 📋 Prerequisites

### 1. Install Required Tools
```bash
# Terraform
terraform version  # >= 1.5

# AWS CLI
aws --version

# GCP CLI (optional)
gcloud --version

# Azure CLI (optional)
az --version
```

### 2. Configure Cloud Credentials

#### AWS
```bash
# Option 1: AWS CLI credentials
aws configure

# Option 2: Environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="ap-southeast-1"

# Option 3: Assume role (recommended for production)
export AWS_ASSUME_ROLE_ARN="arn:aws:iam::ACCOUNT_ID:role/TerraformRole"
```

#### GCP (if using)
```bash
# Option 1: Application Default Credentials
gcloud auth application-default login

# Option 2: Service Account Key
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
```

#### Azure (if using)
```bash
# Option 1: Azure CLI login
az login

# Option 2: Service Principal
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
```

---

## 🚀 Deployment Steps

### Step 1: Initialize Backend

Choose your environment and initialize:

```bash
# Development
terraform init -backend-config=backend/dev.conf

# Staging
terraform init -backend-config=backend/staging.conf

# Production
terraform init -backend-config=backend/prod.conf

# Disaster Recovery
terraform init -backend-config=backend/dr.conf
```

### Step 2: Validate Configuration

```bash
# Format code
terraform fmt -recursive

# Validate syntax
terraform validate

# Check for security issues (optional)
tflint
```

### Step 3: Plan Deployment

```bash
# Development
terraform plan -var-file=environments/dev.tfvars -out=dev.tfplan

# Staging
terraform plan -var-file=environments/staging.tfvars -out=staging.tfplan

# Production (review carefully!)
terraform plan -var-file=environments/prod.tfvars -out=prod.tfplan

# DR
terraform plan -var-file=environments/dr.tfvars -out=dr.tfplan
```

### Step 4: Review & Apply

```bash
# Review the plan
terraform show dev.tfplan

# Apply (requires confirmation)
terraform apply dev.tfplan

# Or apply with auto-approve (CI/CD only)
terraform apply -var-file=environments/dev.tfvars -auto-approve
```

### Step 5: Verify Deployment

```bash
# Show outputs
terraform output

# List resources
terraform state list

# Show specific resource
terraform state show aws_vpc.main
```

---

## 🏷️ FinOps Tagging Strategy

### Mandatory Tags (MUST be provided)

All resources MUST have these tags:

| Tag | Description | Example |
|-----|-------------|---------|
| `CostCenter` | Cost center code | `CC-DEV-001` |
| `BusinessUnit` | Business unit | `Engineering` |
| `Owner` | Resource owner email | `devops@univaicloud.com` |
| `Project` | Project name | `cloud-infra` |
| `Environment` | Environment | `dev`, `staging`, `prod`, `dr` |
| `DataClassification` | Data sensitivity | `public`, `internal`, `confidential`, `restricted` |
| `Compliance` | Compliance frameworks | `SOC2,ISO27001,GDPR` |
| `ManagedBy` | Management tool | `Terraform` (auto) |

### Optional Tags (Recommended)

| Tag | Description | Example |
|-----|-------------|---------|
| `ServiceLevel` | SLA tier | `bronze`, `silver`, `gold`, `platinum` |
| `BackupPolicy` | Backup frequency | `daily`, `weekly`, `none` |
| `AutoShutdown` | Enable auto-shutdown | `true`, `false` |
| `ShutdownSchedule` | Shutdown schedule | `weekdays-after-hours` |

### Tag Validation

Tags are validated during `terraform plan`. Missing mandatory tags will **block deployment**.

---

## 🔐 Security Best Practices

### 1. Backend State Security

- ✅ **Encryption**: State files encrypted with AWS KMS
- ✅ **Versioning**: State history enabled for rollback
- ✅ **Locking**: DynamoDB prevents concurrent modifications
- ✅ **Access Control**: S3 bucket is private with ACL

### 2. Secrets Management

**⚠️ NEVER commit secrets to Git!**

```bash
# Use environment variables
export TF_VAR_aws_access_key="..."
export TF_VAR_aws_secret_key="..."

# Or use HashiCorp Vault (recommended)
export VAULT_ADDR="https://vault.example.com:8200"
export VAULT_TOKEN="your-vault-token"
```

### 3. Least Privilege IAM

Each environment should have its own IAM role with minimal permissions:

```bash
# Example: Assume dev role
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/TerraformDevRole \
  --role-session-name terraform-dev
```

---

## 🔄 Environment Promotion

### Dev → Staging → Prod Workflow

```bash
# 1. Test in dev
terraform apply -var-file=environments/dev.tfvars

# 2. Promote to staging
terraform apply -var-file=environments/staging.tfvars

# 3. Deploy to production (requires approval)
terraform apply -var-file=environments/prod.tfvars

# 4. Setup DR (mirrors production)
terraform apply -var-file=environments/dr.tfvars
```

---

## 🌍 Multi-Cloud Deployment

### Deploy to Multiple Clouds Simultaneously

```hcl
# AWS resources
module "aws_infrastructure" {
  source = "./modules/aws"
  providers = {
    aws = aws
  }
}

# GCP resources
module "gcp_infrastructure" {
  source = "./modules/gcp"
  providers = {
    google = google
  }
}

# Azure resources
module "azure_infrastructure" {
  source = "./modules/azure"
  providers = {
    azurerm = azurerm
  }
}
```

---

## 🧹 Cleanup & Destroy

### Destroy Resources

```bash
# DANGER: This will delete ALL resources!
# Always review the plan first
terraform plan -destroy -var-file=environments/dev.tfvars

# Destroy (requires confirmation)
terraform destroy -var-file=environments/dev.tfvars

# Or with auto-approve (use with caution!)
terraform destroy -var-file=environments/dev.tfvars -auto-approve
```

### Selective Resource Removal

```bash
# Remove specific resource
terraform state rm aws_instance.example

# Import existing resource
terraform import aws_instance.example i-1234567890abcdef0
```

---

## 📊 Cost Tracking

### View Resource Costs

```bash
# Generate cost estimate (requires Infracost)
infracost breakdown --path . --terraform-var-file environments/prod.tfvars

# Compare cost difference
infracost diff --path . --terraform-var-file environments/prod.tfvars
```

### Query by Tags

```bash
# AWS Cost Explorer (via AWS CLI)
aws ce get-cost-and-usage \
  --time-period Start=2025-01-01,End=2025-01-31 \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --group-by Type=TAG,Key=CostCenter
```

---

## 🛠️ Troubleshooting

### Common Issues

#### 1. State Lock Error
```bash
# Force unlock (use with caution!)
terraform force-unlock LOCK_ID
```

#### 2. Backend Configuration Changed
```bash
# Re-initialize backend
terraform init -reconfigure -backend-config=backend/prod.conf
```

#### 3. Module Update
```bash
# Update all modules
terraform init -upgrade
```

#### 4. Drift Detection
```bash
# Check for configuration drift
terraform plan -var-file=environments/prod.tfvars -detailed-exitcode
```

---

## 📚 Additional Resources

- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [FinOps Foundation](https://www.finops.org/)
- [Cloud Security Alliance](https://cloudsecurityalliance.org/)

---

## 🆘 Support

For issues or questions:
- Email: devops@univaicloud.com
- Slack: #cloud-infrastructure
- Repository: https://github.com/Botbynetz/Cloud-Infrastructure-Automation
