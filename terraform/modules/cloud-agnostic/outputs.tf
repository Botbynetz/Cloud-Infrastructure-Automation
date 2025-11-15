# ==============================================================================
# Cloud-Agnostic Module Outputs
# ==============================================================================

# ==============================================================================
# Provider Information
# ==============================================================================

output "cloud_provider" {
  description = "Active cloud provider"
  value       = var.cloud_provider
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

# ==============================================================================
# Networking Outputs
# ==============================================================================

output "vpc_id" {
  description = "Virtual network ID (VPC/VNet)"
  value       = local.vpc_id
}

output "vpc_cidr" {
  description = "Virtual network CIDR block"
  value       = local.vpc_cidr
}

output "app_subnet_id" {
  description = "Application subnet ID"
  value = (
    var.cloud_provider == "aws" ? try(module.aws_infrastructure[0].app_subnet_ids[0], null) :
    var.cloud_provider == "azure" ? try(module.azure_infrastructure[0].app_subnet_id, null) :
    var.cloud_provider == "gcp" ? try(module.gcp_infrastructure[0].app_subnet_id, null) :
    null
  )
}

output "data_subnet_id" {
  description = "Data subnet ID"
  value = (
    var.cloud_provider == "aws" ? try(module.aws_infrastructure[0].data_subnet_ids[0], null) :
    var.cloud_provider == "azure" ? try(module.azure_infrastructure[0].data_subnet_id, null) :
    var.cloud_provider == "gcp" ? try(module.gcp_infrastructure[0].data_subnet_id, null) :
    null
  )
}

# ==============================================================================
# Storage Outputs
# ==============================================================================

output "storage_endpoint" {
  description = "Storage service endpoint URL"
  value       = local.storage_endpoint
}

output "storage_name" {
  description = "Storage service name/identifier"
  value       = local.storage_name
}

output "storage_arn" {
  description = "Storage resource ARN (AWS only)"
  value = var.cloud_provider == "aws" ? try(module.aws_infrastructure[0].s3_bucket_arn, null) : null
}

# ==============================================================================
# Database Outputs
# ==============================================================================

output "database_endpoint" {
  description = "Database connection endpoint"
  value       = local.database_endpoint
  sensitive   = true
}

output "database_name" {
  description = "Database instance name"
  value = (
    var.cloud_provider == "aws" ? try(module.aws_infrastructure[0].rds_instance_id, null) :
    var.cloud_provider == "azure" ? try(module.azure_infrastructure[0].postgresql_server_name, null) :
    var.cloud_provider == "gcp" ? try(module.gcp_infrastructure[0].cloud_sql_instance_name, null) :
    null
  )
}

# ==============================================================================
# Monitoring Outputs
# ==============================================================================

output "monitoring_workspace_id" {
  description = "Monitoring/logging workspace identifier"
  value       = local.monitoring_workspace_id
}

output "monitoring_workspace_name" {
  description = "Monitoring/logging workspace name"
  value = (
    var.cloud_provider == "aws" ? try(module.aws_infrastructure[0].cloudwatch_log_group_name, null) :
    var.cloud_provider == "azure" ? try(module.azure_infrastructure[0].log_analytics_workspace_name, null) :
    var.cloud_provider == "gcp" ? try(module.gcp_infrastructure[0].log_sink_name, null) :
    null
  )
}

output "application_insights_key" {
  description = "Application insights instrumentation key (Azure only)"
  value       = var.cloud_provider == "azure" ? try(module.azure_infrastructure[0].application_insights_instrumentation_key, null) : null
  sensitive   = true
}

# ==============================================================================
# Container Registry Outputs
# ==============================================================================

output "container_registry_url" {
  description = "Container registry URL"
  value       = local.container_registry_url
}

output "container_registry_name" {
  description = "Container registry name"
  value = (
    var.cloud_provider == "aws" ? try(module.aws_infrastructure[0].ecr_repository_name, null) :
    var.cloud_provider == "azure" ? try(module.azure_infrastructure[0].container_registry_name, null) :
    var.cloud_provider == "gcp" ? try(module.gcp_infrastructure[0].artifact_registry_name, null) :
    null
  )
}

# ==============================================================================
# Security Outputs
# ==============================================================================

output "key_vault_uri" {
  description = "Key vault/secrets manager URI"
  value = (
    var.cloud_provider == "aws" ? try(module.aws_infrastructure[0].secrets_manager_arn, null) :
    var.cloud_provider == "azure" ? try(module.azure_infrastructure[0].key_vault_uri, null) :
    var.cloud_provider == "gcp" ? try(module.gcp_infrastructure[0].secret_manager_secret_name, null) :
    null
  )
  sensitive = true
}

output "security_group_id" {
  description = "Primary security group/NSG ID"
  value = (
    var.cloud_provider == "aws" ? try(module.aws_infrastructure[0].security_group_id, null) :
    var.cloud_provider == "azure" ? try(module.azure_infrastructure[0].network_security_group_id, null) :
    var.cloud_provider == "gcp" ? null : # GCP uses firewall rules instead
    null
  )
}

# ==============================================================================
# Cost Tracking Outputs
# ==============================================================================

output "deployment_timestamp" {
  description = "Deployment timestamp for cost tracking"
  value       = timestamp()
}

output "estimated_monthly_cost" {
  description = "Estimated monthly cost (placeholder - use cloud provider cost calculators)"
  value = {
    currency = "USD"
    note     = "Use cloud provider cost management tools for accurate estimates"
    aws_calculator      = "https://calculator.aws/"
    azure_calculator    = "https://azure.microsoft.com/en-us/pricing/calculator/"
    gcp_calculator      = "https://cloud.google.com/products/calculator"
  }
}

# ==============================================================================
# Infrastructure Summary
# ==============================================================================

output "infrastructure_summary" {
  description = "Comprehensive infrastructure summary"
  value = {
    provider = var.cloud_provider
    project  = var.project_name
    environment = var.environment
    
    networking = {
      vpc_id   = local.vpc_id
      vpc_cidr = local.vpc_cidr
      subnets  = {
        app  = var.networking_config.app_subnet_cidr
        data = var.networking_config.data_subnet_cidr
      }
    }
    
    compute = {
      enabled = var.compute_config.enabled
      type    = var.compute_config.instance_type
      count   = var.compute_config.instance_count
    }
    
    storage = {
      enabled    = var.storage_config.enabled
      name       = local.storage_name
      versioning = var.storage_config.enable_versioning
      encryption = var.storage_config.enable_encryption
    }
    
    database = {
      enabled  = var.database_config.enabled
      engine   = var.database_config.engine
      version  = var.database_config.engine_version
      size     = var.database_config.storage_size
    }
    
    monitoring = {
      enabled           = var.monitoring_config.enabled
      workspace_id      = local.monitoring_workspace_id
      log_retention     = var.monitoring_config.log_retention_days
      alerts_enabled    = var.monitoring_config.enable_alerts
    }
    
    container_registry = {
      enabled = var.container_config.enabled
      url     = local.container_registry_url
    }
    
    security = {
      encryption_at_rest   = var.security_config.enable_encryption_at_rest
      encryption_in_transit = var.security_config.enable_encryption_in_transit
      network_isolation    = var.security_config.enable_network_isolation
    }
    
    high_availability = {
      multi_az      = var.ha_config.enable_multi_az
      auto_scaling  = var.ha_config.enable_auto_scaling
      min_instances = var.ha_config.min_instances
      max_instances = var.ha_config.max_instances
    }
    
    cost_management = {
      tracking_enabled = var.cost_config.enable_cost_tracking
      budget_amount    = var.cost_config.budget_amount
    }
    
    tags = local.standard_tags
  }
}

# ==============================================================================
# Provider-Specific Outputs
# ==============================================================================

output "aws_specific_outputs" {
  description = "AWS-specific output values"
  value = var.cloud_provider == "aws" ? {
    vpc_id                = try(module.aws_infrastructure[0].vpc_id, null)
    s3_bucket_arn         = try(module.aws_infrastructure[0].s3_bucket_arn, null)
    ecr_repository_url    = try(module.aws_infrastructure[0].ecr_repository_url, null)
    cloudwatch_log_group  = try(module.aws_infrastructure[0].cloudwatch_log_group_name, null)
  } : null
}

output "azure_specific_outputs" {
  description = "Azure-specific output values"
  value = var.cloud_provider == "azure" ? {
    resource_group_name   = try(module.azure_infrastructure[0].resource_group_name, null)
    vnet_id               = try(module.azure_infrastructure[0].vnet_id, null)
    storage_account_name  = try(module.azure_infrastructure[0].storage_account_name, null)
    key_vault_uri         = try(module.azure_infrastructure[0].key_vault_uri, null)
    log_analytics_workspace_id = try(module.azure_infrastructure[0].log_analytics_workspace_id, null)
  } : null
  sensitive = true
}

output "gcp_specific_outputs" {
  description = "GCP-specific output values"
  value = var.cloud_provider == "gcp" ? {
    project_id            = try(module.gcp_infrastructure[0].project_id, null)
    vpc_network_name      = try(module.gcp_infrastructure[0].vpc_network_name, null)
    storage_bucket_name   = try(module.gcp_infrastructure[0].storage_bucket_name, null)
    artifact_registry_id  = try(module.gcp_infrastructure[0].artifact_registry_id, null)
  } : null
}
