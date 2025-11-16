# ==============================================================================
# Application Insights Module Outputs
# ==============================================================================

# ==============================================================================
# Anomaly Detector Outputs
# ==============================================================================

output "response_time_anomaly_detector_id" {
  description = "ID of the response time anomaly detector"
  value       = var.enable_anomaly_detection ? aws_cloudwatch_anomaly_detector.response_time[0].id : null
}

output "request_count_anomaly_detector_id" {
  description = "ID of the request count anomaly detector"
  value       = var.enable_anomaly_detection ? aws_cloudwatch_anomaly_detector.request_count[0].id : null
}

output "error_rate_anomaly_detector_id" {
  description = "ID of the error rate anomaly detector"
  value       = var.enable_anomaly_detection ? aws_cloudwatch_anomaly_detector.error_rate[0].id : null
}

# ==============================================================================
# Alarm Outputs
# ==============================================================================

output "response_time_anomaly_alarm_arn" {
  description = "ARN of the response time anomaly alarm"
  value       = var.enable_anomaly_detection ? aws_cloudwatch_metric_alarm.response_time_anomaly[0].arn : null
}

output "error_rate_anomaly_alarm_arn" {
  description = "ARN of the error rate anomaly alarm"
  value       = var.enable_anomaly_detection ? aws_cloudwatch_metric_alarm.error_rate_anomaly[0].arn : null
}

# ==============================================================================
# Metric Filter Outputs
# ==============================================================================

output "business_transactions_filter_name" {
  description = "Name of the business transactions metric filter"
  value       = var.enable_business_metrics ? aws_cloudwatch_log_metric_filter.business_transactions[0].name : null
}

output "user_signups_filter_name" {
  description = "Name of the user signups metric filter"
  value       = var.enable_business_metrics ? aws_cloudwatch_log_metric_filter.user_signups[0].name : null
}

output "api_response_time_filter_name" {
  description = "Name of the API response time metric filter"
  value       = var.enable_performance_metrics ? aws_cloudwatch_log_metric_filter.api_response_time[0].name : null
}

output "cache_hit_filter_name" {
  description = "Name of the cache hit metric filter"
  value       = var.enable_cache_metrics ? aws_cloudwatch_log_metric_filter.cache_hit_rate[0].name : null
}

output "cache_miss_filter_name" {
  description = "Name of the cache miss metric filter"
  value       = var.enable_cache_metrics ? aws_cloudwatch_log_metric_filter.cache_miss_rate[0].name : null
}

# ==============================================================================
# Contributor Insights Outputs
# ==============================================================================

output "top_error_endpoints_rule_name" {
  description = "Name of the top error endpoints Contributor Insights rule"
  value       = var.enable_contributor_insights ? aws_cloudwatch_log_contributor_insights_rule.top_error_endpoints[0].name : null
}

output "top_users_rule_name" {
  description = "Name of the top users Contributor Insights rule"
  value       = var.enable_contributor_insights ? aws_cloudwatch_log_contributor_insights_rule.top_users_by_requests[0].name : null
}

# ==============================================================================
# Synthetics Outputs
# ==============================================================================

output "synthetics_canary_name" {
  description = "Name of the Synthetics canary"
  value       = var.enable_synthetics ? aws_synthetics_canary.api_health[0].name : null
}

output "synthetics_canary_arn" {
  description = "ARN of the Synthetics canary"
  value       = var.enable_synthetics ? aws_synthetics_canary.api_health[0].arn : null
}

output "synthetics_role_arn" {
  description = "ARN of the Synthetics IAM role"
  value       = var.enable_synthetics ? aws_iam_role.synthetics[0].arn : null
}

# ==============================================================================
# Dashboard Outputs
# ==============================================================================

output "insights_dashboard_name" {
  description = "Name of the Application Insights dashboard"
  value       = var.enable_insights_dashboard ? aws_cloudwatch_dashboard.application_insights[0].dashboard_name : null
}

output "insights_dashboard_arn" {
  description = "ARN of the Application Insights dashboard"
  value       = var.enable_insights_dashboard ? aws_cloudwatch_dashboard.application_insights[0].dashboard_arn : null
}

# ==============================================================================
# Query Definition Outputs
# ==============================================================================

output "slow_transactions_query_id" {
  description = "ID of the slow transactions query definition"
  value       = aws_cloudwatch_query_definition.slow_transactions.query_definition_id
}

output "error_patterns_query_id" {
  description = "ID of the error patterns query definition"
  value       = aws_cloudwatch_query_definition.error_patterns.query_definition_id
}

output "user_activity_query_id" {
  description = "ID of the user activity query definition"
  value       = aws_cloudwatch_query_definition.user_activity.query_definition_id
}

output "api_performance_query_id" {
  description = "ID of the API performance query definition"
  value       = aws_cloudwatch_query_definition.api_performance_by_endpoint.query_definition_id
}

# ==============================================================================
# Console URLs
# ==============================================================================

output "console_urls" {
  description = "AWS Console URLs for Application Insights resources"
  value = {
    anomaly_detection = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#anomaly-detection:"
    contributor_insights = var.enable_contributor_insights ? "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#contributorinsights:" : null
    synthetics = var.enable_synthetics ? "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#synthetics:canary/detail/${var.enable_synthetics ? aws_synthetics_canary.api_health[0].name : ""}" : null
    dashboard = var.enable_insights_dashboard ? "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${var.enable_insights_dashboard ? aws_cloudwatch_dashboard.application_insights[0].dashboard_name : ""}" : null
  }
}

# ==============================================================================
# Configuration Summary
# ==============================================================================

output "application_insights_summary" {
  description = "Summary of Application Insights configuration"
  value = {
    project_name = var.project_name
    environment  = var.environment
    namespace    = var.application_namespace
    anomaly_detection = {
      enabled        = var.enable_anomaly_detection
      band_width     = var.anomaly_detection_band
      database_monitoring = var.enable_database_monitoring
    }
    custom_metrics = {
      business_metrics    = var.enable_business_metrics
      performance_metrics = var.enable_performance_metrics
      cache_metrics       = var.enable_cache_metrics
    }
    contributor_insights_enabled = var.enable_contributor_insights
    synthetics = {
      enabled  = var.enable_synthetics
      schedule = var.synthetics_schedule
      xray_enabled = var.enable_xray_tracing
    }
    dashboard_enabled = var.enable_insights_dashboard
    slow_transaction_threshold_ms = var.slow_transaction_threshold_ms
  }
}

# ==============================================================================
# Metric Names for Application Use
# ==============================================================================

output "custom_metric_names" {
  description = "List of custom metric names created by this module"
  value = {
    business = var.enable_business_metrics ? {
      transactions = "BusinessTransactions"
      signups      = "UserSignups"
    } : null
    performance = var.enable_performance_metrics ? {
      response_time = "ApiResponseTime"
    } : null
    cache = var.enable_cache_metrics ? {
      hits   = "CacheHits"
      misses = "CacheMisses"
    } : null
    anomaly = var.enable_anomaly_detection ? {
      response_time   = "ResponseTime"
      request_count   = "RequestCount"
      error_rate      = "ErrorRate"
      db_connections  = var.enable_database_monitoring ? "DatabaseConnections" : null
    } : null
  }
}
