# FinOps Tagging Strategy - Mandatory Tags for All Resources
# This file defines the required tags for cost tracking, compliance, and governance

locals {
  # Mandatory tags that MUST be present on ALL resources
  mandatory_tags = {
    # FinOps & Cost Management
    CostCenter     = var.cost_center
    BusinessUnit   = var.business_unit
    Owner          = var.owner_email
    Project        = var.project_name
    
    # Environment & Lifecycle
    Environment    = var.environment
    LifecycleStage = var.lifecycle_stage  # dev, staging, prod, dr
    
    # Compliance & Security
    DataClassification = var.data_classification  # public, internal, confidential, restricted
    Compliance         = var.compliance_framework  # GDPR, HIPAA, PCI-DSS, SOC2, ISO27001
    
    # Technical & Operations
    ManagedBy      = "Terraform"
    Repository     = var.repository_url
    TerraformPath  = path.module
    
    # Deployment tracking
    DeployedBy     = var.deployed_by
    DeployedDate   = timestamp()
    
    # Auto-shutdown for cost optimization
    AutoShutdown   = var.auto_shutdown_enabled
    ShutdownSchedule = var.shutdown_schedule  # e.g., "weekdays-after-hours"
  }
  
  # Optional tags for enhanced tracking
  optional_tags = merge(
    var.additional_tags,
    {
      Application    = var.application_name
      Version        = var.application_version
      ServiceLevel   = var.service_level  # bronze, silver, gold, platinum
      BackupPolicy   = var.backup_policy  # daily, weekly, none
      DisasterRecoveryRPO = var.dr_rpo    # 1h, 4h, 24h
      DisasterRecoveryRTO = var.dr_rto    # 1h, 4h, 24h
    }
  )
  
  # Combine mandatory and optional tags
  common_tags = merge(local.mandatory_tags, local.optional_tags)
}

# Validation: Ensure mandatory tags are not empty
variable "cost_center" {
  description = "Cost center code for billing allocation (MANDATORY)"
  type        = string
  validation {
    condition     = length(var.cost_center) > 0
    error_message = "cost_center is mandatory and cannot be empty. Required for FinOps tracking."
  }
}

variable "business_unit" {
  description = "Business unit name (MANDATORY)"
  type        = string
  validation {
    condition     = length(var.business_unit) > 0
    error_message = "business_unit is mandatory and cannot be empty."
  }
}

variable "owner_email" {
  description = "Email of the resource owner (MANDATORY)"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.owner_email))
    error_message = "owner_email must be a valid email address."
  }
}

variable "project_name" {
  description = "Project name (MANDATORY)"
  type        = string
}

variable "environment" {
  description = "Environment name (MANDATORY)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod", "dr"], var.environment)
    error_message = "environment must be one of: dev, staging, prod, dr."
  }
}

variable "lifecycle_stage" {
  description = "Lifecycle stage of resources"
  type        = string
  default     = "active"
  validation {
    condition     = contains(["active", "deprecated", "eol", "testing"], var.lifecycle_stage)
    error_message = "lifecycle_stage must be one of: active, deprecated, eol, testing."
  }
}

variable "data_classification" {
  description = "Data classification level (MANDATORY for compliance)"
  type        = string
  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "data_classification must be one of: public, internal, confidential, restricted."
  }
}

variable "compliance_framework" {
  description = "Compliance framework requirements (comma-separated)"
  type        = string
  default     = "none"
}

variable "repository_url" {
  description = "Git repository URL"
  type        = string
  default     = "https://github.com/Botbynetz/Cloud-Infrastructure-Automation"
}

variable "deployed_by" {
  description = "Who deployed this resource (user or CI/CD system)"
  type        = string
  default     = "terraform-automation"
}

variable "auto_shutdown_enabled" {
  description = "Enable auto-shutdown for cost optimization"
  type        = bool
  default     = false
}

variable "shutdown_schedule" {
  description = "Auto-shutdown schedule (e.g., weekdays-after-hours, weekends)"
  type        = string
  default     = "disabled"
}

variable "additional_tags" {
  description = "Additional custom tags"
  type        = map(string)
  default     = {}
}

variable "application_name" {
  description = "Application name"
  type        = string
  default     = ""
}

variable "application_version" {
  description = "Application version"
  type        = string
  default     = ""
}

variable "service_level" {
  description = "Service level agreement tier"
  type        = string
  default     = "bronze"
  validation {
    condition     = contains(["bronze", "silver", "gold", "platinum"], var.service_level)
    error_message = "service_level must be one of: bronze, silver, gold, platinum."
  }
}

variable "backup_policy" {
  description = "Backup policy"
  type        = string
  default     = "none"
}

variable "dr_rpo" {
  description = "Disaster Recovery Recovery Point Objective"
  type        = string
  default     = "24h"
}

variable "dr_rto" {
  description = "Disaster Recovery Recovery Time Objective"
  type        = string
  default     = "24h"
}

# Output common tags for use in other modules
output "common_tags" {
  description = "Common tags to be applied to all resources"
  value       = local.common_tags
}

output "mandatory_tags" {
  description = "Mandatory tags only (for validation)"
  value       = local.mandatory_tags
}
