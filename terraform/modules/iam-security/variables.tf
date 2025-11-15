variable "role_name" {
  description = "Name of the IAM role"
  type        = string
}

variable "role_type" {
  description = "Type of role: ec2, lambda, federated, or user"
  type        = string
  default     = "ec2"
  
  validation {
    condition     = contains(["ec2", "lambda", "federated", "user"], var.role_type)
    error_message = "Role type must be one of: ec2, lambda, federated, user"
  }
}

variable "permissions" {
  description = "List of IAM actions allowed for this role"
  type        = list(string)
  default     = []
}

variable "resource_arns" {
  description = "List of resource ARNs that permissions apply to"
  type        = list(string)
  default     = ["*"]
}

variable "require_mfa" {
  description = "Require MFA for assuming this role"
  type        = bool
  default     = false
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds (1 hour to 12 hours)"
  type        = number
  default     = 3600
  
  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "Session duration must be between 3600 (1 hour) and 43200 (12 hours) seconds"
  }
}

variable "enable_session_manager" {
  description = "Enable AWS Systems Manager Session Manager access"
  type        = bool
  default     = false
}

variable "permission_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the role"
  type        = string
  default     = null
}

variable "federated_principal" {
  description = "ARN of the federated identity provider (for federated roles)"
  type        = string
  default     = ""
}

variable "trusted_accounts" {
  description = "List of AWS account IDs that can assume this role"
  type        = list(string)
  default     = []
}

variable "condition" {
  description = "Condition block for assume role policy"
  type = object({
    test     = string
    variable = string
    values   = list(string)
  })
  default = null
}

variable "enable_cloudtrail_logging" {
  description = "Enable CloudTrail logging for role usage"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to IAM resources"
  type        = map(string)
  default     = {}
}

variable "mfa_age_limit" {
  description = "Maximum age of MFA token in seconds"
  type        = number
  default     = 3600
}

variable "compliance_level" {
  description = "Compliance level: standard, pci-dss, hipaa, or soc2"
  type        = string
  default     = "standard"
  
  validation {
    condition     = contains(["standard", "pci-dss", "hipaa", "soc2"], var.compliance_level)
    error_message = "Compliance level must be: standard, pci-dss, hipaa, or soc2"
  }
}

variable "role_template" {
  description = "Pre-configured role template: webapp, database, monitoring, or custom"
  type        = string
  default     = "custom"
}

variable "custom_bucket_arns" {
  description = "Custom S3 bucket ARNs for role templates"
  type        = list(string)
  default     = []
}
