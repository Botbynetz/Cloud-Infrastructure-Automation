# ==============================================================================
# Monitoring Module Outputs
# ==============================================================================

# ==============================================================================
# Data Sources
# ==============================================================================

data "aws_region" "current" {}

# ==============================================================================
# Log Group Outputs
# ==============================================================================

output "application_log_group_name" {
  description = "Application log group name"
  value       = aws_cloudwatch_log_group.application.name
}

output "application_log_group_arn" {
  description = "Application log group ARN"
  value       = aws_cloudwatch_log_group.application.arn
}

output "infrastructure_log_group_name" {
  description = "Infrastructure log group name"
  value       = aws_cloudwatch_log_group.infrastructure.name
}

output "infrastructure_log_group_arn" {
  description = "Infrastructure log group ARN"
  value       = aws_cloudwatch_log_group.infrastructure.arn
}

output "security_log_group_name" {
  description = "Security log group name"
  value       = aws_cloudwatch_log_group.security.name
}

output "security_log_group_arn" {
  description = "Security log group ARN"
  value       = aws_cloudwatch_log_group.security.arn
}

output "audit_log_group_name" {
  description = "Audit log group name"
  value       = aws_cloudwatch_log_group.audit.name
}

output "audit_log_group_arn" {
  description = "Audit log group ARN"
  value       = aws_cloudwatch_log_group.audit.arn
}

# ==============================================================================
# KMS Key Outputs
# ==============================================================================

output "kms_key_id" {
  description = "KMS key ID for log encryption"
  value       = var.enable_log_encryption ? aws_kms_key.logs[0].id : null
}

output "kms_key_arn" {
  description = "KMS key ARN for log encryption"
  value       = var.enable_log_encryption ? aws_kms_key.logs[0].arn : null
}

output "kms_key_alias" {
  description = "KMS key alias for log encryption"
  value       = var.enable_log_encryption ? aws_kms_alias.logs[0].name : null
}

# ==============================================================================
# Dashboard Outputs
# ==============================================================================

output "infrastructure_dashboard_name" {
  description = "Infrastructure dashboard name"
  value       = aws_cloudwatch_dashboard.infrastructure.dashboard_name
}

output "infrastructure_dashboard_arn" {
  description = "Infrastructure dashboard ARN"
  value       = aws_cloudwatch_dashboard.infrastructure.dashboard_arn
}

output "application_dashboard_name" {
  description = "Application dashboard name"
  value       = aws_cloudwatch_dashboard.application.dashboard_name
}

output "application_dashboard_arn" {
  description = "Application dashboard ARN"
  value       = aws_cloudwatch_dashboard.application.dashboard_arn
}

output "cost_dashboard_name" {
  description = "Cost monitoring dashboard name"
  value       = aws_cloudwatch_dashboard.cost.dashboard_name
}

output "cost_dashboard_arn" {
  description = "Cost monitoring dashboard ARN"
  value       = aws_cloudwatch_dashboard.cost.dashboard_arn
}

output "security_dashboard_name" {
  description = "Security monitoring dashboard name"
  value       = aws_cloudwatch_dashboard.security.dashboard_name
}

output "security_dashboard_arn" {
  description = "Security monitoring dashboard ARN"
  value       = aws_cloudwatch_dashboard.security.dashboard_arn
}

# ==============================================================================
# Alarm Outputs
# ==============================================================================

output "high_cpu_alarm_arn" {
  description = "High CPU alarm ARN"
  value       = var.enable_alarms ? aws_cloudwatch_metric_alarm.high_cpu[0].arn : null
}

output "high_memory_alarm_arn" {
  description = "High memory alarm ARN"
  value       = var.enable_alarms ? aws_cloudwatch_metric_alarm.high_memory[0].arn : null
}

output "disk_full_alarm_arn" {
  description = "Disk full alarm ARN"
  value       = var.enable_alarms ? aws_cloudwatch_metric_alarm.disk_full[0].arn : null
}

output "high_error_rate_alarm_arn" {
  description = "High error rate alarm ARN"
  value       = var.enable_alarms ? aws_cloudwatch_metric_alarm.high_error_rate[0].arn : null
}

output "slow_response_time_alarm_arn" {
  description = "Slow response time alarm ARN"
  value       = var.enable_alarms ? aws_cloudwatch_metric_alarm.slow_response_time[0].arn : null
}

output "database_cpu_alarm_arn" {
  description = "Database CPU alarm ARN"
  value       = var.enable_alarms && var.enable_database_alarms ? aws_cloudwatch_metric_alarm.database_cpu[0].arn : null
}

output "database_connections_alarm_arn" {
  description = "Database connections alarm ARN"
  value       = var.enable_alarms && var.enable_database_alarms ? aws_cloudwatch_metric_alarm.database_connections[0].arn : null
}

output "composite_alarm_arn" {
  description = "Composite application health alarm ARN"
  value       = var.enable_alarms ? aws_cloudwatch_composite_alarm.application_health[0].arn : null
}

# ==============================================================================
# Metric Filter Outputs
# ==============================================================================

output "error_count_filter_name" {
  description = "Error count metric filter name"
  value       = aws_cloudwatch_log_metric_filter.error_count.name
}

output "warning_count_filter_name" {
  description = "Warning count metric filter name"
  value       = aws_cloudwatch_log_metric_filter.warning_count.name
}

output "security_events_filter_name" {
  description = "Security events metric filter name"
  value       = aws_cloudwatch_log_metric_filter.security_events.name
}

# ==============================================================================
# Query Definition Outputs
# ==============================================================================

output "top_errors_query_id" {
  description = "Top errors query definition ID"
  value       = aws_cloudwatch_query_definition.top_errors.query_definition_id
}

output "slow_requests_query_id" {
  description = "Slow requests query definition ID"
  value       = aws_cloudwatch_query_definition.slow_requests.query_definition_id
}

output "security_audit_query_id" {
  description = "Security audit query definition ID"
  value       = aws_cloudwatch_query_definition.security_audit.query_definition_id
}

# ==============================================================================
# Dashboard URLs
# ==============================================================================

output "dashboard_urls" {
  description = "CloudWatch dashboard URLs"
  value = {
    infrastructure = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.infrastructure.dashboard_name}"
    application    = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.application.dashboard_name}"
    cost           = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.cost.dashboard_name}"
    security       = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.security.dashboard_name}"
  }
}

# ==============================================================================
# Summary Output
# ==============================================================================

output "monitoring_summary" {
  description = "Summary of monitoring configuration"
  value = {
    log_groups = {
      application    = aws_cloudwatch_log_group.application.name
      infrastructure = aws_cloudwatch_log_group.infrastructure.name
      security       = aws_cloudwatch_log_group.security.name
      audit          = aws_cloudwatch_log_group.audit.name
    }
    dashboards = {
      infrastructure = aws_cloudwatch_dashboard.infrastructure.dashboard_name
      application    = aws_cloudwatch_dashboard.application.dashboard_name
      cost           = aws_cloudwatch_dashboard.cost.dashboard_name
      security       = aws_cloudwatch_dashboard.security.dashboard_name
    }
    alarms = {
      enabled           = var.enable_alarms
      cpu_threshold     = var.cpu_alarm_threshold
      memory_threshold  = var.memory_alarm_threshold
      error_threshold   = var.error_rate_threshold
      response_threshold = var.response_time_threshold
    }
    log_retention = {
      application_days = var.log_retention_days
      security_days    = var.security_log_retention_days
      encryption       = var.enable_log_encryption
    }
    metric_filters = {
      error_count      = aws_cloudwatch_log_metric_filter.error_count.name
      warning_count    = aws_cloudwatch_log_metric_filter.warning_count.name
      security_events  = aws_cloudwatch_log_metric_filter.security_events.name
    }
  }
}
