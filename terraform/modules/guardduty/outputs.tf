# ==============================================================================
# AWS GuardDuty Module Outputs
# ==============================================================================

# ==============================================================================
# Detector Outputs
# ==============================================================================

output "detector_id" {
  description = "ID of the GuardDuty detector"
  value       = aws_guardduty_detector.main.id
}

output "detector_arn" {
  description = "ARN of the GuardDuty detector"
  value       = aws_guardduty_detector.main.arn
}

output "detector_account_id" {
  description = "AWS account ID of the GuardDuty detector"
  value       = aws_guardduty_detector.main.account_id
}

# ==============================================================================
# S3 Bucket Outputs
# ==============================================================================

output "findings_bucket_name" {
  description = "Name of the findings S3 bucket"
  value       = var.enable_findings_export ? aws_s3_bucket.guardduty_findings[0].id : null
}

output "findings_bucket_arn" {
  description = "ARN of the findings S3 bucket"
  value       = var.enable_findings_export ? aws_s3_bucket.guardduty_findings[0].arn : null
}

# ==============================================================================
# SNS Topic Outputs
# ==============================================================================

output "alerts_sns_topic_arn" {
  description = "ARN of the GuardDuty alerts SNS topic"
  value       = var.guardduty_sns_topic_arn != "" ? var.guardduty_sns_topic_arn : (length(aws_sns_topic.guardduty_alerts) > 0 ? aws_sns_topic.guardduty_alerts[0].arn : null)
}

# ==============================================================================
# EventBridge Rule Outputs
# ==============================================================================

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule for GuardDuty findings"
  value       = aws_cloudwatch_event_rule.guardduty_findings.arn
}

output "eventbridge_rule_name" {
  description = "Name of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.guardduty_findings.name
}

# ==============================================================================
# CloudWatch Log Group Outputs
# ==============================================================================

output "log_group_name" {
  description = "Name of the CloudWatch log group for GuardDuty"
  value       = aws_cloudwatch_log_group.guardduty.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.guardduty.arn
}

# ==============================================================================
# Filter Outputs
# ==============================================================================

output "critical_filter_id" {
  description = "ID of the critical findings filter"
  value       = var.enable_critical_filter ? aws_guardduty_filter.critical_findings[0].id : null
}

# ==============================================================================
# IPSet and ThreatIntelSet Outputs
# ==============================================================================

output "trusted_ipset_id" {
  description = "ID of the trusted IP set"
  value       = var.enable_trusted_ips && length(var.trusted_ip_list) > 0 ? aws_guardduty_ipset.trusted[0].id : null
}

output "threat_intel_set_id" {
  description = "ID of the threat intelligence set"
  value       = var.enable_threat_intel && length(var.threat_ip_list) > 0 ? aws_guardduty_threatintelset.known_threats[0].id : null
}

# ==============================================================================
# Alarm Outputs
# ==============================================================================

output "high_severity_alarm_arn" {
  description = "ARN of the high severity findings alarm"
  value       = var.enable_guardduty_alarms ? aws_cloudwatch_metric_alarm.high_severity_findings[0].arn : null
}

output "malware_alarm_arn" {
  description = "ARN of the malware detection alarm"
  value       = var.enable_guardduty_alarms && var.enable_malware_protection ? aws_cloudwatch_metric_alarm.malware_detected[0].arn : null
}

# ==============================================================================
# Dashboard Outputs
# ==============================================================================

output "dashboard_name" {
  description = "Name of the GuardDuty CloudWatch dashboard"
  value       = var.enable_guardduty_dashboard ? aws_cloudwatch_dashboard.guardduty[0].dashboard_name : null
}

output "dashboard_arn" {
  description = "ARN of the GuardDuty CloudWatch dashboard"
  value       = var.enable_guardduty_dashboard ? aws_cloudwatch_dashboard.guardduty[0].dashboard_arn : null
}

# ==============================================================================
# Member Accounts Outputs
# ==============================================================================

output "member_account_ids" {
  description = "List of member account IDs"
  value       = var.enable_member_accounts ? [for m in aws_guardduty_member.members : m.account_id] : []
}

# ==============================================================================
# Console URLs
# ==============================================================================

output "console_urls" {
  description = "AWS Console URLs for GuardDuty resources"
  value = {
    guardduty_dashboard = "https://console.aws.amazon.com/guardduty/home?region=${data.aws_region.current.name}#/summary"
    findings            = "https://console.aws.amazon.com/guardduty/home?region=${data.aws_region.current.name}#/findings"
    settings            = "https://console.aws.amazon.com/guardduty/home?region=${data.aws_region.current.name}#/settings"
    threat_lists        = "https://console.aws.amazon.com/guardduty/home?region=${data.aws_region.current.name}#/settings/lists"
    cloudwatch_dashboard = var.enable_guardduty_dashboard ? "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${var.project_name}-${var.environment}-guardduty" : null
  }
}

# ==============================================================================
# Configuration Summary
# ==============================================================================

output "guardduty_summary" {
  description = "Summary of GuardDuty configuration"
  value = {
    project_name = var.project_name
    environment  = var.environment
    detector = {
      id                           = aws_guardduty_detector.main.id
      enabled                      = var.enable_guardduty
      finding_publishing_frequency = var.finding_publishing_frequency
    }
    data_sources = {
      s3_protection         = var.enable_s3_logs_protection
      kubernetes_audit_logs = var.enable_kubernetes_audit_logs
      malware_protection    = var.enable_malware_protection
    }
    findings_export = {
      enabled          = var.enable_findings_export
      bucket           = var.enable_findings_export ? aws_s3_bucket.guardduty_findings[0].id : null
      retention_days   = var.findings_retention_days
      encryption       = var.enable_findings_encryption
    }
    filters = {
      critical_filter_enabled = var.enable_critical_filter
    }
    ip_lists = {
      trusted_ips_enabled   = var.enable_trusted_ips
      threat_intel_enabled  = var.enable_threat_intel
      trusted_ip_count      = length(var.trusted_ip_list)
      threat_ip_count       = length(var.threat_ip_list)
    }
    notifications = {
      sns_topic_arn     = var.guardduty_sns_topic_arn != "" ? var.guardduty_sns_topic_arn : (length(aws_sns_topic.guardduty_alerts) > 0 ? aws_sns_topic.guardduty_alerts[0].arn : null)
      alert_severities  = var.alert_severity_levels
    }
    alarms = {
      enabled                  = var.enable_guardduty_alarms
      high_severity_threshold  = var.high_severity_threshold
    }
    multi_account = {
      enabled         = var.enable_member_accounts
      member_count    = length(var.member_accounts)
    }
    dashboard = {
      enabled = var.enable_guardduty_dashboard
    }
  }
}

# ==============================================================================
# CLI Commands
# ==============================================================================

output "useful_commands" {
  description = "Useful AWS CLI commands for GuardDuty"
  value = <<-EOT
    # List all findings
    aws guardduty list-findings \
      --detector-id ${aws_guardduty_detector.main.id} \
      --region ${data.aws_region.current.name}

    # Get finding details
    aws guardduty get-findings \
      --detector-id ${aws_guardduty_detector.main.id} \
      --finding-ids <FINDING_ID> \
      --region ${data.aws_region.current.name}

    # Update findings feedback
    aws guardduty update-findings-feedback \
      --detector-id ${aws_guardduty_detector.main.id} \
      --finding-ids <FINDING_ID> \
      --feedback USEFUL \
      --region ${data.aws_region.current.name}

    # Archive findings
    aws guardduty archive-findings \
      --detector-id ${aws_guardduty_detector.main.id} \
      --finding-ids <FINDING_ID> \
      --region ${data.aws_region.current.name}

    # Get detector status
    aws guardduty get-detector \
      --detector-id ${aws_guardduty_detector.main.id} \
      --region ${data.aws_region.current.name}
  EOT
}
