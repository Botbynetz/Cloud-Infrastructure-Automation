# ==============================================================================
# AWS X-Ray Module Outputs
# ==============================================================================

# ==============================================================================
# X-Ray Group Outputs
# ==============================================================================

output "xray_group_name" {
  description = "Name of the main X-Ray group"
  value       = aws_xray_group.main.group_name
}

output "xray_group_arn" {
  description = "ARN of the main X-Ray group"
  value       = aws_xray_group.main.arn
}

output "error_group_name" {
  description = "Name of the error X-Ray group"
  value       = var.enable_error_group ? aws_xray_group.errors[0].group_name : null
}

output "error_group_arn" {
  description = "ARN of the error X-Ray group"
  value       = var.enable_error_group ? aws_xray_group.errors[0].arn : null
}

output "slow_request_group_name" {
  description = "Name of the slow request X-Ray group"
  value       = var.enable_slow_request_group ? aws_xray_group.slow_requests_group[0].group_name : null
}

output "slow_request_group_arn" {
  description = "ARN of the slow request X-Ray group"
  value       = var.enable_slow_request_group ? aws_xray_group.slow_requests_group[0].arn : null
}

# ==============================================================================
# Sampling Rule Outputs
# ==============================================================================

output "default_sampling_rule_arn" {
  description = "ARN of the default sampling rule"
  value       = aws_xray_sampling_rule.default.arn
}

output "high_priority_sampling_rule_arn" {
  description = "ARN of the high priority sampling rule"
  value       = var.enable_high_priority_sampling ? aws_xray_sampling_rule.high_priority[0].arn : null
}

output "api_sampling_rule_arn" {
  description = "ARN of the API sampling rule"
  value       = var.enable_api_sampling ? aws_xray_sampling_rule.api_endpoints[0].arn : null
}

output "error_sampling_rule_arn" {
  description = "ARN of the error sampling rule"
  value       = var.enable_error_sampling ? aws_xray_sampling_rule.error_traces[0].arn : null
}

output "slow_request_sampling_rule_arn" {
  description = "ARN of the slow request sampling rule"
  value       = var.enable_slow_request_sampling ? aws_xray_sampling_rule.slow_requests[0].arn : null
}

# ==============================================================================
# IAM Outputs
# ==============================================================================

output "xray_role_arn" {
  description = "ARN of the X-Ray IAM role"
  value       = var.create_xray_role ? aws_iam_role.xray[0].arn : null
}

output "xray_role_name" {
  description = "Name of the X-Ray IAM role"
  value       = var.create_xray_role ? aws_iam_role.xray[0].name : null
}

output "xray_instance_profile_arn" {
  description = "ARN of the X-Ray instance profile"
  value       = var.create_xray_role && var.create_instance_profile ? aws_iam_instance_profile.xray[0].arn : null
}

output "xray_instance_profile_name" {
  description = "Name of the X-Ray instance profile"
  value       = var.create_xray_role && var.create_instance_profile ? aws_iam_instance_profile.xray[0].name : null
}

# ==============================================================================
# Alarm Outputs
# ==============================================================================

output "high_error_rate_alarm_arn" {
  description = "ARN of the high error rate alarm"
  value       = var.enable_xray_alarms ? aws_cloudwatch_metric_alarm.high_error_rate[0].arn : null
}

output "high_latency_alarm_arn" {
  description = "ARN of the high latency alarm"
  value       = var.enable_xray_alarms ? aws_cloudwatch_metric_alarm.high_latency[0].arn : null
}

output "throttle_alarm_arn" {
  description = "ARN of the throttle rate alarm"
  value       = var.enable_xray_alarms ? aws_cloudwatch_metric_alarm.throttle_rate[0].arn : null
}

# ==============================================================================
# Lambda Layer Outputs
# ==============================================================================

output "xray_lambda_layer_arn" {
  description = "ARN of the X-Ray Lambda layer"
  value       = var.create_lambda_layer ? aws_lambda_layer_version.xray_sdk[0].arn : null
}

output "xray_lambda_layer_version" {
  description = "Version of the X-Ray Lambda layer"
  value       = var.create_lambda_layer ? aws_lambda_layer_version.xray_sdk[0].version : null
}

# ==============================================================================
# Dashboard Outputs
# ==============================================================================

output "xray_dashboard_name" {
  description = "Name of the X-Ray CloudWatch dashboard"
  value       = var.enable_xray_dashboard ? aws_cloudwatch_dashboard.xray[0].dashboard_name : null
}

output "xray_dashboard_arn" {
  description = "ARN of the X-Ray CloudWatch dashboard"
  value       = var.enable_xray_dashboard ? aws_cloudwatch_dashboard.xray[0].dashboard_arn : null
}

# ==============================================================================
# Console URLs
# ==============================================================================

output "console_urls" {
  description = "AWS Console URLs for X-Ray resources"
  value = {
    service_map = local.service_map_url
    traces      = local.traces_url
    analytics   = local.analytics_url
    dashboard   = var.enable_xray_dashboard ? "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${var.enable_xray_dashboard ? aws_cloudwatch_dashboard.xray[0].dashboard_name : ""}" : null
  }
}

# ==============================================================================
# Configuration Summary
# ==============================================================================

output "xray_summary" {
  description = "Summary of X-Ray configuration"
  value = {
    service_name = var.service_name
    environment  = var.environment
    sampling = {
      default_rate              = var.default_sampling_rate
      high_priority_enabled     = var.enable_high_priority_sampling
      high_priority_rate        = var.high_priority_sampling_rate
      api_sampling_enabled      = var.enable_api_sampling
      api_sampling_rate         = var.api_sampling_rate
      error_sampling_enabled    = var.enable_error_sampling
      slow_request_enabled      = var.enable_slow_request_sampling
      slow_request_threshold_ms = var.slow_request_threshold * 1000
    }
    groups = {
      main_group           = aws_xray_group.main.group_name
      error_group_enabled  = var.enable_error_group
      slow_group_enabled   = var.enable_slow_request_group
      insights_enabled     = var.enable_insights
      notifications_enabled = var.enable_insights_notifications
    }
    iam = {
      role_created             = var.create_xray_role
      instance_profile_created = var.create_instance_profile
    }
    alarms = {
      enabled                = var.enable_xray_alarms
      error_rate_threshold   = var.error_rate_threshold
      latency_threshold_ms   = var.latency_threshold
      throttle_rate_threshold = var.throttle_rate_threshold
    }
    security = {
      encryption_enabled = var.enable_encryption
      kms_key_provided   = var.kms_key_id != ""
    }
    dashboard_enabled = var.enable_xray_dashboard
  }
}

# ==============================================================================
# Integration Variables for Other Modules
# ==============================================================================

output "xray_daemon_config" {
  description = "Configuration for X-Ray daemon"
  value = {
    sampling_rule_arns = concat(
      [aws_xray_sampling_rule.default.arn],
      var.enable_high_priority_sampling ? [aws_xray_sampling_rule.high_priority[0].arn] : [],
      var.enable_api_sampling ? [aws_xray_sampling_rule.api_endpoints[0].arn] : [],
      var.enable_error_sampling ? [aws_xray_sampling_rule.error_traces[0].arn] : [],
      var.enable_slow_request_sampling ? [aws_xray_sampling_rule.slow_requests[0].arn] : []
    )
    group_name = aws_xray_group.main.group_name
    region     = data.aws_region.current.name
  }
}

output "instrumentation_config" {
  description = "Configuration for application instrumentation"
  value = {
    service_name       = var.service_name
    sampling_rate      = var.default_sampling_rate
    tracing_enabled    = true
    daemon_address     = "127.0.0.1:2000"  # Default X-Ray daemon address
    log_group          = var.application_log_group_name
    environment        = var.environment
  }
}
