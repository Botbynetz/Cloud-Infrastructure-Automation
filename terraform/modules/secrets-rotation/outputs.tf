output "rds_rotation_lambda_arn" {
  description = "ARN of RDS password rotation Lambda function"
  value       = var.enable_rds_rotation ? aws_lambda_function.rotate_rds_password[0].arn : null
}

output "api_key_rotation_lambda_arn" {
  description = "ARN of API key rotation Lambda function"
  value       = var.enable_api_key_rotation ? aws_lambda_function.rotate_api_keys[0].arn : null
}

output "rotation_alerts_topic_arn" {
  description = "ARN of SNS topic for rotation alerts"
  value       = var.enable_rotation_alerts ? aws_sns_topic.rotation_alerts[0].arn : null
}

output "rotation_schedule" {
  description = "Rotation schedules"
  value = {
    rds_password = var.enable_rds_rotation ? "Every 30 days" : "Disabled"
    api_keys     = var.enable_api_key_rotation ? "Every 90 days" : "Disabled"
  }
}
