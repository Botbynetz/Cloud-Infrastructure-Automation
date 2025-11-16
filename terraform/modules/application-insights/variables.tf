# ==============================================================================
# Application Insights Module Variables
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
# Application Configuration
# ==============================================================================

variable "application_namespace" {
  description = "CloudWatch namespace for application metrics"
  type        = string
  default     = "CustomApplication"
}

variable "application_log_group_name" {
  description = "CloudWatch log group name for application logs"
  type        = string
}

# ==============================================================================
# Anomaly Detection Configuration
# ==============================================================================

variable "enable_anomaly_detection" {
  description = "Enable anomaly detection for application metrics"
  type        = bool
  default     = true
}

variable "anomaly_detection_band" {
  description = "Standard deviations for anomaly detection band (1-10)"
  type        = number
  default     = 2
  validation {
    condition     = var.anomaly_detection_band >= 1 && var.anomaly_detection_band <= 10
    error_message = "Anomaly detection band must be between 1 and 10."
  }
}

variable "enable_database_monitoring" {
  description = "Enable database connection monitoring"
  type        = bool
  default     = true
}

# ==============================================================================
# Custom Metrics Configuration
# ==============================================================================

variable "enable_business_metrics" {
  description = "Enable business transaction metrics"
  type        = bool
  default     = true
}

variable "business_transaction_pattern" {
  description = "Log pattern for business transactions"
  type        = string
  default     = "[time, request_id, event=TRANSACTION, transaction_type=transactionType, ...]"
}

variable "enable_performance_metrics" {
  description = "Enable detailed performance metrics"
  type        = bool
  default     = true
}

variable "enable_cache_metrics" {
  description = "Enable cache hit/miss metrics"
  type        = bool
  default     = true
}

# ==============================================================================
# Contributor Insights Configuration
# ==============================================================================

variable "enable_contributor_insights" {
  description = "Enable CloudWatch Contributor Insights"
  type        = bool
  default     = true
}

# ==============================================================================
# Synthetics Configuration
# ==============================================================================

variable "enable_synthetics" {
  description = "Enable CloudWatch Synthetics canary monitoring"
  type        = bool
  default     = false
}

variable "synthetics_bucket_name" {
  description = "S3 bucket name for Synthetics artifacts"
  type        = string
  default     = ""
}

variable "synthetics_schedule" {
  description = "Schedule expression for Synthetics canary (e.g., rate(5 minutes))"
  type        = string
  default     = "rate(5 minutes)"
}

variable "enable_xray_tracing" {
  description = "Enable X-Ray tracing for Synthetics canary"
  type        = bool
  default     = true
}

# ==============================================================================
# Alarm Configuration
# ==============================================================================

variable "alarm_actions" {
  description = "List of ARNs to notify when alarms trigger"
  type        = list(string)
  default     = []
}

# ==============================================================================
# Dashboard Configuration
# ==============================================================================

variable "enable_insights_dashboard" {
  description = "Create CloudWatch dashboard for Application Insights"
  type        = bool
  default     = true
}

# ==============================================================================
# Query Configuration
# ==============================================================================

variable "slow_transaction_threshold_ms" {
  description = "Threshold in milliseconds to identify slow transactions"
  type        = number
  default     = 1000
  validation {
    condition     = var.slow_transaction_threshold_ms > 0
    error_message = "Slow transaction threshold must be greater than 0."
  }
}
