# Cloud-Agnostic Infrastructure Module

This module provides a unified interface for deploying infrastructure across AWS, Azure, and GCP, enabling true multi-cloud deployments with a single configuration.

## Features

- **Single Configuration**: Deploy to AWS, Azure, or GCP with one set of variables
- **Provider Translation**: Automatically translates configurations between cloud providers
- **Consistent Outputs**: Unified output structure regardless of provider
- **Resource Standardization**: Common resource naming and tagging across clouds
- **Cost Tracking**: Built-in deployment tracking for cost management

## Usage

### Basic Example

```hcl
module "cloud_infrastructure" {
  source = "./modules/cloud-agnostic"
  
  cloud_provider = "aws"  # or "azure" or "gcp"
  project_name   = "my-app"
  environment    = "production"
  
  networking_config = {
    vpc_cidr         = "10.0.0.0/16"
    app_subnet_cidr  = "10.0.1.0/24"
    data_subnet_cidr = "10.0.2.0/24"
  }
  
  compute_config = {
    enabled       = true
    instance_type = "t3.micro"
    instance_count = 2
  }
  
  storage_config = {
    enabled           = true
    enable_versioning = true
    enable_encryption = true
  }
}
```

### AWS Deployment

```hcl
module "aws_infrastructure" {
  source = "./modules/cloud-agnostic"
  
  cloud_provider = "aws"
  project_name   = "cloud-infra"
  environment    = "production"
  
  aws_config = {
    region             = "us-east-1"
    availability_zones = ["us-east-1a", "us-east-1b"]
  }
  
  database_config = {
    enabled        = true
    engine         = "postgres"
    engine_version = "15"
    instance_class = "db.t3.micro"
    storage_size   = 20
  }
}
```

### Azure Deployment

```hcl
module "azure_infrastructure" {
  source = "./modules/cloud-agnostic"
  
  cloud_provider = "azure"
  project_name   = "cloud-infra"
  environment    = "production"
  
  azure_config = {
    region              = "East US"
    storage_replication = "GRS"
  }
  
  monitoring_config = {
    enabled            = true
    log_retention_days = 90
    enable_alerts      = true
    alert_email        = "ops@example.com"
  }
}
```

### GCP Deployment

```hcl
module "gcp_infrastructure" {
  source = "./modules/cloud-agnostic"
  
  cloud_provider = "gcp"
  project_name   = "cloud-infra"
  environment    = "production"
  
  gcp_config = {
    project_id  = "my-gcp-project"
    region      = "us-central1"
    zone        = "us-central1-a"
    enable_cmek = true
  }
  
  container_config = {
    enabled                   = true
    enable_vulnerability_scan = true
  }
}
```

## Configuration Variables

### Core Configuration

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `cloud_provider` | Target cloud provider (aws, azure, gcp) | string | - | Yes |
| `project_name` | Project name for resource naming | string | "cloud-infra" | No |
| `environment` | Environment (dev, staging, production) | string | - | Yes |
| `common_tags` | Tags/labels for all resources | map(string) | See defaults | No |

### Networking Configuration

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `networking_config.vpc_cidr` | VPC/VNet CIDR block | string | "10.0.0.0/16" |
| `networking_config.app_subnet_cidr` | Application subnet CIDR | string | "10.0.1.0/24" |
| `networking_config.data_subnet_cidr` | Data subnet CIDR | string | "10.0.2.0/24" |

### Compute Configuration

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `compute_config.enabled` | Enable compute instances | bool | true |
| `compute_config.instance_type` | Instance type/size | string | "t3.micro" |
| `compute_config.instance_count` | Number of instances | number | 1 |

### Storage Configuration

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `storage_config.enabled` | Enable object storage | bool | true |
| `storage_config.enable_versioning` | Enable versioning | bool | true |
| `storage_config.enable_encryption` | Enable encryption | bool | true |

### Database Configuration

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `database_config.enabled` | Enable database | bool | false |
| `database_config.engine` | Database engine | string | "postgres" |
| `database_config.engine_version` | Engine version | string | "15" |
| `database_config.instance_class` | Instance class | string | "db-t3.micro" |
| `database_config.storage_size` | Storage size (GB) | number | 20 |

### Monitoring Configuration

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `monitoring_config.enabled` | Enable monitoring | bool | true |
| `monitoring_config.log_retention_days` | Log retention period | number | 30 |
| `monitoring_config.enable_alerts` | Enable alerting | bool | true |
| `monitoring_config.alert_email` | Alert email address | string | "admin@example.com" |

## Outputs

### Core Outputs

- `cloud_provider` - Active cloud provider
- `vpc_id` - Virtual network ID
- `vpc_cidr` - Virtual network CIDR
- `storage_endpoint` - Storage service endpoint
- `database_endpoint` - Database connection endpoint (sensitive)
- `monitoring_workspace_id` - Monitoring workspace ID
- `container_registry_url` - Container registry URL

### Provider-Specific Outputs

- `aws_specific_outputs` - AWS-only outputs (VPC, S3, ECR)
- `azure_specific_outputs` - Azure-only outputs (Resource Group, VNet, Storage Account)
- `gcp_specific_outputs` - GCP-only outputs (Project, VPC, Storage Bucket)

## Instance Type Translation

The module automatically translates instance types between providers:

| AWS | Azure | GCP |
|-----|-------|-----|
| t3.micro | Standard_B1s | e2-micro |
| t3.small | Standard_B1ms | e2-small |
| t3.medium | Standard_B2s | e2-medium |
| m5.large | Standard_D2s_v3 | n2-standard-2 |
| c5.large | Standard_F2s_v2 | c2-standard-4 |

## Cost Comparison

Estimated monthly costs for basic deployment:

| Resource | AWS | Azure | GCP |
|----------|-----|-------|-----|
| Compute (1x t3.micro) | ~$7.50 | ~$8.00 | ~$6.50 |
| Storage (10GB) | ~$0.23 | ~$0.20 | ~$0.20 |
| Database (db.t3.micro) | ~$12.00 | ~$15.00 | ~$9.00 |
| Monitoring | ~$5.00 | ~$5.00 | Free tier |
| **Total** | **~$25** | **~$28** | **~$16** |

## Multi-Cloud Deployment Strategy

### Scenario 1: Primary AWS with Azure Backup

```hcl
# Primary infrastructure in AWS
module "aws_primary" {
  source         = "./modules/cloud-agnostic"
  cloud_provider = "aws"
  environment    = "production"
  # ... configuration
}

# Backup infrastructure in Azure
module "azure_backup" {
  source         = "./modules/cloud-agnostic"
  cloud_provider = "azure"
  environment    = "disaster-recovery"
  # ... configuration
}
```

### Scenario 2: Regional Distribution

```hcl
# North America - AWS
module "na_infrastructure" {
  source         = "./modules/cloud-agnostic"
  cloud_provider = "aws"
  aws_config = {
    region = "us-east-1"
  }
}

# Europe - Azure
module "eu_infrastructure" {
  source         = "./modules/cloud-agnostic"
  cloud_provider = "azure"
  azure_config = {
    region = "West Europe"
  }
}

# Asia - GCP
module "asia_infrastructure" {
  source         = "./modules/cloud-agnostic"
  cloud_provider = "gcp"
  gcp_config = {
    region = "asia-east1"
  }
}
```

## Security Best Practices

1. **Encryption**: Always enable encryption at rest and in transit
2. **Network Isolation**: Use private subnets for data tier
3. **Access Control**: Implement least-privilege IAM policies
4. **Monitoring**: Enable comprehensive logging and alerting
5. **Secrets Management**: Use cloud-native secret stores

## Migration Between Providers

To migrate between cloud providers:

1. Deploy to new provider with same configuration
2. Migrate data using cloud-native tools
3. Update DNS/traffic routing
4. Validate new deployment
5. Decommission old infrastructure

## Requirements

- Terraform >= 1.6.0
- AWS Provider >= 5.0 (for AWS deployments)
- Azure Provider >= 3.80 (for Azure deployments)
- GCP Provider >= 5.7 (for GCP deployments)

## License

MIT License - See LICENSE file for details
