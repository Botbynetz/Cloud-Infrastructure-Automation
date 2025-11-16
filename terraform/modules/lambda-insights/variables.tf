# ==============================================================================
# Lambda Insights Module Variables
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
# Lambda Configuration
# ==============================================================================

variable "lambda_role_names" {
  description = "List of Lambda IAM role names to attach Lambda Insights policy to"
  type        = list(string)
  default     = []
}

variable "lambda_log_group_names" {
  description = "List of Lambda CloudWatch log group names for error analysis"
  type        = list(string)
  default     = []
}

variable "primary_function_name" {
  description = "Primary Lambda function name for alarms"
  type        = string
  default     = ""
}

# ==============================================================================
# CloudWatch Configuration
# ==============================================================================

variable "log_retention_days" {
  description = "Number of days to retain Lambda Insights logs"
  type        = number
  default     = 30
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch Logs retention period."
  }
}

variable "enable_log_encryption" {
  description = "Enable KMS encryption for Lambda Insights logs"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for log encryption"
  type        = string
  default     = null
}

# ==============================================================================
# Insights Configuration
# ==============================================================================

variable "insights_log_level" {
  description = "Lambda Insights log level (info, warn, error)"
  type        = string
  default     = "info"
  validation {
    condition     = contains(["info", "warn", "error", "debug"], var.insights_log_level)
    error_message = "Insights log level must be one of: info, warn, error, debug."
  }
}

# ==============================================================================
# Alarm Configuration
# ==============================================================================

variable "enable_lambda_alarms" {
  description = "Enable CloudWatch alarms for Lambda metrics"
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarms trigger"
  type        = list(string)
  default     = []
}

variable "duration_threshold_ms" {
  description = "Duration threshold in milliseconds to trigger alarm"
  type        = number
  default     = 10000
  validation {
    condition     = var.duration_threshold_ms > 0
    error_message = "Duration threshold must be greater than 0."
  }
}

variable "memory_utilization_threshold" {
  description = "Memory utilization threshold percentage to trigger alarm"
  type        = number
  default     = 80
  validation {
    condition     = var.memory_utilization_threshold >= 0 && var.memory_utilization_threshold <= 100
    error_message = "Memory utilization threshold must be between 0 and 100."
  }
}

variable "error_threshold" {
  description = "Number of errors to trigger alarm"
  type        = number
  default     = 10
  validation {
    condition     = var.error_threshold > 0
    error_message = "Error threshold must be greater than 0."
  }
}

variable "throttle_threshold" {
  description = "Number of throttles to trigger alarm"
  type        = number
  default     = 5
  validation {
    condition     = var.throttle_threshold > 0
    error_message = "Throttle threshold must be greater than 0."
  }
}

variable "monitor_cold_starts" {
  description = "Enable monitoring and alerting for cold starts"
  type        = bool
  default     = true
}

variable "cold_start_threshold_ms" {
  description = "Cold start duration threshold in milliseconds"
  type        = number
  default     = 5000
  validation {
    condition     = var.cold_start_threshold_ms > 0
    error_message = "Cold start threshold must be greater than 0."
  }
}

# ==============================================================================
# Dashboard Configuration
# ==============================================================================

variable "enable_lambda_dashboard" {
  description = "Create CloudWatch dashboard for Lambda Insights"
  type        = bool
  default     = true
}
