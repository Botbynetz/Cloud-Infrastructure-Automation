# ==============================================================================
# Centralized Logging Module Outputs
# ==============================================================================

# ==============================================================================
# S3 Bucket Outputs
# ==============================================================================

output "s3_bucket_name" {
  description = "S3 bucket name for log storage"
  value       = var.enable_log_export ? aws_s3_bucket.logs[0].id : null
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN for log storage"
  value       = var.enable_log_export ? aws_s3_bucket.logs[0].arn : null
}

output "s3_bucket_domain_name" {
  description = "S3 bucket domain name"
  value       = var.enable_log_export ? aws_s3_bucket.logs[0].bucket_domain_name : null
}

# ==============================================================================
# Kinesis Stream Outputs
# ==============================================================================

output "kinesis_stream_name" {
  description = "Kinesis stream name for log streaming"
  value       = var.enable_kinesis_streaming ? (var.enable_log_encryption ? aws_kinesis_stream.logs_encrypted[0].name : aws_kinesis_stream.logs[0].name) : null
}

output "kinesis_stream_arn" {
  description = "Kinesis stream ARN for log streaming"
  value       = var.enable_kinesis_streaming ? (var.enable_log_encryption ? aws_kinesis_stream.logs_encrypted[0].arn : aws_kinesis_stream.logs[0].arn) : null
}

output "kinesis_stream_id" {
  description = "Kinesis stream ID"
  value       = var.enable_kinesis_streaming ? (var.enable_log_encryption ? aws_kinesis_stream.logs_encrypted[0].id : aws_kinesis_stream.logs[0].id) : null
}

# ==============================================================================
# IAM Role Outputs
# ==============================================================================

output "kinesis_role_arn" {
  description = "IAM role ARN for CloudWatch Logs to Kinesis"
  value       = var.enable_kinesis_streaming ? aws_iam_role.cloudwatch_logs_kinesis[0].arn : null
}

output "log_export_lambda_role_arn" {
  description = "IAM role ARN for log export Lambda"
  value       = var.enable_log_export ? aws_iam_role.log_export_lambda[0].arn : null
}

# ==============================================================================
# Lambda Function Outputs
# ==============================================================================

output "log_export_lambda_function_name" {
  description = "Log export Lambda function name"
  value       = var.enable_log_export ? aws_lambda_function.log_export[0].function_name : null
}

output "log_export_lambda_function_arn" {
  description = "Log export Lambda function ARN"
  value       = var.enable_log_export ? aws_lambda_function.log_export[0].arn : null
}

# ==============================================================================
# Subscription Filter Outputs
# ==============================================================================

output "application_subscription_filter_name" {
  description = "Application log subscription filter name"
  value       = var.enable_kinesis_streaming ? aws_cloudwatch_log_subscription_filter.application_to_kinesis[0].name : null
}

output "infrastructure_subscription_filter_name" {
  description = "Infrastructure log subscription filter name"
  value       = var.enable_kinesis_streaming && var.stream_infrastructure_logs ? aws_cloudwatch_log_subscription_filter.infrastructure_to_kinesis[0].name : null
}

output "security_subscription_filter_name" {
  description = "Security log subscription filter name"
  value       = var.enable_kinesis_streaming && var.stream_security_logs ? aws_cloudwatch_log_subscription_filter.security_to_kinesis[0].name : null
}

# ==============================================================================
# Cross-Account Logging Outputs
# ==============================================================================

output "cross_account_destination_arn" {
  description = "Cross-account log destination ARN"
  value       = var.enable_cross_account_logging ? aws_cloudwatch_log_destination.cross_account[0].arn : null
}

output "cross_account_destination_name" {
  description = "Cross-account log destination name"
  value       = var.enable_cross_account_logging ? aws_cloudwatch_log_destination.cross_account[0].name : null
}

# ==============================================================================
# Query Definition Outputs
# ==============================================================================

output "log_aggregation_stats_query_id" {
  description = "Log aggregation statistics query ID"
  value       = aws_cloudwatch_query_definition.log_aggregation_stats.query_definition_id
}

output "cross_log_group_errors_query_id" {
  description = "Cross log group errors query ID"
  value       = aws_cloudwatch_query_definition.cross_log_group_errors.query_definition_id
}

# ==============================================================================
# Configuration Summary
# ==============================================================================

output "logging_summary" {
  description = "Summary of centralized logging configuration"
  value = {
    s3_export = {
      enabled           = var.enable_log_export
      bucket_name       = var.enable_log_export ? aws_s3_bucket.logs[0].id : null
      scheduled_export  = var.enable_scheduled_export
      schedule          = var.export_schedule_expression
    }
    kinesis_streaming = {
      enabled                 = var.enable_kinesis_streaming
      stream_name            = var.enable_kinesis_streaming ? (var.enable_log_encryption ? aws_kinesis_stream.logs_encrypted[0].name : aws_kinesis_stream.logs[0].name) : null
      shard_count            = var.kinesis_shard_count
      retention_hours        = var.kinesis_retention_hours
      application_logs       = var.stream_application_logs
      infrastructure_logs    = var.stream_infrastructure_logs
      security_logs          = var.stream_security_logs
    }
    cross_account = {
      enabled      = var.enable_cross_account_logging
      account_ids  = var.cross_account_ids
    }
    storage_lifecycle = {
      glacier_days       = var.s3_transition_days
      deep_archive_days  = var.s3_deep_archive_days
      expiration_days    = var.s3_expiration_days
    }
    encryption = {
      enabled = var.enable_log_encryption
      kms_key_id = var.kms_key_id
    }
  }
}

# ==============================================================================
# CloudWatch Console URLs
# ==============================================================================

output "console_urls" {
  description = "AWS Console URLs for centralized logging resources"
  value = {
    s3_bucket = var.enable_log_export ? "https://s3.console.aws.amazon.com/s3/buckets/${aws_s3_bucket.logs[0].id}" : null
    kinesis_stream = var.enable_kinesis_streaming ? "https://console.aws.amazon.com/kinesis/home?region=${data.aws_region.current.name}#/streams/details/${var.enable_log_encryption ? aws_kinesis_stream.logs_encrypted[0].name : aws_kinesis_stream.logs[0].name}/monitoring" : null
    lambda_function = var.enable_log_export ? "https://console.aws.amazon.com/lambda/home?region=${data.aws_region.current.name}#/functions/${aws_lambda_function.log_export[0].function_name}" : null
  }
}
