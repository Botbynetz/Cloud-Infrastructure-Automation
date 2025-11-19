# Outputs for Multi-Cloud KMS Module

# ============================================
# AWS KMS Outputs
# ============================================

output "aws_kms_primary_key_id" {
  description = "AWS KMS primary key ID"
  value       = var.enable_aws_kms ? aws_kms_key.primary[0].id : null
}

output "aws_kms_primary_key_arn" {
  description = "AWS KMS primary key ARN"
  value       = var.enable_aws_kms ? aws_kms_key.primary[0].arn : null
}

output "aws_kms_terraform_state_key_id" {
  description = "AWS KMS Terraform state key ID"
  value       = var.enable_aws_kms ? aws_kms_key.terraform_state[0].id : null
}

output "aws_kms_terraform_state_key_arn" {
  description = "AWS KMS Terraform state key ARN"
  value       = var.enable_aws_kms ? aws_kms_key.terraform_state[0].arn : null
}

output "aws_kms_secrets_key_id" {
  description = "AWS KMS secrets key ID"
  value       = var.enable_aws_kms ? aws_kms_key.secrets[0].id : null
}

output "aws_kms_secrets_key_arn" {
  description = "AWS KMS secrets key ARN"
  value       = var.enable_aws_kms ? aws_kms_key.secrets[0].arn : null
}

output "aws_kms_ebs_key_id" {
  description = "AWS KMS EBS key ID"
  value       = var.enable_aws_kms ? aws_kms_key.ebs[0].id : null
}

output "aws_kms_ebs_key_arn" {
  description = "AWS KMS EBS key ARN"
  value       = var.enable_aws_kms ? aws_kms_key.ebs[0].arn : null
}

output "aws_kms_rds_key_id" {
  description = "AWS KMS RDS key ID"
  value       = var.enable_aws_kms ? aws_kms_key.rds[0].id : null
}

output "aws_kms_rds_key_arn" {
  description = "AWS KMS RDS key ARN"
  value       = var.enable_aws_kms ? aws_kms_key.rds[0].arn : null
}

output "aws_kms_s3_key_id" {
  description = "AWS KMS S3 key ID"
  value       = var.enable_aws_kms ? aws_kms_key.s3[0].id : null
}

output "aws_kms_s3_key_arn" {
  description = "AWS KMS S3 key ARN"
  value       = var.enable_aws_kms ? aws_kms_key.s3[0].arn : null
}

output "aws_kms_key_aliases" {
  description = "Map of AWS KMS key aliases"
  value = var.enable_aws_kms ? {
    primary         = aws_kms_alias.primary[0].name
    terraform_state = aws_kms_alias.terraform_state[0].name
    secrets         = aws_kms_alias.secrets[0].name
    ebs             = aws_kms_alias.ebs[0].name
    rds             = aws_kms_alias.rds[0].name
    s3              = aws_kms_alias.s3[0].name
  } : null
}

# ============================================
# GCP KMS Outputs
# ============================================

output "gcp_key_ring_id" {
  description = "GCP KMS key ring ID"
  value       = var.enable_gcp_kms ? google_kms_key_ring.main[0].id : null
}

output "gcp_key_ring_name" {
  description = "GCP KMS key ring name"
  value       = var.enable_gcp_kms ? google_kms_key_ring.main[0].name : null
}

output "gcp_crypto_key_primary_id" {
  description = "GCP primary crypto key ID"
  value       = var.enable_gcp_kms ? google_kms_crypto_key.primary[0].id : null
}

output "gcp_crypto_key_terraform_state_id" {
  description = "GCP Terraform state crypto key ID"
  value       = var.enable_gcp_kms ? google_kms_crypto_key.terraform_state[0].id : null
}

output "gcp_crypto_key_secrets_id" {
  description = "GCP secrets crypto key ID"
  value       = var.enable_gcp_kms ? google_kms_crypto_key.secrets[0].id : null
}

# ============================================
# Azure Key Vault Outputs
# ============================================

output "azure_key_vault_id" {
  description = "Azure Key Vault ID"
  value       = var.enable_azure_keyvault ? azurerm_key_vault.main[0].id : null
}

output "azure_key_vault_uri" {
  description = "Azure Key Vault URI"
  value       = var.enable_azure_keyvault ? azurerm_key_vault.main[0].vault_uri : null
}

output "azure_key_vault_name" {
  description = "Azure Key Vault name"
  value       = var.enable_azure_keyvault ? azurerm_key_vault.main[0].name : null
}

output "azure_key_id" {
  description = "Azure primary key ID"
  value       = var.enable_azure_keyvault ? azurerm_key_vault_key.primary[0].id : null
}

# ============================================
# Summary Outputs
# ============================================

output "kms_summary" {
  description = "Summary of created KMS resources"
  value = {
    aws_enabled   = var.enable_aws_kms
    gcp_enabled   = var.enable_gcp_kms
    azure_enabled = var.enable_azure_keyvault
    
    aws_keys_count   = var.enable_aws_kms ? 6 : 0
    gcp_keys_count   = var.enable_gcp_kms ? 3 : 0
    azure_keys_count = var.enable_azure_keyvault ? 1 : 0
  }
}
