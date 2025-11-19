# Multi-Cloud Provider Configuration
# Supports AWS, GCP, and Azure simultaneously

terraform {
  required_version = ">= 1.5"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.20"
    }
  }
}

# ============================================
# AWS Provider Configuration
# ============================================
provider "aws" {
  region = var.aws_region
  
  # Use default tags for all AWS resources
  default_tags {
    tags = merge(
      local.common_tags,
      {
        CloudProvider = "AWS"
      }
    )
  }
  
  # Assume role for cross-account deployment (optional)
  assume_role {
    role_arn     = var.aws_assume_role_arn
    session_name = "terraform-${var.environment}"
  }
}

# AWS Secondary Region for DR/Multi-Region
provider "aws" {
  alias  = "dr"
  region = var.aws_dr_region
  
  default_tags {
    tags = merge(
      local.common_tags,
      {
        CloudProvider = "AWS"
        Purpose       = "DisasterRecovery"
      }
    )
  }
}

# ============================================
# Google Cloud Provider Configuration
# ============================================
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
  
  # Use credentials from service account JSON or ADC
  credentials = var.gcp_credentials_file != "" ? file(var.gcp_credentials_file) : null
  
  # Default labels for all GCP resources
  default_labels = merge(
    {
      environment     = var.environment
      managed_by      = "terraform"
      project         = var.project_name
      cloud_provider  = "gcp"
    },
    var.gcp_additional_labels
  )
}

# GCP Secondary Region for DR/Multi-Region
provider "google" {
  alias   = "dr"
  project = var.gcp_project_id
  region  = var.gcp_dr_region
  zone    = var.gcp_dr_zone
  
  credentials = var.gcp_credentials_file != "" ? file(var.gcp_credentials_file) : null
}

# ============================================
# Azure Provider Configuration
# ============================================
provider "azurerm" {
  features {
    # Key Vault features
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    
    # Resource Group features
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    
    # Virtual Machine features
    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = true
      skip_shutdown_and_force_delete = false
    }
  }
  
  # Use service principal or managed identity
  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_tenant_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  
  # Skip provider registration (if already done)
  skip_provider_registration = var.azure_skip_provider_registration
}

# Azure Secondary Region for DR/Multi-Region
provider "azurerm" {
  alias = "dr"
  
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
  
  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_tenant_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
}

# ============================================
# HashiCorp Vault Provider (for secrets)
# ============================================
provider "vault" {
  address = var.vault_address
  token   = var.vault_token
  
  # Skip TLS verification for development only
  skip_tls_verify = var.environment == "dev" ? true : false
}

# ============================================
# Provider Variables
# ============================================

# AWS Variables
variable "aws_region" {
  description = "Primary AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_dr_region" {
  description = "DR AWS region"
  type        = string
  default     = "us-west-2"
}

variable "aws_assume_role_arn" {
  description = "AWS IAM role ARN to assume (optional)"
  type        = string
  default     = ""
}

# GCP Variables
variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
  default     = ""
}

variable "gcp_region" {
  description = "Primary GCP region"
  type        = string
  default     = "asia-southeast1"
}

variable "gcp_zone" {
  description = "Primary GCP zone"
  type        = string
  default     = "asia-southeast1-a"
}

variable "gcp_dr_region" {
  description = "DR GCP region"
  type        = string
  default     = "us-west1"
}

variable "gcp_dr_zone" {
  description = "DR GCP zone"
  type        = string
  default     = "us-west1-a"
}

variable "gcp_credentials_file" {
  description = "Path to GCP service account credentials JSON file"
  type        = string
  default     = ""
  sensitive   = true
}

variable "gcp_additional_labels" {
  description = "Additional labels for GCP resources"
  type        = map(string)
  default     = {}
}

# Azure Variables
variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_tenant_id" {
  description = "Azure tenant ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_client_id" {
  description = "Azure service principal client ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_client_secret" {
  description = "Azure service principal client secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_skip_provider_registration" {
  description = "Skip Azure provider registration"
  type        = bool
  default     = false
}

# Vault Variables
variable "vault_address" {
  description = "HashiCorp Vault server address"
  type        = string
  default     = "https://vault.example.com:8200"
}

variable "vault_token" {
  description = "HashiCorp Vault authentication token"
  type        = string
  default     = ""
  sensitive   = true
}
