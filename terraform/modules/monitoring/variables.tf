# ==============================================================================
# Monitoring Module Variables
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
# Log Configuration
# ==============================================================================

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
  
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention must be a valid CloudWatch Logs retention period."
  }
}

variable "security_log_retention_days" {
  description = "Number of days to retain security logs"
  type        = number
  default     = 365
  
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.security_log_retention_days)
    error_message = "Security log retention must be a valid CloudWatch Logs retention period."
  }
}

variable "enable_log_encryption" {
  description = "Enable KMS encryption for CloudWatch Logs"
  type        = bool
  default     = true
}

# ==============================================================================
# Alarm Configuration
# ==============================================================================

variable "enable_alarms" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers"
  type        = list(string)
  default     = []
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization threshold for alarm (percentage)"
  type        = number
  default     = 80
  
  validation {
    condition     = var.cpu_alarm_threshold >= 0 && var.cpu_alarm_threshold <= 100
    error_message = "CPU threshold must be between 0 and 100."
  }
}

variable "memory_alarm_threshold" {
  description = "Memory utilization threshold for alarm (percentage)"
  type        = number
  default     = 80
  
  validation {
    condition     = var.memory_alarm_threshold >= 0 && var.memory_alarm_threshold <= 100
    error_message = "Memory threshold must be between 0 and 100."
  }
}

variable "error_rate_threshold" {
  description = "Error rate threshold (errors per minute)"
  type        = number
  default     = 10
}

variable "response_time_threshold" {
  description = "Response time threshold in milliseconds"
  type        = number
  default     = 1000
}

variable "enable_database_alarms" {
  description = "Enable database-specific alarms"
  type        = bool
  default     = false
}

variable "database_connections_threshold" {
  description = "Maximum database connections threshold"
  type        = number
  default     = 80
}

# ==============================================================================
# Dashboard Configuration
# ==============================================================================

variable "enable_dashboards" {
  description = "Enable CloudWatch dashboards"
  type        = bool
  default     = true
}

variable "dashboard_widgets" {
  description = "Custom dashboard widgets configuration"
  type        = any
  default     = {}
}

# ==============================================================================
# Metric Configuration
# ==============================================================================

variable "custom_metrics" {
  description = "List of custom metric configurations"
  type = list(object({
    name        = string
    namespace   = string
    statistic   = string
    period      = number
    unit        = string
  }))
  default = []
}

# ==============================================================================
# SNS Configuration
# ==============================================================================

variable "enable_sns_notifications" {
  description = "Enable SNS notifications for alarms"
  type        = bool
  default     = true
}

variable "notification_emails" {
  description = "List of email addresses for alarm notifications"
  type        = list(string)
  default     = []
}

variable "notification_phone_numbers" {
  description = "List of phone numbers for SMS notifications"
  type        = list(string)
  default     = []
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}

# ==============================================================================
# X-Ray Configuration
# ==============================================================================

variable "enable_xray_tracing" {
  description = "Enable AWS X-Ray distributed tracing"
  type        = bool
  default     = false
}

variable "xray_sampling_rate" {
  description = "X-Ray sampling rate (0.0 to 1.0)"
  type        = number
  default     = 0.05
  
  validation {
    condition     = var.xray_sampling_rate >= 0 && var.xray_sampling_rate <= 1
    error_message = "X-Ray sampling rate must be between 0 and 1."
  }
}

# ==============================================================================
# CloudWatch Insights Configuration
# ==============================================================================

variable "enable_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = false
}

variable "insights_retention_days" {
  description = "Number of days to retain Container Insights data"
  type        = number
  default     = 7
}

# ==============================================================================
# Cost Monitoring Configuration
# ==============================================================================

variable "enable_cost_monitoring" {
  description = "Enable cost monitoring dashboard"
  type        = bool
  default     = true
}

variable "cost_budget_threshold" {
  description = "Monthly cost budget threshold in USD"
  type        = number
  default     = 100
}

variable "cost_alert_thresholds" {
  description = "Cost alert thresholds (percentage of budget)"
  type        = list(number)
  default     = [50, 80, 100]
}

# ==============================================================================
# Security Monitoring Configuration
# ==============================================================================

variable "enable_security_monitoring" {
  description = "Enable security monitoring dashboard"
  type        = bool
  default     = true
}

variable "security_alert_on_failed_logins" {
  description = "Number of failed login attempts before alerting"
  type        = number
  default     = 5
}

variable "security_alert_on_unauthorized_access" {
  description = "Alert on any unauthorized access attempt"
  type        = bool
  default     = true
}
