# Variables for Multi-Cloud KMS Module

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Common tags for AWS resources"
  type        = map(string)
  default     = {}
}

variable "gcp_labels" {
  description = "Common labels for GCP resources"
  type        = map(string)
  default     = {}
}

# ============================================
# Feature Flags
# ============================================

variable "enable_aws_kms" {
  description = "Enable AWS KMS keys"
  type        = bool
  default     = true
}

variable "enable_gcp_kms" {
  description = "Enable GCP KMS keys"
  type        = bool
  default     = false
}

variable "enable_azure_keyvault" {
  description = "Enable Azure Key Vault"
  type        = bool
  default     = false
}

variable "enable_multi_region_kms" {
  description = "Enable multi-region KMS keys (AWS)"
  type        = bool
  default     = false
}

variable "enable_cross_account_access" {
  description = "Enable cross-account KMS access"
  type        = bool
  default     = false
}

# ============================================
# AWS KMS Configuration
# ============================================

variable "kms_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 10
  
  validation {
    condition     = var.kms_deletion_window >= 7 && var.kms_deletion_window <= 30
    error_message = "Deletion window must be between 7 and 30 days."
  }
}

variable "cross_account_role_arns" {
  description = "List of cross-account IAM role ARNs for KMS access"
  type        = list(string)
  default     = []
}

# ============================================
# GCP KMS Configuration
# ============================================

variable "gcp_region" {
  description = "GCP region for key ring"
  type        = string
  default     = "asia-southeast1"
}

# ============================================
# Azure Key Vault Configuration
# ============================================

variable "azure_location" {
  description = "Azure location for Key Vault"
  type        = string
  default     = "Southeast Asia"
}

variable "allowed_ip_ranges" {
  description = "Allowed IP ranges for Azure Key Vault access"
  type        = list(string)
  default     = []
}
