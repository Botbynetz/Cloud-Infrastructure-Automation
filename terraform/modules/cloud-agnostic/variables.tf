# ==============================================================================
# Cloud-Agnostic Module Variables
# ==============================================================================

variable "cloud_provider" {
  description = "Target cloud provider (aws, azure, gcp)"
  type        = string
  
  validation {
    condition     = contains(["aws", "azure", "gcp"], var.cloud_provider)
    error_message = "Cloud provider must be aws, azure, or gcp."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "cloud-infra"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "common_tags" {
  description = "Common tags/labels to apply to all resources"
  type        = map(string)
  default = {
    Project   = "cloud-infrastructure-automation"
    ManagedBy = "terraform"
  }
}

# ==============================================================================
# AWS Configuration
# ==============================================================================

variable "aws_config" {
  description = "AWS-specific configuration"
  type = object({
    region             = string
    availability_zones = list(string)
  })
  default = {
    region             = "us-east-1"
    availability_zones = ["us-east-1a", "us-east-1b"]
  }
}

# ==============================================================================
# Azure Configuration
# ==============================================================================

variable "azure_config" {
  description = "Azure-specific configuration"
  type = object({
    region              = string
    storage_replication = string
  })
  default = {
    region              = "East US"
    storage_replication = "LRS"
  }
}

# ==============================================================================
# GCP Configuration
# ==============================================================================

variable "gcp_config" {
  description = "GCP-specific configuration"
  type = object({
    project_id  = string
    region      = string
    zone        = string
    enable_cmek = bool
  })
  default = {
    project_id  = ""
    region      = "us-central1"
    zone        = "us-central1-a"
    enable_cmek = false
  }
}

# ==============================================================================
# Networking Configuration
# ==============================================================================

variable "networking_config" {
  description = "Networking configuration applicable across all providers"
  type = object({
    vpc_cidr         = string
    app_subnet_cidr  = string
    data_subnet_cidr = string
  })
  default = {
    vpc_cidr         = "10.0.0.0/16"
    app_subnet_cidr  = "10.0.1.0/24"
    data_subnet_cidr = "10.0.2.0/24"
  }
}

# ==============================================================================
# Compute Configuration
# ==============================================================================

variable "compute_config" {
  description = "Compute instance configuration"
  type = object({
    enabled       = bool
    instance_type = string
    instance_count = number
  })
  default = {
    enabled       = true
    instance_type = "t3.micro" # AWS default, will be translated for other providers
    instance_count = 1
  }
}

# ==============================================================================
# Storage Configuration
# ==============================================================================

variable "storage_config" {
  description = "Storage configuration"
  type = object({
    enabled           = bool
    enable_versioning = bool
    enable_encryption = bool
  })
  default = {
    enabled           = true
    enable_versioning = true
    enable_encryption = true
  }
}

# ==============================================================================
# Database Configuration
# ==============================================================================

variable "database_config" {
  description = "Database configuration"
  type = object({
    enabled        = bool
    engine         = string
    engine_version = string
    instance_class = string
    storage_size   = number
  })
  default = {
    enabled        = false
    engine         = "postgres"
    engine_version = "15"
    instance_class = "db-t3.micro" # Will be translated for other providers
    storage_size   = 20
  }
}

# ==============================================================================
# Container Configuration
# ==============================================================================

variable "container_config" {
  description = "Container registry configuration"
  type = object({
    enabled             = bool
    enable_vulnerability_scan = bool
  })
  default = {
    enabled             = true
    enable_vulnerability_scan = true
  }
}

# ==============================================================================
# Monitoring Configuration
# ==============================================================================

variable "monitoring_config" {
  description = "Monitoring and logging configuration"
  type = object({
    enabled            = bool
    log_retention_days = number
    enable_alerts      = bool
    alert_email        = string
  })
  default = {
    enabled            = true
    log_retention_days = 30
    enable_alerts      = true
    alert_email        = "admin@example.com"
  }
}

# ==============================================================================
# Security Configuration
# ==============================================================================

variable "security_config" {
  description = "Security configuration"
  type = object({
    enable_encryption_at_rest   = bool
    enable_encryption_in_transit = bool
    enable_network_isolation    = bool
    allowed_ip_ranges           = list(string)
  })
  default = {
    enable_encryption_at_rest   = true
    enable_encryption_in_transit = true
    enable_network_isolation    = true
    allowed_ip_ranges           = ["0.0.0.0/0"]
  }
}

# ==============================================================================
# Cost Management Configuration
# ==============================================================================

variable "cost_config" {
  description = "Cost management configuration"
  type = object({
    enable_cost_tracking = bool
    budget_amount        = number
    budget_alert_email   = string
  })
  default = {
    enable_cost_tracking = true
    budget_amount        = 100
    budget_alert_email   = "billing@example.com"
  }
}

# ==============================================================================
# High Availability Configuration
# ==============================================================================

variable "ha_config" {
  description = "High availability configuration"
  type = object({
    enable_multi_az     = bool
    enable_auto_scaling = bool
    min_instances       = number
    max_instances       = number
  })
  default = {
    enable_multi_az     = false
    enable_auto_scaling = false
    min_instances       = 1
    max_instances       = 3
  }
}
