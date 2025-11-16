# ==============================================================================
# Disaster Recovery Module - Variables
# ==============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# Backup Configuration
# ==============================================================================

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 2555 # 7 years for compliance
  
  validation {
    condition     = var.backup_retention_days >= 30
    error_message = "Backup retention must be at least 30 days."
  }
}

variable "snapshot_retention_days" {
  description = "Number of days to retain RDS snapshots"
  type        = number
  default     = 35
  
  validation {
    condition     = var.snapshot_retention_days >= 7
    error_message = "Snapshot retention must be at least 7 days."
  }
}

variable "kms_key_id" {
  description = "KMS key ID for S3 bucket encryption"
  type        = string
  default     = null
}

variable "sns_kms_key_id" {
  description = "KMS key ID for SNS topic encryption"
  type        = string
  default     = null
}

# ==============================================================================
# RDS Disaster Recovery
# ==============================================================================

variable "enable_rds_dr" {
  description = "Enable RDS disaster recovery (automated snapshot copy)"
  type        = bool
  default     = true
}

# ==============================================================================
# Route53 Failover Configuration
# ==============================================================================

variable "enable_route53_failover" {
  description = "Enable Route53 health checks and failover"
  type        = bool
  default     = true
}

variable "primary_endpoint" {
  description = "Primary region endpoint FQDN for health checks"
  type        = string
  default     = ""
}

variable "secondary_endpoint" {
  description = "Secondary region endpoint FQDN for health checks"
  type        = string
  default     = ""
}

variable "health_check_type" {
  description = "Type of health check (HTTP, HTTPS, TCP)"
  type        = string
  default     = "HTTPS"
  
  validation {
    condition     = contains(["HTTP", "HTTPS", "TCP"], var.health_check_type)
    error_message = "Health check type must be HTTP, HTTPS, or TCP."
  }
}

variable "health_check_path" {
  description = "Path for HTTP(S) health checks"
  type        = string
  default     = "/health"
}

variable "health_check_port" {
  description = "Port for health checks"
  type        = number
  default     = 443
  
  validation {
    condition     = var.health_check_port > 0 && var.health_check_port <= 65535
    error_message = "Port must be between 1 and 65535."
  }
}

variable "health_check_interval" {
  description = "Health check interval in seconds (10 or 30)"
  type        = number
  default     = 30
  
  validation {
    condition     = contains([10, 30], var.health_check_interval)
    error_message = "Health check interval must be 10 or 30 seconds."
  }
}

variable "health_check_failure_threshold" {
  description = "Number of consecutive failures before marking unhealthy"
  type        = number
  default     = 3
  
  validation {
    condition     = var.health_check_failure_threshold >= 1 && var.health_check_failure_threshold <= 10
    error_message = "Failure threshold must be between 1 and 10."
  }
}

# ==============================================================================
# RTO/RPO Configuration
# ==============================================================================

variable "rto_threshold_seconds" {
  description = "Recovery Time Objective threshold in seconds"
  type        = number
  default     = 3600 # 1 hour
  
  validation {
    condition     = var.rto_threshold_seconds >= 60
    error_message = "RTO threshold must be at least 60 seconds."
  }
}

variable "rpo_threshold_seconds" {
  description = "Recovery Point Objective threshold in seconds"
  type        = number
  default     = 900 # 15 minutes
  
  validation {
    condition     = var.rpo_threshold_seconds >= 60
    error_message = "RPO threshold must be at least 60 seconds."
  }
}

variable "replication_lag_threshold" {
  description = "Maximum acceptable replication lag in seconds"
  type        = number
  default     = 900 # 15 minutes
  
  validation {
    condition     = var.replication_lag_threshold >= 60
    error_message = "Replication lag threshold must be at least 60 seconds."
  }
}

# ==============================================================================
# Monitoring & Alerting
# ==============================================================================

variable "alarm_actions" {
  description = "List of ARNs to notify when alarms trigger"
  type        = list(string)
  default     = []
}

variable "dr_notification_emails" {
  description = "List of email addresses for DR notifications"
  type        = list(string)
  default     = []
}

# ==============================================================================
# DR Testing Configuration
# ==============================================================================

variable "enable_automated_dr_testing" {
  description = "Enable automated DR testing (monthly)"
  type        = bool
  default     = false
}

variable "dr_test_schedule" {
  description = "Cron expression for automated DR testing"
  type        = string
  default     = "cron(0 3 1 * ? *)" # First day of every month at 3 AM
}

# ==============================================================================
# Advanced Configuration
# ==============================================================================

variable "enable_cross_account_backup" {
  description = "Enable backup to separate AWS account for additional security"
  type        = bool
  default     = false
}

variable "backup_account_id" {
  description = "AWS account ID for cross-account backups"
  type        = string
  default     = ""
}

variable "enable_backup_vault" {
  description = "Enable AWS Backup vault for centralized backup management"
  type        = bool
  default     = true
}

variable "backup_plan_name" {
  description = "Name for AWS Backup plan"
  type        = string
  default     = "comprehensive-backup-plan"
}

variable "backup_rules" {
  description = "Backup rules configuration"
  type = list(object({
    name              = string
    schedule          = string
    start_window      = number
    completion_window = number
    lifecycle = object({
      cold_storage_after = number
      delete_after       = number
    })
  }))
  default = [
    {
      name              = "daily-backup"
      schedule          = "cron(0 2 * * ? *)"
      start_window      = 60
      completion_window = 120
      lifecycle = {
        cold_storage_after = 30
        delete_after       = 365
      }
    },
    {
      name              = "weekly-backup"
      schedule          = "cron(0 3 ? * 1 *)"
      start_window      = 60
      completion_window = 180
      lifecycle = {
        cold_storage_after = 90
        delete_after       = 730
      }
    },
    {
      name              = "monthly-backup"
      schedule          = "cron(0 4 1 * ? *)"
      start_window      = 60
      completion_window = 240
      lifecycle = {
        cold_storage_after = 180
        delete_after       = 2555
      }
    }
  ]
}

variable "enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery for supported resources"
  type        = bool
  default     = true
}

variable "continuous_backup_retention_days" {
  description = "Days to retain continuous backups (PITR)"
  type        = number
  default     = 35
  
  validation {
    condition     = var.continuous_backup_retention_days >= 1 && var.continuous_backup_retention_days <= 35
    error_message = "Continuous backup retention must be between 1 and 35 days."
  }
}
