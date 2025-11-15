# ==============================================================================
# Azure Provider - Input Variables
# ==============================================================================

# ------------------------------------------------------------------------------
# General Configuration
# ------------------------------------------------------------------------------

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
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
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

# ------------------------------------------------------------------------------
# Azure Configuration
# ------------------------------------------------------------------------------

variable "azure_region" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
}

variable "prevent_rg_deletion" {
  description = "Prevent deletion of resource group if it contains resources"
  type        = bool
  default     = true
}

variable "purge_key_vault_on_destroy" {
  description = "Purge Key Vault on destroy (disable for production)"
  type        = bool
  default     = false
}

# ------------------------------------------------------------------------------
# Networking Configuration
# ------------------------------------------------------------------------------

variable "vnet_address_space" {
  description = "Address space for virtual network"
  type        = string
  default     = "10.1.0.0/16"
}

variable "app_subnet_prefix" {
  description = "Address prefix for application subnet"
  type        = string
  default     = "10.1.1.0/24"
}

variable "data_subnet_prefix" {
  description = "Address prefix for data subnet"
  type        = string
  default     = "10.1.2.0/24"
}

variable "admin_source_ip" {
  description = "Source IP address for admin access (SSH)"
  type        = string
  default     = "*"
}

# ------------------------------------------------------------------------------
# Storage Configuration
# ------------------------------------------------------------------------------

variable "storage_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.storage_replication_type)
    error_message = "Invalid storage replication type."
  }
}

# ------------------------------------------------------------------------------
# Monitoring Configuration
# ------------------------------------------------------------------------------

variable "log_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 30
  validation {
    condition     = var.log_retention_days >= 7 && var.log_retention_days <= 730
    error_message = "Log retention must be between 7 and 730 days."
  }
}

# ------------------------------------------------------------------------------
# Container Registry Configuration
# ------------------------------------------------------------------------------

variable "enable_container_registry" {
  description = "Enable Azure Container Registry"
  type        = bool
  default     = false
}

variable "acr_replica_location" {
  description = "Location for ACR geo-replication"
  type        = string
  default     = "West US"
}
