# FinOps Module Variables

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for FinOps resources"
  type        = string
  default     = "us-east-1"
}

variable "cur_region" {
  description = "AWS region for Cost and Usage Report (must be us-east-1)"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = var.cur_region == "us-east-1"
    error_message = "Cost and Usage Reports must be delivered to us-east-1 region."
  }
}

# ============================================================
# Cost Data Configuration
# ============================================================

variable "cost_data_retention_days" {
  description = "Number of days to retain cost data in S3 before deletion"
  type        = number
  default     = 2555 # 7 years for compliance

  validation {
    condition     = var.cost_data_retention_days >= 365
    error_message = "Cost data must be retained for at least 1 year."
  }
}

# ============================================================
# Multi-Account Tracking
# ============================================================

variable "enable_multi_account_tracking" {
  description = "Enable cost tracking across multiple AWS accounts"
  type        = bool
  default     = false
}

# ============================================================
# Cost Anomaly Detection
# ============================================================

variable "anomaly_alert_frequency" {
  description = "Frequency of anomaly alerts (DAILY or IMMEDIATE)"
  type        = string
  default     = "DAILY"

  validation {
    condition     = contains(["DAILY", "IMMEDIATE"], var.anomaly_alert_frequency)
    error_message = "Anomaly alert frequency must be DAILY or IMMEDIATE."
  }
}

variable "anomaly_threshold_amount" {
  description = "Minimum cost impact (USD) to trigger anomaly alert"
  type        = number
  default     = 100

  validation {
    condition     = var.anomaly_threshold_amount > 0
    error_message = "Anomaly threshold must be greater than 0."
  }
}

variable "anomaly_threshold_percentage" {
  description = "Percentage threshold for cost anomaly detection"
  type        = number
  default     = 20

  validation {
    condition     = var.anomaly_threshold_percentage > 0 && var.anomaly_threshold_percentage <= 100
    error_message = "Anomaly threshold percentage must be between 1 and 100."
  }
}

# ============================================================
# Budget Configuration
# ============================================================

variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD (0 to disable budget alerts)"
  type        = number
  default     = 5000

  validation {
    condition     = var.monthly_budget_limit >= 0
    error_message = "Monthly budget limit must be non-negative."
  }
}

# ============================================================
# Rightsizing Configuration
# ============================================================

variable "rightsizing_cpu_threshold_low" {
  description = "CPU utilization percentage below which instances are considered under-utilized"
  type        = number
  default     = 20

  validation {
    condition     = var.rightsizing_cpu_threshold_low > 0 && var.rightsizing_cpu_threshold_low < 100
    error_message = "CPU threshold low must be between 1 and 99."
  }
}

variable "rightsizing_cpu_threshold_high" {
  description = "CPU utilization percentage above which instances are considered over-utilized"
  type        = number
  default     = 80

  validation {
    condition     = var.rightsizing_cpu_threshold_high > 0 && var.rightsizing_cpu_threshold_high <= 100
    error_message = "CPU threshold high must be between 1 and 100."
  }
}

variable "auto_apply_rightsizing" {
  description = "Automatically apply rightsizing recommendations (use with caution)"
  type        = bool
  default     = false
}

variable "rightsizing_dry_run" {
  description = "Enable dry-run mode for rightsizing (no actual changes)"
  type        = bool
  default     = true
}

# ============================================================
# Waste Elimination Configuration
# ============================================================

variable "waste_threshold_usd" {
  description = "Minimum monthly cost (USD) for a resource to be considered waste"
  type        = number
  default     = 5

  validation {
    condition     = var.waste_threshold_usd > 0
    error_message = "Waste threshold must be greater than 0."
  }
}

variable "unused_resource_days" {
  description = "Number of days a resource must be unused before considered waste"
  type        = number
  default     = 30

  validation {
    condition     = var.unused_resource_days >= 7
    error_message = "Unused resource days must be at least 7 days."
  }
}

variable "auto_delete_waste" {
  description = "Automatically delete detected waste resources (use with extreme caution)"
  type        = bool
  default     = false
}

variable "waste_cleanup_dry_run" {
  description = "Enable dry-run mode for waste cleanup (no actual deletions)"
  type        = bool
  default     = true
}

# ============================================================
# Notification Configuration
# ============================================================

variable "finops_notification_emails" {
  description = "List of email addresses to receive FinOps notifications"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for email in var.finops_notification_emails : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All email addresses must be valid."
  }
}

variable "alarm_actions" {
  description = "List of ARNs to notify when CloudWatch alarms trigger (SNS topics, etc.)"
  type        = list(string)
  default     = null
}

# ============================================================
# Tags
# ============================================================

variable "tags" {
  description = "Additional tags for all FinOps resources"
  type        = map(string)
  default     = {}
}
