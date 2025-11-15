# ==============================================================================
# Cloud-Agnostic Infrastructure Module
# ==============================================================================
# Unified interface for deploying infrastructure across AWS, Azure, and GCP

terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.7"
    }
  }
}

# ==============================================================================
# AWS Resources
# ==============================================================================

module "aws_infrastructure" {
  source = "../../providers/aws"
  count  = var.cloud_provider == "aws" ? 1 : 0
  
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_config.region
  
  # Networking
  vpc_cidr             = var.networking_config.vpc_cidr
  availability_zones   = var.aws_config.availability_zones
  
  # Compute
  enable_ec2           = var.compute_config.enabled
  instance_type        = var.compute_config.instance_type
  
  # Storage
  enable_s3            = var.storage_config.enabled
  
  # Database
  enable_rds           = var.database_config.enabled
  db_instance_class    = var.database_config.instance_class
  
  # Monitoring
  enable_cloudwatch    = var.monitoring_config.enabled
  
  tags = merge(var.common_tags, {
    Provider = "AWS"
  })
}

# ==============================================================================
# Azure Resources
# ==============================================================================

module "azure_infrastructure" {
  source = "../../providers/azure"
  count  = var.cloud_provider == "azure" ? 1 : 0
  
  project_name = var.project_name
  environment  = var.environment
  azure_region = var.azure_config.region
  
  # Networking
  vnet_cidr            = var.networking_config.vpc_cidr
  app_subnet_cidr      = var.networking_config.app_subnet_cidr
  data_subnet_cidr     = var.networking_config.data_subnet_cidr
  
  # Storage
  storage_account_tier = var.storage_config.enabled ? "Standard" : null
  storage_replication  = var.azure_config.storage_replication
  
  # Monitoring
  log_retention_days   = var.monitoring_config.log_retention_days
  
  common_tags = merge(var.common_tags, {
    Provider = "Azure"
  })
}

# ==============================================================================
# GCP Resources
# ==============================================================================

module "gcp_infrastructure" {
  source = "../../providers/gcp"
  count  = var.cloud_provider == "gcp" ? 1 : 0
  
  gcp_project_id = var.gcp_config.project_id
  project_name   = var.project_name
  environment    = var.environment
  gcp_region     = var.gcp_config.region
  gcp_zone       = var.gcp_config.zone
  
  # Networking
  app_subnet_cidr     = var.networking_config.app_subnet_cidr
  data_subnet_cidr    = var.networking_config.data_subnet_cidr
  
  # Storage
  force_destroy_bucket = !var.storage_config.enable_versioning
  enable_cmek          = var.gcp_config.enable_cmek
  
  # Database
  enable_cloud_sql     = var.database_config.enabled
  cloud_sql_tier       = var.database_config.instance_class
  
  # Container Registry
  enable_artifact_registry = var.container_config.enabled
  
  # Monitoring
  enable_monitoring_alerts = var.monitoring_config.enabled
  alert_email              = var.monitoring_config.alert_email
  
  common_labels = merge(var.common_tags, {
    provider = "gcp"
  })
}

# ==============================================================================
# Cloud-Agnostic Outputs
# ==============================================================================

locals {
  # Normalize outputs across cloud providers
  vpc_id = (
    var.cloud_provider == "aws" ? try(module.aws_infrastructure[0].vpc_id, null) :
    var.cloud_provider == "azure" ? try(module.azure_infrastructure[0].vnet_id, null) :
    var.cloud_provider == "gcp" ? try(module.gcp_infrastructure[0].vpc_network_id, null) :
    null
  )
  
  vpc_cidr = (
    var.cloud_provider == "aws" ? try(module.aws_infrastructure[0].vpc_cidr, null) :
    var.cloud_provider == "azure" ? try(module.azure_infrastructure[0].vnet_address_space[0], null) :
    var.cloud_provider == "gcp" ? var.networking_config.vpc_cidr :
    null
  )
  
  storage_endpoint = (
    var.cloud_provider == "aws" ? try(module.aws_infrastructure[0].s3_bucket_domain_name, null) :
    var.cloud_provider == "azure" ? try(module.azure_infrastructure[0].storage_primary_blob_endpoint, null) :
    var.cloud_provider == "gcp" ? try(module.gcp_infrastructure[0].storage_bucket_url, null) :
    null
  )
  
  storage_name = (
    var.cloud_provider == "aws" ? try(module.aws_infrastructure[0].s3_bucket_id, null) :
    var.cloud_provider == "azure" ? try(module.azure_infrastructure[0].storage_account_name, null) :
    var.cloud_provider == "gcp" ? try(module.gcp_infrastructure[0].storage_bucket_name, null) :
    null
  )
  
  database_endpoint = (
    var.cloud_provider == "aws" ? try(module.aws_infrastructure[0].rds_endpoint, null) :
    var.cloud_provider == "azure" ? try(module.azure_infrastructure[0].postgresql_fqdn, null) :
    var.cloud_provider == "gcp" ? try(module.gcp_infrastructure[0].cloud_sql_connection_name, null) :
    null
  )
  
  monitoring_workspace_id = (
    var.cloud_provider == "aws" ? try(module.aws_infrastructure[0].cloudwatch_log_group_name, null) :
    var.cloud_provider == "azure" ? try(module.azure_infrastructure[0].log_analytics_workspace_id, null) :
    var.cloud_provider == "gcp" ? try(module.gcp_infrastructure[0].log_sink_name, null) :
    null
  )
  
  container_registry_url = (
    var.cloud_provider == "aws" ? try(module.aws_infrastructure[0].ecr_repository_url, null) :
    var.cloud_provider == "azure" ? try(module.azure_infrastructure[0].container_registry_login_server, null) :
    var.cloud_provider == "gcp" ? try(module.gcp_infrastructure[0].artifact_registry_location, null) :
    null
  )
}

# ==============================================================================
# Resource Tagging/Labeling
# ==============================================================================

locals {
  # Standardized tags/labels across providers
  standard_tags = merge(
    var.common_tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Provider    = var.cloud_provider
      Module      = "cloud-agnostic"
    }
  )
}

# ==============================================================================
# Cost Tracking
# ==============================================================================

resource "null_resource" "cost_tracking" {
  triggers = {
    cloud_provider = var.cloud_provider
    project_name   = var.project_name
    environment    = var.environment
    timestamp      = timestamp()
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "Deployment Details:" > deployment-info.txt
      echo "Cloud Provider: ${var.cloud_provider}" >> deployment-info.txt
      echo "Project: ${var.project_name}" >> deployment-info.txt
      echo "Environment: ${var.environment}" >> deployment-info.txt
      echo "Timestamp: ${timestamp()}" >> deployment-info.txt
      echo "VPC ID: ${local.vpc_id}" >> deployment-info.txt
      echo "Storage: ${local.storage_name}" >> deployment-info.txt
    EOT
  }
}
