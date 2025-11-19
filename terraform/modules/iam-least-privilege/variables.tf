variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod, dr)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod", "dr"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, dr"
  }
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

# ============================================
# Role Creation Flags
# ============================================

variable "create_dev_role" {
  description = "Create development Terraform role"
  type        = bool
  default     = false
}

variable "create_prod_role" {
  description = "Create production Terraform role"
  type        = bool
  default     = false
}

variable "create_cicd_role" {
  description = "Create CI/CD automation role"
  type        = bool
  default     = false
}

variable "create_readonly_role" {
  description = "Create read-only audit role"
  type        = bool
  default     = false
}

# ============================================
# Assume Role Configuration
# ============================================

variable "allowed_assume_role_principals" {
  description = "List of AWS principal ARNs allowed to assume these roles"
  type        = list(string)
  default     = []
}

variable "external_id" {
  description = "External ID for assume role (security best practice)"
  type        = string
  sensitive   = true
}

variable "enable_github_oidc" {
  description = "Enable GitHub Actions OIDC provider for CI/CD"
  type        = bool
  default     = false
}

variable "github_oidc_provider_arn" {
  description = "ARN of GitHub OIDC identity provider"
  type        = string
  default     = ""
}

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
  default     = ""
}

# ============================================
# KMS Keys (per environment)
# ============================================

variable "dev_kms_key_arn" {
  description = "KMS key ARN for development environment"
  type        = string
  default     = ""
}

variable "prod_kms_key_arn" {
  description = "KMS key ARN for production environment"
  type        = string
  default     = ""
}

# ============================================
# Security Configuration
# ============================================

variable "require_mfa_for_prod" {
  description = "Require MFA for production operations"
  type        = bool
  default     = true
}

variable "terraform_state_bucket" {
  description = "S3 bucket name for Terraform state"
  type        = string
}

variable "terraform_lock_table" {
  description = "DynamoDB table name for Terraform state locks"
  type        = string
}
