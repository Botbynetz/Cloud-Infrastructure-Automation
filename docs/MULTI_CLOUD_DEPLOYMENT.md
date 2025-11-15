# Multi-Cloud Deployment Guide

Complete guide for deploying infrastructure across AWS, Azure, and GCP using the cloud-agnostic Terraform module.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Provider Setup](#provider-setup)
  - [AWS Setup](#aws-setup)
  - [Azure Setup](#azure-setup)
  - [GCP Setup](#gcp-setup)
- [Deployment Patterns](#deployment-patterns)
- [Cost Comparison](#cost-comparison)
- [Migration Strategies](#migration-strategies)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

This guide demonstrates how to deploy identical infrastructure across multiple cloud providers using a unified Terraform configuration. The cloud-agnostic module abstracts provider-specific details while maintaining cloud-native best practices.

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                   Cloud-Agnostic Module                      │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Compute    │  │   Storage    │  │   Database   │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Networking  │  │  Monitoring  │  │   Security   │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
         ▼                 ▼                 ▼
    ┌────────┐        ┌────────┐       ┌────────┐
    │  AWS   │        │ Azure  │       │  GCP   │
    │        │        │        │       │        │
    │ • VPC  │        │ • VNet │       │ • VPC  │
    │ • EC2  │        │ • VM   │       │ • GCE  │
    │ • S3   │        │ • Blob │       │ • GCS  │
    │ • RDS  │        │ • SQL  │       │ • SQL  │
    └────────┘        └────────┘       └────────┘
```

## Prerequisites

### Required Tools

- **Terraform** >= 1.6.0
- **AWS CLI** (for AWS deployments)
- **Azure CLI** (for Azure deployments)
- **gcloud CLI** (for GCP deployments)
- **Git** for version control

### Cloud Accounts

You need active accounts with appropriate permissions:

- **AWS**: IAM user with AdministratorAccess or specific resource permissions
- **Azure**: Service Principal with Contributor role
- **GCP**: Service Account with Editor role

### Installation

```bash
# Install Terraform
# Windows (with Chocolatey)
choco install terraform

# macOS (with Homebrew)
brew install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify installation
terraform version
```

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/Botbynetz/Cloud-Infrastructure-Automation.git
cd Cloud-Infrastructure-Automation/cloud-infra
```

### 2. Choose Your Provider

Create a `terraform.tfvars` file:

```hcl
# For AWS deployment
cloud_provider = "aws"
project_name   = "my-app"
environment    = "production"

aws_config = {
  region             = "us-east-1"
  availability_zones = ["us-east-1a", "us-east-1b"]
}
```

### 3. Initialize and Deploy

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy infrastructure
terraform apply
```

### 4. Verify Deployment

```bash
# View outputs
terraform output

# Get infrastructure summary
terraform output infrastructure_summary
```

## Provider Setup

### AWS Setup

#### 1. Configure AWS CLI

```bash
# Configure AWS credentials
aws configure

# Verify access
aws sts get-caller-identity
```

#### 2. Create IAM User (Optional)

```bash
# Create IAM user for Terraform
aws iam create-user --user-name terraform-deployer

# Attach policies
aws iam attach-user-policy \
  --user-name terraform-deployer \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Create access key
aws iam create-access-key --user-name terraform-deployer
```

#### 3. Configure Terraform Variables

```hcl
# terraform.tfvars
cloud_provider = "aws"
project_name   = "cloud-infra"
environment    = "production"

aws_config = {
  region             = "us-east-1"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

networking_config = {
  vpc_cidr         = "10.0.0.0/16"
  app_subnet_cidr  = "10.0.1.0/24"
  data_subnet_cidr = "10.0.2.0/24"
}

compute_config = {
  enabled       = true
  instance_type = "t3.medium"
  instance_count = 2
}

database_config = {
  enabled        = true
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.small"
  storage_size   = 50
}

monitoring_config = {
  enabled            = true
  log_retention_days = 90
  enable_alerts      = true
  alert_email        = "ops@example.com"
}
```

#### 4. Deploy to AWS

```bash
terraform init
terraform plan -out=aws-plan.tfplan
terraform apply aws-plan.tfplan
```

#### 5. Verify AWS Resources

```bash
# List VPCs
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=cloud-infra"

# List S3 buckets
aws s3 ls | grep cloud-infra

# Check RDS instances
aws rds describe-db-instances --query "DBInstances[?contains(DBInstanceIdentifier, 'cloud-infra')]"
```

---

### Azure Setup

#### 1. Install Azure CLI

```bash
# Windows (with Chocolatey)
choco install azure-cli

# macOS (with Homebrew)
brew install azure-cli

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

#### 2. Login to Azure

```bash
# Login interactively
az login

# List subscriptions
az account list --output table

# Set active subscription
az account set --subscription "Your Subscription Name"
```

#### 3. Create Service Principal

```bash
# Create service principal for Terraform
az ad sp create-for-rbac --name "terraform-deployer" --role="Contributor" --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"

# Output will look like:
# {
#   "appId": "00000000-0000-0000-0000-000000000000",
#   "displayName": "terraform-deployer",
#   "password": "XXXXXXXXXXXXXXXXXXXXXXXXXXXX",
#   "tenant": "00000000-0000-0000-0000-000000000000"
# }
```

#### 4. Configure Environment Variables

```bash
# PowerShell
$env:ARM_CLIENT_ID="YOUR_APP_ID"
$env:ARM_CLIENT_SECRET="YOUR_PASSWORD"
$env:ARM_SUBSCRIPTION_ID="YOUR_SUBSCRIPTION_ID"
$env:ARM_TENANT_ID="YOUR_TENANT_ID"

# Bash
export ARM_CLIENT_ID="YOUR_APP_ID"
export ARM_CLIENT_SECRET="YOUR_PASSWORD"
export ARM_SUBSCRIPTION_ID="YOUR_SUBSCRIPTION_ID"
export ARM_TENANT_ID="YOUR_TENANT_ID"
```

#### 5. Configure Terraform Variables

```hcl
# terraform.tfvars
cloud_provider = "azure"
project_name   = "cloud-infra"
environment    = "production"

azure_config = {
  region              = "East US"
  storage_replication = "GRS"  # Geo-redundant storage
}

networking_config = {
  vpc_cidr         = "10.1.0.0/16"
  app_subnet_cidr  = "10.1.1.0/24"
  data_subnet_cidr = "10.1.2.0/24"
}

storage_config = {
  enabled           = true
  enable_versioning = true
  enable_encryption = true
}

monitoring_config = {
  enabled            = true
  log_retention_days = 90
  enable_alerts      = true
  alert_email        = "ops@example.com"
}
```

#### 6. Deploy to Azure

```bash
terraform init
terraform plan -out=azure-plan.tfplan
terraform apply azure-plan.tfplan
```

#### 7. Verify Azure Resources

```bash
# List resource groups
az group list --query "[?contains(name, 'cloud-infra')]" --output table

# List virtual networks
az network vnet list --query "[?contains(name, 'cloud-infra')]" --output table

# List storage accounts
az storage account list --query "[?contains(name, 'cloudinfra')]" --output table

# Check Log Analytics workspaces
az monitor log-analytics workspace list --query "[?contains(name, 'cloud-infra')]" --output table
```

---

### GCP Setup

#### 1. Install gcloud CLI

```bash
# Windows (download installer)
https://cloud.google.com/sdk/docs/install

# macOS (with Homebrew)
brew install --cask google-cloud-sdk

# Linux
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

#### 2. Initialize gcloud

```bash
# Initialize gcloud
gcloud init

# Login
gcloud auth login

# List projects
gcloud projects list

# Set active project
gcloud config set project YOUR_PROJECT_ID
```

#### 3. Enable Required APIs

```bash
# Enable Compute Engine API
gcloud services enable compute.googleapis.com

# Enable Cloud Storage API
gcloud services enable storage.googleapis.com

# Enable Cloud SQL API
gcloud services enable sqladmin.googleapis.com

# Enable Cloud KMS API
gcloud services enable cloudkms.googleapis.com

# Enable Secret Manager API
gcloud services enable secretmanager.googleapis.com

# Enable Artifact Registry API
gcloud services enable artifactregistry.googleapis.com

# Enable Cloud Monitoring API
gcloud services enable monitoring.googleapis.com

# Enable Cloud Logging API
gcloud services enable logging.googleapis.com
```

#### 4. Create Service Account

```bash
# Create service account
gcloud iam service-accounts create terraform-deployer \
  --display-name="Terraform Deployment Account"

# Grant Editor role
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:terraform-deployer@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/editor"

# Create and download key
gcloud iam service-accounts keys create terraform-key.json \
  --iam-account=terraform-deployer@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

#### 5. Configure Authentication

```bash
# Set credentials environment variable
# PowerShell
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\terraform-key.json"

# Bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/terraform-key.json"

# Verify authentication
gcloud auth application-default print-access-token
```

#### 6. Configure Terraform Variables

```hcl
# terraform.tfvars
cloud_provider = "gcp"
project_name   = "cloud-infra"
environment    = "production"

gcp_config = {
  project_id  = "your-gcp-project-id"
  region      = "us-central1"
  zone        = "us-central1-a"
  enable_cmek = true  # Customer-managed encryption keys
}

networking_config = {
  vpc_cidr         = "10.2.0.0/16"
  app_subnet_cidr  = "10.2.1.0/24"
  data_subnet_cidr = "10.2.2.0/24"
}

database_config = {
  enabled        = true
  engine         = "postgres"
  engine_version = "15"
  instance_class = "db-f1-micro"
  storage_size   = 10
}

container_config = {
  enabled                   = true
  enable_vulnerability_scan = true
}

monitoring_config = {
  enabled            = true
  log_retention_days = 30
  enable_alerts      = true
  alert_email        = "ops@example.com"
}
```

#### 7. Deploy to GCP

```bash
terraform init
terraform plan -out=gcp-plan.tfplan
terraform apply gcp-plan.tfplan
```

#### 8. Verify GCP Resources

```bash
# List VPC networks
gcloud compute networks list --filter="name~cloud-infra"

# List subnets
gcloud compute networks subnets list --filter="name~cloud-infra"

# List storage buckets
gcloud storage buckets list --filter="name~cloud-infra"

# Check Cloud SQL instances
gcloud sql instances list --filter="name~cloud-infra"

# List Artifact Registry repositories
gcloud artifacts repositories list --filter="name~cloud-infra"
```

---

## Deployment Patterns

### Pattern 1: Single Provider

Deploy all infrastructure to one cloud provider.

```hcl
module "infrastructure" {
  source = "./modules/cloud-agnostic"
  
  cloud_provider = "aws"  # Single provider
  project_name   = "my-app"
  environment    = "production"
  
  # Full configuration
}
```

**Use Cases:**
- Cost optimization
- Team expertise with specific provider
- Regulatory requirements

---

### Pattern 2: Primary + Disaster Recovery

Primary infrastructure in one cloud, DR in another.

```hcl
# Primary in AWS
module "primary" {
  source = "./modules/cloud-agnostic"
  
  cloud_provider = "aws"
  project_name   = "my-app"
  environment    = "production"
  
  ha_config = {
    enable_multi_az     = true
    enable_auto_scaling = true
    min_instances       = 2
    max_instances       = 10
  }
}

# DR in Azure
module "disaster_recovery" {
  source = "./modules/cloud-agnostic"
  
  cloud_provider = "azure"
  project_name   = "my-app"
  environment    = "dr"
  
  compute_config = {
    enabled       = false  # Keep cold until needed
    instance_type = "Standard_B2s"
    instance_count = 0
  }
  
  storage_config = {
    enabled = true  # Replicate data
  }
}
```

**Use Cases:**
- Business continuity
- Compliance requirements
- Risk mitigation

---

### Pattern 3: Geographic Distribution

Deploy to multiple providers based on geographic regions.

```hcl
# North America - AWS
module "na_region" {
  source = "./modules/cloud-agnostic"
  
  cloud_provider = "aws"
  project_name   = "my-app"
  environment    = "production"
  
  aws_config = {
    region = "us-east-1"
  }
  
  common_tags = {
    Region = "North-America"
  }
}

# Europe - Azure
module "eu_region" {
  source = "./modules/cloud-agnostic"
  
  cloud_provider = "azure"
  project_name   = "my-app"
  environment    = "production"
  
  azure_config = {
    region = "West Europe"
  }
  
  common_tags = {
    Region = "Europe"
  }
}

# Asia - GCP
module "asia_region" {
  source = "./modules/cloud-agnostic"
  
  cloud_provider = "gcp"
  project_name   = "my-app"
  environment    = "production"
  
  gcp_config = {
    project_id = "my-app-asia"
    region     = "asia-east1"
  }
  
  common_labels = {
    region = "asia"
  }
}
```

**Use Cases:**
- Low latency for global users
- Data residency requirements
- Regional compliance

---

### Pattern 4: Cost Optimization

Use the most cost-effective provider for each workload.

```hcl
# Compute-heavy workload - GCP (lower compute costs)
module "compute_workload" {
  source = "./modules/cloud-agnostic"
  
  cloud_provider = "gcp"
  
  compute_config = {
    enabled       = true
    instance_type = "e2-medium"
    instance_count = 10
  }
  
  database_config = {
    enabled = false
  }
}

# Storage-heavy workload - AWS (S3 pricing)
module "storage_workload" {
  source = "./modules/cloud-agnostic"
  
  cloud_provider = "aws"
  
  compute_config = {
    enabled = false
  }
  
  storage_config = {
    enabled = true
  }
}

# Database workload - Azure (flexible pricing)
module "database_workload" {
  source = "./modules/cloud-agnostic"
  
  cloud_provider = "azure"
  
  compute_config = {
    enabled = false
  }
  
  database_config = {
    enabled        = true
    instance_class = "GP_Gen5_2"
  }
}
```

**Use Cases:**
- Budget constraints
- Workload-specific optimization
- Avoiding vendor lock-in

---

## Cost Comparison

### Monthly Cost Estimate (Basic Deployment)

| Resource Type | AWS | Azure | GCP | Notes |
|---------------|-----|-------|-----|-------|
| **Compute** | | | | |
| 1x Small Instance | $7.50 | $8.03 | $6.50 | t3.micro / B1s / e2-micro |
| 1x Medium Instance | $30.37 | $29.93 | $24.27 | t3.medium / B2ms / e2-medium |
| 1x Large Instance | $60.74 | $58.40 | $48.54 | t3.large / B4ms / e2-standard-2 |
| **Storage** | | | | |
| 100 GB Object Storage | $2.30 | $1.84 | $2.00 | S3 Standard / Blob Hot / Standard |
| 1 TB Object Storage | $23.00 | $18.40 | $20.00 | |
| **Database** | | | | |
| PostgreSQL Small | $12.41 | $14.61 | $9.37 | db.t3.micro / B_Gen5_1 / db-f1-micro |
| PostgreSQL Medium | $49.64 | $58.40 | $37.54 | db.t3.small / B_Gen5_2 / db-g1-small |
| **Networking** | | | | |
| Data Transfer Out (1TB) | $90.00 | $87.00 | $120.00 | First 1TB |
| Load Balancer | $16.20 | $18.25 | $18.26 | ALB / Standard / Standard |
| **Monitoring** | | | | |
| Basic Monitoring | $5.00 | $5.00 | Free | CloudWatch / Monitor / Ops |
| **Total (Basic)** | **$25-30** | **$28-33** | **$16-22** | Small instance + storage + monitoring |
| **Total (Medium)** | **$90-100** | **$95-105** | **$75-85** | Medium instance + 100GB + DB |

### Cost Optimization Tips

#### AWS Cost Optimization

```hcl
# Use Savings Plans
compute_config = {
  instance_type = "t3.medium"  # Burstable instances
}

# Enable S3 lifecycle policies
storage_config = {
  enabled = true
  # Add lifecycle rules in provider config
}

# Use Reserved Instances for databases
database_config = {
  enabled        = true
  instance_class = "db.t3.micro"  # Consider Reserved Instance
}
```

#### Azure Cost Optimization

```hcl
# Use B-series burstable VMs
azure_config = {
  region = "East US"  # Cheaper than West US
}

# Use locally-redundant storage
azure_config = {
  storage_replication = "LRS"  # Instead of GRS
}

# Enable autoscaling
ha_config = {
  enable_auto_scaling = true
  min_instances       = 1
  max_instances       = 5
}
```

#### GCP Cost Optimization

```hcl
# Use E2 instances (cost-optimized)
compute_config = {
  instance_type = "e2-medium"
}

# Enable committed use discounts
gcp_config = {
  region = "us-central1"  # Cheapest region
}

# Use Cloud Storage lifecycle management
storage_config = {
  enabled = true
  # Nearline after 90 days, Archive after 365 days
}
```

### Total Cost of Ownership (TCO) Calculator

Use these scripts to calculate your TCO:

```bash
# See scripts/cost-calculator.sh
./scripts/cost-calculator.sh --provider aws --environment production
./scripts/cost-calculator.sh --provider azure --environment production
./scripts/cost-calculator.sh --provider gcp --environment production
```

---

## Migration Strategies

### Strategy 1: Lift and Shift

Migrate existing infrastructure to cloud with minimal changes.

#### Steps:

1. **Inventory Current Infrastructure**
   ```bash
   # Document all resources
   terraform import aws_vpc.main vpc-12345678
   terraform import aws_subnet.app subnet-12345678
   ```

2. **Deploy Parallel Infrastructure**
   ```hcl
   module "new_infrastructure" {
     source = "./modules/cloud-agnostic"
     cloud_provider = "azure"  # New provider
   }
   ```

3. **Migrate Data**
   ```bash
   # AWS S3 to Azure Blob
   azcopy copy "https://mybucket.s3.amazonaws.com/*" "https://mystorageaccount.blob.core.windows.net/mycontainer" --recursive
   
   # AWS RDS to Azure SQL
   pg_dump -h aws-rds-endpoint.rds.amazonaws.com > backup.sql
   psql -h azure-postgres.postgres.database.azure.com < backup.sql
   ```

4. **Update DNS/Traffic Routing**
   ```hcl
   # Route 53 to Azure Traffic Manager
   resource "azurerm_traffic_manager_profile" "main" {
     # Configuration
   }
   ```

5. **Decommission Old Infrastructure**
   ```bash
   terraform destroy -target=module.old_infrastructure
   ```

---

### Strategy 2: Strangler Fig Pattern

Gradually migrate components while maintaining service.

#### Steps:

1. **Deploy New Infrastructure**
   ```hcl
   module "new_app_tier" {
     source = "./modules/cloud-agnostic"
     cloud_provider = "gcp"
     
     compute_config = {
       enabled = true
     }
     
     database_config = {
       enabled = false  # Still using old database
     }
   }
   ```

2. **Route Percentage of Traffic**
   ```hcl
   # Use load balancer weights
   resource "aws_lb_target_group" "new" {
     # New GCP endpoints
   }
   
   resource "aws_lb_listener_rule" "split" {
     # 10% to new infrastructure
     weight = 10
   }
   ```

3. **Increase Traffic Gradually**
   ```hcl
   # Week 1: 10%
   # Week 2: 25%
   # Week 3: 50%
   # Week 4: 100%
   ```

4. **Migrate Database Last**
   ```hcl
   # After all traffic is on new infrastructure
   database_config = {
     enabled = true
   }
   ```

---

### Strategy 3: Blue-Green Deployment

Deploy complete new environment, then switch.

#### Steps:

1. **Deploy Green Environment**
   ```hcl
   module "green_environment" {
     source = "./modules/cloud-agnostic"
     cloud_provider = "azure"
     environment    = "green"
   }
   ```

2. **Sync Data to Green**
   ```bash
   # Continuous replication
   aws dms create-replication-task \
     --source aws-rds \
     --target azure-postgres
   ```

3. **Test Green Environment**
   ```bash
   # Run integration tests
   terraform test
   ```

4. **Switch Traffic**
   ```hcl
   # Update DNS
   resource "aws_route53_record" "app" {
     records = [module.green_environment.load_balancer_ip]
   }
   ```

5. **Keep Blue for Rollback**
   ```bash
   # Wait 7 days before destroying
   terraform destroy -target=module.blue_environment
   ```

---

## Best Practices

### 1. Infrastructure as Code

✅ **DO:**
- Version control all Terraform code
- Use remote state with locking
- Implement CI/CD for infrastructure
- Use workspaces for environments

❌ **DON'T:**
- Manual changes in cloud console
- Commit secrets to Git
- Share state files via email
- Mix manual and Terraform resources

### 2. Security

✅ **DO:**
- Enable encryption at rest and in transit
- Use secret managers for credentials
- Implement least-privilege IAM
- Enable audit logging
- Use private subnets for data tier

❌ **DON'T:**
- Hardcode credentials
- Use overly permissive security groups
- Disable encryption for cost savings
- Skip security updates

### 3. Cost Management

✅ **DO:**
- Use auto-scaling
- Enable cost alerts
- Right-size instances
- Use spot/preemptible instances
- Implement lifecycle policies

❌ **DON'T:**
- Leave unused resources running
- Over-provision resources
- Ignore cost anomalies
- Skip resource tagging

### 4. High Availability

✅ **DO:**
- Deploy across multiple AZs/regions
- Implement health checks
- Use managed services
- Set up automated backups
- Test disaster recovery

❌ **DON'T:**
- Single point of failure
- Skip backup testing
- Ignore monitoring alerts
- Deploy without redundancy

---

## Troubleshooting

### Common Issues

#### Issue 1: Authentication Failed

**AWS:**
```bash
# Check credentials
aws sts get-caller-identity

# Verify region
aws configure get region
```

**Azure:**
```bash
# Re-login
az login

# Check subscription
az account show
```

**GCP:**
```bash
# Check application default credentials
gcloud auth application-default print-access-token

# Verify project
gcloud config get-value project
```

#### Issue 2: Quota Exceeded

**AWS:**
```bash
# Check service quotas
aws service-quotas list-service-quotas --service-code ec2

# Request quota increase
aws service-quotas request-service-quota-increase \
  --service-code ec2 \
  --quota-code L-1216C47A \
  --desired-value 100
```

**Azure:**
```bash
# Check quotas
az vm list-usage --location "East US"

# Request increase via portal
```

**GCP:**
```bash
# Check quotas
gcloud compute project-info describe --project YOUR_PROJECT_ID

# Request increase
# https://console.cloud.google.com/iam-admin/quotas
```

#### Issue 3: Resource Already Exists

```bash
# Import existing resource
terraform import module.infrastructure.aws_vpc.main vpc-12345678

# Or destroy and recreate
terraform destroy -target=module.infrastructure.aws_vpc.main
terraform apply
```

#### Issue 4: State Lock Error

```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID

# Better: Use remote state with proper locking
```

---

## Additional Resources

### Official Documentation

- [AWS Terraform Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Azure Terraform Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GCP Terraform Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

### Cost Calculators

- [AWS Pricing Calculator](https://calculator.aws/)
- [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/)
- [GCP Pricing Calculator](https://cloud.google.com/products/calculator)

### Community

- [Terraform Community Forum](https://discuss.hashicorp.com/c/terraform-core/)
- [AWS Reddit](https://reddit.com/r/aws)
- [Azure Reddit](https://reddit.com/r/AZURE)
- [GCP Reddit](https://reddit.com/r/googlecloud)

---

## Support

For issues or questions:
1. Check [Troubleshooting](#troubleshooting) section
2. Review [GitHub Issues](https://github.com/Botbynetz/Cloud-Infrastructure-Automation/issues)
3. Open a new issue with details

---

**Last Updated:** December 2024
**Version:** 1.4.0
