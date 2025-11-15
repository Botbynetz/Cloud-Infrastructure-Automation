# ==============================================================================
# Centralized Logging Module Variables
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
# Log Group References (from monitoring module)
# ==============================================================================

variable "application_log_group_name" {
  description = "Application log group name"
  type        = string
}

variable "infrastructure_log_group_name" {
  description = "Infrastructure log group name"
  type        = string
}

variable "security_log_group_name" {
  description = "Security log group name"
  type        = string
}

variable "audit_log_group_name" {
  description = "Audit log group name"
  type        = string
}

# ==============================================================================
# Encryption Configuration
# ==============================================================================

variable "enable_log_encryption" {
  description = "Enable KMS encryption for logs"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for log encryption"
  type        = string
  default     = ""
}

# ==============================================================================
# S3 Log Export Configuration
# ==============================================================================

variable "enable_log_export" {
  description = "Enable CloudWatch Logs export to S3"
  type        = bool
  default     = true
}

variable "s3_transition_days" {
  description = "Days before transitioning logs to Glacier"
  type        = number
  default     = 90
}

variable "s3_deep_archive_days" {
  description = "Days before transitioning logs to Deep Archive"
  type        = number
  default     = 180
}

variable "s3_expiration_days" {
  description = "Days before deleting logs from S3"
  type        = number
  default     = 2555  # 7 years for compliance
}

variable "enable_scheduled_export" {
  description = "Enable scheduled export of logs to S3"
  type        = bool
  default     = true
}

variable "export_schedule_expression" {
  description = "CloudWatch Events schedule expression for log export"
  type        = string
  default     = "cron(0 2 * * ? *)"  # Daily at 2 AM UTC
}

# ==============================================================================
# Kinesis Streaming Configuration
# ==============================================================================

variable "enable_kinesis_streaming" {
  description = "Enable real-time log streaming to Kinesis"
  type        = bool
  default     = false
}

variable "kinesis_shard_count" {
  description = "Number of Kinesis shards"
  type        = number
  default     = 1
}

variable "kinesis_retention_hours" {
  description = "Kinesis data retention period in hours"
  type        = number
  default     = 24
  
  validation {
    condition     = var.kinesis_retention_hours >= 24 && var.kinesis_retention_hours <= 8760
    error_message = "Kinesis retention must be between 24 and 8760 hours."
  }
}

variable "kinesis_stream_mode" {
  description = "Kinesis stream mode (PROVISIONED or ON_DEMAND)"
  type        = string
  default     = "PROVISIONED"
  
  validation {
    condition     = contains(["PROVISIONED", "ON_DEMAND"], var.kinesis_stream_mode)
    error_message = "Stream mode must be PROVISIONED or ON_DEMAND."
  }
}

variable "kinesis_filter_pattern" {
  description = "CloudWatch Logs filter pattern for Kinesis subscription"
  type        = string
  default     = ""  # Empty string matches all log events
}

variable "stream_application_logs" {
  description = "Stream application logs to Kinesis"
  type        = bool
  default     = true
}

variable "stream_infrastructure_logs" {
  description = "Stream infrastructure logs to Kinesis"
  type        = bool
  default     = false
}

variable "stream_security_logs" {
  description = "Stream security logs to Kinesis"
  type        = bool
  default     = true
}

# ==============================================================================
# Cross-Account Logging Configuration
# ==============================================================================

variable "enable_cross_account_logging" {
  description = "Enable cross-account log aggregation"
  type        = bool
  default     = false
}

variable "cross_account_ids" {
  description = "List of AWS account IDs allowed to send logs"
  type        = list(string)
  default     = []
}

# ==============================================================================
# Elasticsearch Integration (Optional)
# ==============================================================================

variable "enable_elasticsearch_integration" {
  description = "Enable Elasticsearch integration for log analytics"
  type        = bool
  default     = false
}

variable "elasticsearch_domain_endpoint" {
  description = "Elasticsearch domain endpoint"
  type        = string
  default     = ""
}

# ==============================================================================
# Advanced Configuration
# ==============================================================================

variable "enable_log_sampling" {
  description = "Enable log sampling to reduce volume"
  type        = bool
  default     = false
}

variable "log_sampling_rate" {
  description = "Percentage of logs to sample (1-100)"
  type        = number
  default     = 10
  
  validation {
    condition     = var.log_sampling_rate >= 1 && var.log_sampling_rate <= 100
    error_message = "Sampling rate must be between 1 and 100."
  }
}
