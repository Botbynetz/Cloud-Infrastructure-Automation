# ==============================================================================
# AWS Config Module Variables
# ==============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
  validation {
    condition     = can(regex("^(dev|staging|production)$", var.environment))
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# AWS Config Recorder Configuration
# ==============================================================================

variable "enable_config_recorder" {
  description = "Enable AWS Config recorder"
  type        = bool
  default     = true
}

variable "record_all_resources" {
  description = "Record all supported resource types"
  type        = bool
  default     = true
}

variable "include_global_resources" {
  description = "Include global resources (IAM, etc.) in recording"
  type        = bool
  default     = true
}

variable "recording_frequency" {
  description = "Recording frequency (CONTINUOUS, DAILY)"
  type        = string
  default     = "CONTINUOUS"
  validation {
    condition     = contains(["CONTINUOUS", "DAILY"], var.recording_frequency)
    error_message = "Recording frequency must be CONTINUOUS or DAILY."
  }
}

variable "excluded_resource_types" {
  description = "List of resource types to exclude from recording"
  type        = list(string)
  default     = []
}

variable "snapshot_delivery_frequency" {
  description = "How often to deliver configuration snapshots"
  type        = string
  default     = "TwentyFour_Hours"
  validation {
    condition = contains([
      "One_Hour",
      "Three_Hours",
      "Six_Hours",
      "Twelve_Hours",
      "TwentyFour_Hours"
    ], var.snapshot_delivery_frequency)
    error_message = "Invalid snapshot delivery frequency."
  }
}

# ==============================================================================
# Storage Configuration
# ==============================================================================

variable "config_retention_days" {
  description = "Number of days to retain Config data in S3"
  type        = number
  default     = 2555  # 7 years for compliance
  validation {
    condition     = var.config_retention_days >= 90
    error_message = "Config retention must be at least 90 days."
  }
}

variable "enable_config_encryption" {
  description = "Enable KMS encryption for Config data"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for Config encryption"
  type        = string
  default     = null
}

# ==============================================================================
# SNS Notification Configuration
# ==============================================================================

variable "config_sns_topic_arn" {
  description = "SNS topic ARN for Config notifications (leave empty to create new)"
  type        = string
  default     = ""
}

# ==============================================================================
# Config Rules Configuration
# ==============================================================================

variable "enable_encryption_rules" {
  description = "Enable encryption compliance rules"
  type        = bool
  default     = true
}

variable "enable_access_control_rules" {
  description = "Enable access control compliance rules"
  type        = bool
  default     = true
}

variable "enable_network_rules" {
  description = "Enable network security compliance rules"
  type        = bool
  default     = true
}

variable "enable_logging_rules" {
  description = "Enable logging compliance rules"
  type        = bool
  default     = true
}

# ==============================================================================
# Conformance Packs Configuration
# ==============================================================================

variable "enable_cis_conformance_pack" {
  description = "Enable CIS AWS Foundations conformance pack"
  type        = bool
  default     = false
}

variable "enable_operational_conformance_pack" {
  description = "Enable Operational Best Practices conformance pack"
  type        = bool
  default     = false
}

# ==============================================================================
# Config Aggregator Configuration
# ==============================================================================

variable "enable_config_aggregator" {
  description = "Enable AWS Config aggregator for multi-account/region"
  type        = bool
  default     = false
}

variable "aggregator_type" {
  description = "Type of aggregator (organization or account)"
  type        = string
  default     = "account"
  validation {
    condition     = contains(["organization", "account"], var.aggregator_type)
    error_message = "Aggregator type must be organization or account."
  }
}

variable "aggregator_role_arn" {
  description = "IAM role ARN for organization aggregator"
  type        = string
  default     = ""
}

variable "aggregator_account_ids" {
  description = "List of account IDs for account aggregator"
  type        = list(string)
  default     = []
}

# ==============================================================================
# Alarm Configuration
# ==============================================================================

variable "enable_compliance_alarms" {
  description = "Enable CloudWatch alarms for compliance violations"
  type        = bool
  default     = true
}

variable "compliance_alarm_threshold" {
  description = "Number of non-compliant resources to trigger alarm"
  type        = number
  default     = 5
  validation {
    condition     = var.compliance_alarm_threshold > 0
    error_message = "Compliance alarm threshold must be greater than 0."
  }
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarms trigger"
  type        = list(string)
  default     = []
}
