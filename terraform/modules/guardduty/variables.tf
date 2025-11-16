# ==============================================================================
# AWS GuardDuty Module Variables
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
# GuardDuty Detector Configuration
# ==============================================================================

variable "enable_guardduty" {
  description = "Enable GuardDuty detector"
  type        = bool
  default     = true
}

variable "finding_publishing_frequency" {
  description = "Frequency of publishing findings (FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS)"
  type        = string
  default     = "FIFTEEN_MINUTES"
  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.finding_publishing_frequency)
    error_message = "Finding publishing frequency must be FIFTEEN_MINUTES, ONE_HOUR, or SIX_HOURS."
  }
}

# ==============================================================================
# Data Sources Configuration
# ==============================================================================

variable "enable_s3_logs_protection" {
  description = "Enable S3 protection in GuardDuty"
  type        = bool
  default     = true
}

variable "enable_kubernetes_audit_logs" {
  description = "Enable Kubernetes audit logs protection"
  type        = bool
  default     = false
}

variable "enable_malware_protection" {
  description = "Enable malware protection for EC2 instances"
  type        = bool
  default     = true
}

# ==============================================================================
# Findings Export Configuration
# ==============================================================================

variable "enable_findings_export" {
  description = "Enable exporting findings to S3"
  type        = bool
  default     = true
}

variable "findings_retention_days" {
  description = "Number of days to retain findings in S3"
  type        = number
  default     = 90
  validation {
    condition     = var.findings_retention_days >= 1
    error_message = "Findings retention must be at least 1 day."
  }
}

variable "enable_findings_encryption" {
  description = "Enable KMS encryption for findings"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for findings encryption"
  type        = string
  default     = null
}

variable "findings_log_retention_days" {
  description = "CloudWatch Logs retention for GuardDuty findings"
  type        = number
  default     = 30
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.findings_log_retention_days)
    error_message = "Invalid log retention period."
  }
}

# ==============================================================================
# Filters Configuration
# ==============================================================================

variable "enable_critical_filter" {
  description = "Enable filter to archive low-severity findings"
  type        = bool
  default     = false
}

# ==============================================================================
# IPSet and ThreatIntelSet Configuration
# ==============================================================================

variable "enable_trusted_ips" {
  description = "Enable trusted IP list"
  type        = bool
  default     = false
}

variable "trusted_ip_list" {
  description = "List of trusted IP addresses/CIDRs"
  type        = list(string)
  default     = []
}

variable "enable_threat_intel" {
  description = "Enable threat intelligence IP list"
  type        = bool
  default     = false
}

variable "threat_ip_list" {
  description = "List of known threat IP addresses/CIDRs"
  type        = list(string)
  default     = []
}

# ==============================================================================
# SNS Notification Configuration
# ==============================================================================

variable "guardduty_sns_topic_arn" {
  description = "SNS topic ARN for GuardDuty alerts (leave empty to create new)"
  type        = string
  default     = ""
}

variable "alert_severity_levels" {
  description = "Severity levels that trigger alerts (1-10)"
  type        = list(number)
  default     = [4.0, 7.0, 8.0]  # Medium, High, Critical
  validation {
    condition     = alltrue([for s in var.alert_severity_levels : s >= 0.1 && s <= 10.0])
    error_message = "Severity levels must be between 0.1 and 10.0."
  }
}

# ==============================================================================
# Alarm Configuration
# ==============================================================================

variable "enable_guardduty_alarms" {
  description = "Enable CloudWatch alarms for GuardDuty"
  type        = bool
  default     = true
}

variable "high_severity_threshold" {
  description = "Number of high-severity findings to trigger alarm"
  type        = number
  default     = 1
  validation {
    condition     = var.high_severity_threshold > 0
    error_message = "High severity threshold must be greater than 0."
  }
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarms trigger"
  type        = list(string)
  default     = []
}

# ==============================================================================
# Multi-Account Configuration
# ==============================================================================

variable "enable_member_accounts" {
  description = "Enable GuardDuty member accounts (for multi-account setup)"
  type        = bool
  default     = false
}

variable "member_accounts" {
  description = "List of member accounts to invite"
  type = list(object({
    account_id = string
    email      = string
  }))
  default = []
}

# ==============================================================================
# Dashboard Configuration
# ==============================================================================

variable "enable_guardduty_dashboard" {
  description = "Enable CloudWatch dashboard for GuardDuty"
  type        = bool
  default     = true
}
