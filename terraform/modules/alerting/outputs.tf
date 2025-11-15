# ==============================================================================
# Advanced Alerting Module Outputs
# ==============================================================================

# ==============================================================================
# SNS Topic Outputs
# ==============================================================================

output "critical_topic_arn" {
  description = "Critical alerts SNS topic ARN"
  value       = var.enable_sns_notifications ? aws_sns_topic.critical[0].arn : null
}

output "critical_topic_name" {
  description = "Critical alerts SNS topic name"
  value       = var.enable_sns_notifications ? aws_sns_topic.critical[0].name : null
}

output "warning_topic_arn" {
  description = "Warning alerts SNS topic ARN"
  value       = var.enable_sns_notifications ? aws_sns_topic.warning[0].arn : null
}

output "warning_topic_name" {
  description = "Warning alerts SNS topic name"
  value       = var.enable_sns_notifications ? aws_sns_topic.warning[0].name : null
}

output "info_topic_arn" {
  description = "Info alerts SNS topic ARN"
  value       = var.enable_sns_notifications ? aws_sns_topic.info[0].arn : null
}

output "info_topic_name" {
  description = "Info alerts SNS topic name"
  value       = var.enable_sns_notifications ? aws_sns_topic.info[0].name : null
}

# ==============================================================================
# Lambda Function Outputs
# ==============================================================================

output "slack_notifier_function_arn" {
  description = "Slack notifier Lambda function ARN"
  value       = var.enable_slack_notifications ? aws_lambda_function.slack_notifier[0].arn : null
}

output "pagerduty_notifier_function_arn" {
  description = "PagerDuty notifier Lambda function ARN"
  value       = var.enable_pagerduty_notifications ? aws_lambda_function.pagerduty_notifier[0].arn : null
}

output "alert_aggregator_function_arn" {
  description = "Alert aggregator Lambda function ARN"
  value       = var.enable_alert_aggregation ? aws_lambda_function.alert_aggregator[0].arn : null
}

# ==============================================================================
# DynamoDB Table Outputs
# ==============================================================================

output "alert_state_table_name" {
  description = "Alert state DynamoDB table name"
  value       = var.enable_alert_aggregation ? aws_dynamodb_table.alert_state[0].name : null
}

output "alert_state_table_arn" {
  description = "Alert state DynamoDB table ARN"
  value       = var.enable_alert_aggregation ? aws_dynamodb_table.alert_state[0].arn : null
}

# ==============================================================================
# Step Function Outputs
# ==============================================================================

output "escalation_state_machine_arn" {
  description = "Alert escalation state machine ARN"
  value       = var.enable_escalation ? aws_sfn_state_machine.alert_escalation[0].arn : null
}

output "escalation_state_machine_name" {
  description = "Alert escalation state machine name"
  value       = var.enable_escalation ? aws_sfn_state_machine.alert_escalation[0].name : null
}

# ==============================================================================
# Configuration Summary
# ==============================================================================

output "alerting_summary" {
  description = "Summary of alerting configuration"
  value = {
    sns_topics = {
      critical = var.enable_sns_notifications ? aws_sns_topic.critical[0].arn : null
      warning  = var.enable_sns_notifications ? aws_sns_topic.warning[0].arn : null
      info     = var.enable_sns_notifications ? aws_sns_topic.info[0].arn : null
    }
    integrations = {
      slack        = var.enable_slack_notifications
      pagerduty    = var.enable_pagerduty_notifications
      sms          = var.enable_sms_notifications
    }
    features = {
      aggregation  = var.enable_alert_aggregation
      escalation   = var.enable_escalation
      encryption   = var.enable_encryption
    }
    subscriptions = {
      critical_emails = length(var.critical_email_endpoints)
      warning_emails  = length(var.warning_email_endpoints)
      info_emails     = length(var.info_email_endpoints)
      critical_sms    = length(var.critical_sms_endpoints)
    }
  }
}

# ==============================================================================
# Alarm Action ARNs (for use in CloudWatch alarms)
# ==============================================================================

output "alarm_actions" {
  description = "Map of alarm actions by severity"
  value = var.enable_sns_notifications ? {
    critical = aws_sns_topic.critical[0].arn
    warning  = aws_sns_topic.warning[0].arn
    info     = aws_sns_topic.info[0].arn
  } : {}
}
