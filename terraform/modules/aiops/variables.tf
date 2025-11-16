# AIOps Module Variables

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, production)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ml_data_retention_days" {
  description = "ML training data retention in days"
  type        = number
  default     = 365
}

variable "kinesis_shard_count" {
  description = "Number of Kinesis shards for metrics stream"
  type        = number
  default     = 2
}

variable "enable_ml_predictions" {
  description = "Enable ML-based predictions"
  type        = bool
  default     = true
}

variable "enable_predictive_scaling" {
  description = "Enable predictive auto-scaling"
  type        = bool
  default     = false
}

variable "enable_auto_remediation" {
  description = "Enable automatic remediation of detected issues"
  type        = bool
  default     = false
}

variable "anomaly_detection_threshold" {
  description = "Threshold for anomaly detection (0.0-1.0)"
  type        = number
  default     = 0.8
}

variable "prediction_window_hours" {
  description = "Prediction window in hours for forecasting"
  type        = number
  default     = 4
}

variable "aiops_notification_emails" {
  description = "Email addresses for AIOps alerts"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
