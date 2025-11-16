# ==============================================================================
# AWS X-Ray Module Variables
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

variable "service_name" {
  description = "Name of the service to trace"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# Sampling Configuration
# ==============================================================================

variable "default_sampling_rate" {
  description = "Default sampling rate for X-Ray (0.0 to 1.0)"
  type        = number
  default     = 0.05
  validation {
    condition     = var.default_sampling_rate >= 0 && var.default_sampling_rate <= 1
    error_message = "Sampling rate must be between 0 and 1."
  }
}

variable "default_reservoir_size" {
  description = "Number of requests per second to instrument regardless of sampling rate"
  type        = number
  default     = 1
}

variable "enable_high_priority_sampling" {
  description = "Enable high priority sampling rule for critical endpoints"
  type        = bool
  default     = true
}

variable "high_priority_sampling_rate" {
  description = "Sampling rate for high priority endpoints"
  type        = number
  default     = 0.5
  validation {
    condition     = var.high_priority_sampling_rate >= 0 && var.high_priority_sampling_rate <= 1
    error_message = "High priority sampling rate must be between 0 and 1."
  }
}

variable "high_priority_reservoir_size" {
  description = "Reservoir size for high priority sampling"
  type        = number
  default     = 5
}

variable "high_priority_url_pattern" {
  description = "URL pattern for high priority sampling (e.g., /api/critical/*)"
  type        = string
  default     = "/api/critical/*"
}

variable "enable_api_sampling" {
  description = "Enable dedicated sampling rule for API endpoints"
  type        = bool
  default     = true
}

variable "api_sampling_rate" {
  description = "Sampling rate for API endpoints"
  type        = number
  default     = 0.1
  validation {
    condition     = var.api_sampling_rate >= 0 && var.api_sampling_rate <= 1
    error_message = "API sampling rate must be between 0 and 1."
  }
}

variable "api_reservoir_size" {
  description = "Reservoir size for API sampling"
  type        = number
  default     = 2
}

variable "enable_error_sampling" {
  description = "Enable 100% sampling for error traces"
  type        = bool
  default     = true
}

variable "enable_slow_request_sampling" {
  description = "Enable 100% sampling for slow requests"
  type        = bool
  default     = true
}

# ==============================================================================
# X-Ray Groups Configuration
# ==============================================================================

variable "enable_insights" {
  description = "Enable X-Ray Insights for anomaly detection"
  type        = bool
  default     = true
}

variable "enable_insights_notifications" {
  description = "Enable notifications for X-Ray Insights"
  type        = bool
  default     = true
}

variable "enable_error_group" {
  description = "Create dedicated X-Ray group for error traces"
  type        = bool
  default     = true
}

variable "enable_slow_request_group" {
  description = "Create dedicated X-Ray group for slow requests"
  type        = bool
  default     = true
}

variable "slow_request_threshold" {
  description = "Duration threshold in seconds to classify request as slow"
  type        = number
  default     = 3
  validation {
    condition     = var.slow_request_threshold > 0
    error_message = "Slow request threshold must be greater than 0."
  }
}

# ==============================================================================
# IAM Configuration
# ==============================================================================

variable "create_xray_role" {
  description = "Create IAM role for X-Ray daemon"
  type        = bool
  default     = true
}

variable "create_instance_profile" {
  description = "Create instance profile for EC2 instances"
  type        = bool
  default     = true
}

# ==============================================================================
# Alarm Configuration
# ==============================================================================

variable "enable_xray_alarms" {
  description = "Enable CloudWatch alarms for X-Ray metrics"
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarms trigger"
  type        = list(string)
  default     = []
}

variable "error_rate_threshold" {
  description = "Error rate threshold percentage to trigger alarm"
  type        = number
  default     = 5
  validation {
    condition     = var.error_rate_threshold >= 0 && var.error_rate_threshold <= 100
    error_message = "Error rate threshold must be between 0 and 100."
  }
}

variable "latency_threshold" {
  description = "Average latency threshold in milliseconds to trigger alarm"
  type        = number
  default     = 2000
  validation {
    condition     = var.latency_threshold > 0
    error_message = "Latency threshold must be greater than 0."
  }
}

variable "throttle_rate_threshold" {
  description = "Throttle rate threshold percentage to trigger alarm"
  type        = number
  default     = 1
  validation {
    condition     = var.throttle_rate_threshold >= 0 && var.throttle_rate_threshold <= 100
    error_message = "Throttle rate threshold must be between 0 and 100."
  }
}

# ==============================================================================
# Encryption Configuration
# ==============================================================================

variable "enable_encryption" {
  description = "Enable encryption for X-Ray data"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for X-Ray encryption (leave empty for default encryption)"
  type        = string
  default     = ""
}

# ==============================================================================
# Lambda Layer Configuration
# ==============================================================================

variable "create_lambda_layer" {
  description = "Create Lambda layer with X-Ray SDK"
  type        = bool
  default     = false
}

# ==============================================================================
# Dashboard Configuration
# ==============================================================================

variable "enable_xray_dashboard" {
  description = "Create CloudWatch dashboard for X-Ray metrics"
  type        = bool
  default     = true
}

variable "application_log_group_name" {
  description = "CloudWatch log group name for application logs"
  type        = string
  default     = ""
}

# ==============================================================================
# Advanced Configuration
# ==============================================================================

variable "custom_sampling_rules" {
  description = "List of custom sampling rules"
  type = list(object({
    rule_name      = string
    priority       = number
    reservoir_size = number
    fixed_rate     = number
    url_path       = string
    http_method    = string
    service_name   = string
  }))
  default = []
}

variable "enable_service_graph" {
  description = "Enable service graph generation"
  type        = bool
  default     = true
}

variable "trace_retention_days" {
  description = "Number of days to retain X-Ray traces (not directly configurable, informational)"
  type        = number
  default     = 30
}
