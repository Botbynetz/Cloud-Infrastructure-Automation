# =============================================================================
# Zero Trust Security Architecture - Outputs
# =============================================================================

# Security Group IDs
output "public_tier_sg_id" {
  description = "Security group ID for public tier (load balancers)"
  value       = aws_security_group.public_tier.id
}

output "web_tier_sg_id" {
  description = "Security group ID for web tier (application servers)"
  value       = aws_security_group.web_tier.id
}

output "app_tier_sg_id" {
  description = "Security group ID for app tier (business logic)"
  value       = aws_security_group.app_tier.id
}

output "data_tier_sg_id" {
  description = "Security group ID for data tier (databases)"
  value       = aws_security_group.data_tier.id
}

output "admin_tier_sg_id" {
  description = "Security group ID for admin tier (JIT access)"
  value       = aws_security_group.admin_tier.id
}

# IAM Identity Center Resources
output "read_only_permission_set_arn" {
  description = "ARN of the read-only permission set"
  value       = var.enable_identity_center ? aws_ssoadmin_permission_set.read_only[0].arn : null
}

output "power_user_permission_set_arn" {
  description = "ARN of the power user permission set"
  value       = var.enable_identity_center ? aws_ssoadmin_permission_set.power_user[0].arn : null
}

output "admin_permission_set_arn" {
  description = "ARN of the admin permission set"
  value       = var.enable_identity_center ? aws_ssoadmin_permission_set.admin[0].arn : null
}

# JIT Access Resources
output "jit_access_lambda_arn" {
  description = "ARN of the JIT access Lambda function"
  value       = aws_lambda_function.jit_access.arn
}

output "jit_access_lambda_name" {
  description = "Name of the JIT access Lambda function"
  value       = aws_lambda_function.jit_access.function_name
}

output "jit_access_log_table" {
  description = "DynamoDB table name for JIT access audit log"
  value       = aws_dynamodb_table.jit_access_log.name
}

output "jit_notifications_topic_arn" {
  description = "ARN of SNS topic for JIT access notifications"
  value       = aws_sns_topic.jit_access_notifications.arn
}

# Secrets Rotation Resources
output "secrets_rotation_lambda_arn" {
  description = "ARN of the secrets rotation Lambda function"
  value       = var.enable_secrets_rotation ? aws_lambda_function.rds_password_rotation[0].arn : null
}

output "secrets_rotation_notifications_topic_arn" {
  description = "ARN of SNS topic for secrets rotation notifications"
  value       = var.enable_secrets_rotation ? aws_sns_topic.secrets_rotation_notifications[0].arn : null
}

# VPC Endpoints
output "vpc_endpoint_s3_id" {
  description = "ID of the S3 VPC endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "vpc_endpoint_dynamodb_id" {
  description = "ID of the DynamoDB VPC endpoint"
  value       = aws_vpc_endpoint.dynamodb.id
}

output "vpc_endpoint_secretsmanager_id" {
  description = "ID of the Secrets Manager VPC endpoint"
  value       = aws_vpc_endpoint.secretsmanager.id
}

output "vpc_endpoint_ssm_id" {
  description = "ID of the SSM VPC endpoint"
  value       = aws_vpc_endpoint.ssm.id
}

# Monitoring
output "cloudwatch_dashboard_name" {
  description = "Name of the Zero Trust CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.zero_trust.dashboard_name
}

output "cloudwatch_dashboard_url" {
  description = "URL to access the Zero Trust CloudWatch dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.zero_trust.dashboard_name}"
}

# Summary
output "zero_trust_summary" {
  description = "Summary of Zero Trust configuration"
  value = {
    security_groups = {
      public_tier = aws_security_group.public_tier.id
      web_tier    = aws_security_group.web_tier.id
      app_tier    = aws_security_group.app_tier.id
      data_tier   = aws_security_group.data_tier.id
      admin_tier  = aws_security_group.admin_tier.id
    }
    jit_access = {
      lambda_function   = aws_lambda_function.jit_access.function_name
      audit_table       = aws_dynamodb_table.jit_access_log.name
      duration_minutes  = var.jit_access_duration_minutes
      allowed_ports     = var.jit_allowed_ports
    }
    secrets_rotation = {
      enabled          = var.enable_secrets_rotation
      lambda_function  = var.enable_secrets_rotation ? aws_lambda_function.rds_password_rotation[0].function_name : null
      rotation_period  = "30 days"
    }
    identity_center = {
      enabled             = var.enable_identity_center
      read_only_duration  = var.read_only_session_duration
      power_user_duration = var.power_user_session_duration
      admin_duration      = var.admin_session_duration
    }
    vpc_endpoints = [
      "S3 (Gateway)",
      "DynamoDB (Gateway)",
      "Secrets Manager (Interface)",
      "SSM (Interface)",
      "EC2 Messages (Interface)",
      "SSM Messages (Interface)"
    ]
    monitoring = {
      dashboard_name = aws_cloudwatch_dashboard.zero_trust.dashboard_name
      alarms = [
        "JIT High Usage",
        "JIT Errors",
        var.enable_secrets_rotation ? "Secrets Rotation Failure" : null
      ]
    }
  }
}
