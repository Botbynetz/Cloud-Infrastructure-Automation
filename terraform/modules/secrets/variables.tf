variable "secrets" {
  description = "Map of secrets to create in AWS Secrets Manager"
  type = map(object({
    description      = string
    secret_string    = string
    rotation_enabled = optional(bool, false)
    rotation_days    = optional(number, 30)
    recovery_window  = optional(number, 30)
    tags             = optional(map(string), {})
  }))
  
  validation {
    condition     = alltrue([for k, v in var.secrets : v.recovery_window >= 7 && v.recovery_window <= 30])
    error_message = "Recovery window must be between 7 and 30 days."
  }
  
  validation {
    condition     = alltrue([for k, v in var.secrets : !v.rotation_enabled || (v.rotation_days >= 1 && v.rotation_days <= 365)])
    error_message = "Rotation days must be between 1 and 365 when rotation is enabled."
  }
}

variable "kms_key_id" {
  description = "KMS key ID to use for encrypting secrets. If not provided, AWS managed key will be used."
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags to apply to all secrets"
  type        = map(string)
  default     = {}
}

variable "enable_replication" {
  description = "Enable secret replication to another region"
  type        = bool
  default     = false
}

variable "replica_region" {
  description = "Region to replicate secrets to"
  type        = string
  default     = ""
}

variable "rotation_lambda_arn" {
  description = "ARN of Lambda function to use for secret rotation"
  type        = string
  default     = ""
}

# ============================================
# HashiCorp Vault Configuration
# ============================================

variable "enable_vault_integration" {
  description = "Enable HashiCorp Vault integration for secrets management"
  type        = bool
  default     = false
}

variable "vault_address" {
  description = "HashiCorp Vault server address"
  type        = string
  default     = ""
}

variable "vault_namespace" {
  description = "Vault namespace (for Vault Enterprise)"
  type        = string
  default     = ""
}
