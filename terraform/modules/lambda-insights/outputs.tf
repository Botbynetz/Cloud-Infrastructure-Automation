# ==============================================================================
# Lambda Insights Module Outputs
# ==============================================================================

# ==============================================================================
# Lambda Insights Layer
# ==============================================================================

output "lambda_insights_layer_arn" {
  description = "ARN of the Lambda Insights extension layer"
  value       = local.lambda_insights_layer_arn
}

# ==============================================================================
# IAM Policy Outputs
# ==============================================================================

output "lambda_insights_policy_arn" {
  description = "ARN of the Lambda Insights IAM policy"
  value       = aws_iam_policy.lambda_insights.arn
}

output "lambda_insights_policy_name" {
  description = "Name of the Lambda Insights IAM policy"
  value       = aws_iam_policy.lambda_insights.name
}

# ==============================================================================
# Log Group Outputs
# ==============================================================================

output "lambda_insights_log_group_name" {
  description = "Name of the Lambda Insights log group"
  value       = aws_cloudwatch_log_group.lambda_insights.name
}

output "lambda_insights_log_group_arn" {
  description = "ARN of the Lambda Insights log group"
  value       = aws_cloudwatch_log_group.lambda_insights.arn
}

# ==============================================================================
# Alarm Outputs
# ==============================================================================

output "high_duration_alarm_arn" {
  description = "ARN of the high duration alarm"
  value       = var.enable_lambda_alarms ? aws_cloudwatch_metric_alarm.lambda_high_duration[0].arn : null
}

output "high_memory_alarm_arn" {
  description = "ARN of the high memory utilization alarm"
  value       = var.enable_lambda_alarms ? aws_cloudwatch_metric_alarm.lambda_high_memory[0].arn : null
}

output "high_errors_alarm_arn" {
  description = "ARN of the high errors alarm"
  value       = var.enable_lambda_alarms ? aws_cloudwatch_metric_alarm.lambda_high_errors[0].arn : null
}

output "throttles_alarm_arn" {
  description = "ARN of the throttles alarm"
  value       = var.enable_lambda_alarms ? aws_cloudwatch_metric_alarm.lambda_throttles[0].arn : null
}

output "cold_starts_alarm_arn" {
  description = "ARN of the cold starts alarm"
  value       = var.enable_lambda_alarms && var.monitor_cold_starts ? aws_cloudwatch_metric_alarm.lambda_cold_starts[0].arn : null
}

# ==============================================================================
# Dashboard Outputs
# ==============================================================================

output "lambda_insights_dashboard_name" {
  description = "Name of the Lambda Insights CloudWatch dashboard"
  value       = var.enable_lambda_dashboard ? aws_cloudwatch_dashboard.lambda_insights[0].dashboard_name : null
}

output "lambda_insights_dashboard_arn" {
  description = "ARN of the Lambda Insights CloudWatch dashboard"
  value       = var.enable_lambda_dashboard ? aws_cloudwatch_dashboard.lambda_insights[0].dashboard_arn : null
}

# ==============================================================================
# Query Definition Outputs
# ==============================================================================

output "performance_query_id" {
  description = "ID of the Lambda performance query definition"
  value       = aws_cloudwatch_query_definition.lambda_performance.query_definition_id
}

output "cold_starts_query_id" {
  description = "ID of the Lambda cold starts query definition"
  value       = aws_cloudwatch_query_definition.lambda_cold_starts.query_definition_id
}

output "errors_query_id" {
  description = "ID of the Lambda errors query definition"
  value       = aws_cloudwatch_query_definition.lambda_errors.query_definition_id
}

output "memory_analysis_query_id" {
  description = "ID of the Lambda memory analysis query definition"
  value       = aws_cloudwatch_query_definition.lambda_memory_analysis.query_definition_id
}

# ==============================================================================
# Console URLs
# ==============================================================================

output "console_urls" {
  description = "AWS Console URLs for Lambda Insights resources"
  value = {
    lambda_insights = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#lambda-insights:functions"
    dashboard       = var.enable_lambda_dashboard ? "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${var.enable_lambda_dashboard ? aws_cloudwatch_dashboard.lambda_insights[0].dashboard_name : ""}" : null
  }
}

# ==============================================================================
# Configuration Summary
# ==============================================================================

output "lambda_insights_summary" {
  description = "Summary of Lambda Insights configuration"
  value = {
    project_name = var.project_name
    environment  = var.environment
    layer_arn    = local.lambda_insights_layer_arn
    policy_arn   = aws_iam_policy.lambda_insights.arn
    logging = {
      log_group_name    = aws_cloudwatch_log_group.lambda_insights.name
      retention_days    = var.log_retention_days
      encryption_enabled = var.enable_log_encryption
    }
    alarms = {
      enabled                = var.enable_lambda_alarms
      duration_threshold_ms  = var.duration_threshold_ms
      memory_threshold       = var.memory_utilization_threshold
      error_threshold        = var.error_threshold
      throttle_threshold     = var.throttle_threshold
      monitor_cold_starts    = var.monitor_cold_starts
      cold_start_threshold_ms = var.cold_start_threshold_ms
    }
    dashboard_enabled = var.enable_lambda_dashboard
    insights_log_level = var.insights_log_level
  }
}

# ==============================================================================
# Lambda Function Integration Config
# ==============================================================================

output "lambda_function_config" {
  description = "Configuration to apply to Lambda functions for Insights integration"
  value = {
    layers = [local.lambda_insights_layer_arn]
    environment_variables = local.lambda_insights_config.environment_variables
    policy_arn = aws_iam_policy.lambda_insights.arn
    log_group = aws_cloudwatch_log_group.lambda_insights.name
  }
}
