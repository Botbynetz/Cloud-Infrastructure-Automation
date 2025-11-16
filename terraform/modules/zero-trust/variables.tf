# =============================================================================
# Zero Trust Security Architecture - Variables
# =============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for Zero Trust implementation"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for VPC endpoints"
  type        = list(string)
}

variable "private_route_table_ids" {
  description = "List of private route table IDs for gateway endpoints"
  type        = list(string)
}

# =============================================================================
# Identity Center (AWS SSO) Configuration
# =============================================================================

variable "enable_identity_center" {
  description = "Enable AWS IAM Identity Center (SSO) integration"
  type        = bool
  default     = false
}

variable "identity_center_instance_arn" {
  description = "ARN of the IAM Identity Center instance"
  type        = string
  default     = ""
}

variable "read_only_session_duration" {
  description = "Session duration for read-only permission set (ISO-8601 format)"
  type        = string
  default     = "PT8H"  # 8 hours
}

variable "power_user_session_duration" {
  description = "Session duration for power user permission set"
  type        = string
  default     = "PT4H"  # 4 hours
}

variable "admin_session_duration" {
  description = "Session duration for admin permission set"
  type        = string
  default     = "PT2H"  # 2 hours (shorter for security)
}

# =============================================================================
# Network Micro-Segmentation Configuration
# =============================================================================

variable "web_tier_port" {
  description = "Port for web tier communication"
  type        = number
  default     = 8080
}

variable "app_tier_port" {
  description = "Port for app tier communication"
  type        = number
  default     = 8081
}

variable "data_tier_port" {
  description = "Port for data tier communication (e.g., PostgreSQL, MySQL)"
  type        = number
  default     = 5432
  
  validation {
    condition     = var.data_tier_port >= 1024 && var.data_tier_port <= 65535
    error_message = "Data tier port must be between 1024 and 65535."
  }
}

# =============================================================================
# Just-in-Time (JIT) Access Configuration
# =============================================================================

variable "jit_access_duration_minutes" {
  description = "Duration in minutes for JIT access grants"
  type        = number
  default     = 60  # 1 hour
  
  validation {
    condition     = var.jit_access_duration_minutes >= 15 && var.jit_access_duration_minutes <= 480
    error_message = "JIT access duration must be between 15 minutes and 8 hours."
  }
}

variable "jit_allowed_ports" {
  description = "List of ports allowed for JIT access"
  type        = list(number)
  default     = [22, 3389]  # SSH and RDP
}

variable "jit_notification_emails" {
  description = "List of email addresses for JIT access notifications"
  type        = list(string)
  default     = []
}

variable "jit_usage_threshold" {
  description = "Threshold for JIT access usage alarm (requests per 5 minutes)"
  type        = number
  default     = 10
}

# =============================================================================
# Secrets Rotation Configuration
# =============================================================================

variable "enable_secrets_rotation" {
  description = "Enable automated secrets rotation"
  type        = bool
  default     = true
}

variable "secrets_rotation_notification_emails" {
  description = "List of email addresses for secrets rotation notifications"
  type        = list(string)
  default     = []
}

# =============================================================================
# KMS and SNS Configuration
# =============================================================================

variable "sns_kms_key_id" {
  description = "KMS key ID for SNS topic encryption"
  type        = string
  default     = "alias/aws/sns"
}

# =============================================================================
# Monitoring and Alerting
# =============================================================================

variable "alarm_actions" {
  description = "List of ARNs to notify when alarms trigger"
  type        = list(string)
  default     = []
}

# =============================================================================
# Tags
# =============================================================================

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
