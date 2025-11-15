# ==============================================================================
# Advanced Alerting Module Variables
# ==============================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# SNS Configuration
# ==============================================================================

variable "enable_sns_notifications" {
  description = "Enable SNS notifications"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Enable encryption for SNS topics"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for SNS encryption"
  type        = string
  default     = ""
}

# ==============================================================================
# Email Subscriptions
# ==============================================================================

variable "critical_email_endpoints" {
  description = "List of email addresses for critical alerts"
  type        = list(string)
  default     = []
}

variable "warning_email_endpoints" {
  description = "List of email addresses for warning alerts"
  type        = list(string)
  default     = []
}

variable "info_email_endpoints" {
  description = "List of email addresses for info alerts"
  type        = list(string)
  default     = []
}

# ==============================================================================
# SMS Subscriptions
# ==============================================================================

variable "enable_sms_notifications" {
  description = "Enable SMS notifications for critical alerts"
  type        = bool
  default     = false
}

variable "critical_sms_endpoints" {
  description = "List of phone numbers for critical SMS alerts (E.164 format)"
  type        = list(string)
  default     = []
}

# ==============================================================================
# Slack Integration
# ==============================================================================

variable "enable_slack_notifications" {
  description = "Enable Slack notifications"
  type        = bool
  default     = false
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}

variable "slack_channel" {
  description = "Slack channel for notifications"
  type        = string
  default     = "#alerts"
}

# ==============================================================================
# PagerDuty Integration
# ==============================================================================

variable "enable_pagerduty_notifications" {
  description = "Enable PagerDuty notifications"
  type        = bool
  default     = false
}

variable "pagerduty_integration_key" {
  description = "PagerDuty integration key"
  type        = string
  default     = ""
  sensitive   = true
}

# ==============================================================================
# Alert Aggregation
# ==============================================================================

variable "enable_alert_aggregation" {
  description = "Enable alert aggregation to prevent alert fatigue"
  type        = bool
  default     = true
}

variable "alert_aggregation_window" {
  description = "Time window in seconds for alert aggregation"
  type        = number
  default     = 300  # 5 minutes
}

# ==============================================================================
# Escalation Configuration
# ==============================================================================

variable "enable_escalation" {
  description = "Enable alert escalation workflow"
  type        = bool
  default     = false
}

variable "escalation_wait_time" {
  description = "Time in seconds to wait before escalating unacknowledged alerts"
  type        = number
  default     = 900  # 15 minutes
}
