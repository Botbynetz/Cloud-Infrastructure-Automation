output "secret_arns" {
  description = "Map of secret names to their ARNs"
  value       = { for k, v in aws_secretsmanager_secret.this : k => v.arn }
}

output "secret_ids" {
  description = "Map of secret names to their IDs"
  value       = { for k, v in aws_secretsmanager_secret.this : k => v.id }
}

output "secret_names" {
  description = "List of all secret names"
  value       = [for secret in aws_secretsmanager_secret.this : secret.name]
}

output "kms_key_id" {
  description = "KMS key ID used for encrypting secrets"
  value       = var.kms_key_id != null ? var.kms_key_id : (length(aws_kms_key.secrets) > 0 ? aws_kms_key.secrets[0].id : null)
}

output "kms_key_arn" {
  description = "KMS key ARN used for encrypting secrets"
  value       = var.kms_key_id != null ? var.kms_key_id : (length(aws_kms_key.secrets) > 0 ? aws_kms_key.secrets[0].arn : null)
}

output "iam_policy_arn" {
  description = "ARN of IAM policy for reading secrets"
  value       = aws_iam_policy.secret_read.arn
}

output "rotation_enabled_secrets" {
  description = "List of secrets with rotation enabled"
  value       = [for k, v in var.secrets : k if v.rotation_enabled]
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for secrets audit logs"
  value       = aws_cloudwatch_log_group.secrets.name
}
