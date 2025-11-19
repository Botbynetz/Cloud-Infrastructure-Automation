variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod, dr)"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

# ============================================
# Rotation Features
# ============================================

variable "enable_rds_rotation" {
  description = "Enable automatic RDS password rotation"
  type        = bool
  default     = true
}

variable "enable_api_key_rotation" {
  description = "Enable automatic API key rotation"
  type        = bool
  default     = true
}

variable "enable_rotation_alerts" {
  description = "Enable SNS alerts for rotation failures"
  type        = bool
  default     = true
}

# ============================================
# KMS Configuration
# ============================================

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting secrets"
  type        = string
}

# ============================================
# Lambda Configuration
# ============================================

variable "lambda_subnet_ids" {
  description = "Subnet IDs for Lambda functions (must have RDS access)"
  type        = list(string)
  default     = []
}

variable "lambda_security_group_ids" {
  description = "Security group IDs for Lambda functions"
  type        = list(string)
  default     = []
}

# ============================================
# API Configuration
# ============================================

variable "api_endpoint" {
  description = "API endpoint for key rotation operations"
  type        = string
  default     = ""
}

# ============================================
# Alert Configuration
# ============================================

variable "alert_email_addresses" {
  description = "Email addresses to receive rotation failure alerts"
  type        = list(string)
  default     = []
}
