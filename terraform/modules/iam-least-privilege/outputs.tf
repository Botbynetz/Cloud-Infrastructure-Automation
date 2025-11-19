# ============================================
# IAM Role ARNs
# ============================================

output "terraform_dev_role_arn" {
  description = "ARN of Terraform development role"
  value       = var.create_dev_role ? aws_iam_role.terraform_dev[0].arn : null
}

output "terraform_prod_role_arn" {
  description = "ARN of Terraform production role"
  value       = var.create_prod_role ? aws_iam_role.terraform_prod[0].arn : null
}

output "cicd_role_arn" {
  description = "ARN of CI/CD automation role"
  value       = var.create_cicd_role ? aws_iam_role.cicd[0].arn : null
}

output "readonly_role_arn" {
  description = "ARN of read-only audit role"
  value       = var.create_readonly_role ? aws_iam_role.readonly[0].arn : null
}

# ============================================
# IAM Role Names
# ============================================

output "terraform_dev_role_name" {
  description = "Name of Terraform development role"
  value       = var.create_dev_role ? aws_iam_role.terraform_dev[0].name : null
}

output "terraform_prod_role_name" {
  description = "Name of Terraform production role"
  value       = var.create_prod_role ? aws_iam_role.terraform_prod[0].name : null
}

output "cicd_role_name" {
  description = "Name of CI/CD automation role"
  value       = var.create_cicd_role ? aws_iam_role.cicd[0].name : null
}

output "readonly_role_name" {
  description = "Name of read-only audit role"
  value       = var.create_readonly_role ? aws_iam_role.readonly[0].name : null
}

# ============================================
# Usage Instructions
# ============================================

output "usage_instructions" {
  description = "How to use these IAM roles"
  value = {
    dev_role = var.create_dev_role ? "aws sts assume-role --role-arn ${aws_iam_role.terraform_dev[0].arn} --role-session-name terraform-dev" : "Not created"
    prod_role = var.create_prod_role ? "aws sts assume-role --role-arn ${aws_iam_role.terraform_prod[0].arn} --role-session-name terraform-prod --serial-number arn:aws:iam::ACCOUNT_ID:mfa/USER --token-code MFA_CODE" : "Not created"
    cicd_role = var.create_cicd_role ? "Use in GitHub Actions with OIDC provider" : "Not created"
  }
}

# ============================================
# Security Summary
# ============================================

output "security_summary" {
  description = "Summary of security configurations"
  value = {
    mfa_required_for_prod = var.require_mfa_for_prod
    github_oidc_enabled   = var.enable_github_oidc
    roles_created = {
      dev      = var.create_dev_role
      prod     = var.create_prod_role
      cicd     = var.create_cicd_role
      readonly = var.create_readonly_role
    }
  }
}
