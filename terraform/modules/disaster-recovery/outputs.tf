# ==============================================================================
# Disaster Recovery Module - Outputs
# ==============================================================================

# ==============================================================================
# S3 Backup Buckets
# ==============================================================================

output "backup_bucket_primary_id" {
  description = "ID of the primary backup bucket"
  value       = aws_s3_bucket.backup_primary.id
}

output "backup_bucket_primary_arn" {
  description = "ARN of the primary backup bucket"
  value       = aws_s3_bucket.backup_primary.arn
}

output "backup_bucket_secondary_id" {
  description = "ID of the secondary backup bucket"
  value       = aws_s3_bucket.backup_secondary.id
}

output "backup_bucket_secondary_arn" {
  description = "ARN of the secondary backup bucket"
  value       = aws_s3_bucket.backup_secondary.arn
}

output "replication_role_arn" {
  description = "ARN of the S3 replication IAM role"
  value       = aws_iam_role.replication.arn
}

# ==============================================================================
# RDS Disaster Recovery
# ==============================================================================

output "rds_snapshot_copy_lambda_arn" {
  description = "ARN of the RDS snapshot copy Lambda function"
  value       = var.enable_rds_dr ? aws_lambda_function.rds_snapshot_copy[0].arn : null
}

output "rds_snapshot_copy_lambda_name" {
  description = "Name of the RDS snapshot copy Lambda function"
  value       = var.enable_rds_dr ? aws_lambda_function.rds_snapshot_copy[0].function_name : null
}

output "snapshot_copy_schedule" {
  description = "CloudWatch Event schedule for snapshot copy"
  value       = var.enable_rds_dr ? aws_cloudwatch_event_rule.daily_snapshot_copy[0].schedule_expression : null
}

# ==============================================================================
# DynamoDB Global Table
# ==============================================================================

output "dr_state_table_name" {
  description = "Name of the DynamoDB table for DR state tracking"
  value       = aws_dynamodb_table.dr_state.name
}

output "dr_state_table_arn" {
  description = "ARN of the DynamoDB table for DR state tracking"
  value       = aws_dynamodb_table.dr_state.arn
}

output "dr_state_table_stream_arn" {
  description = "Stream ARN of the DynamoDB table"
  value       = aws_dynamodb_table.dr_state.stream_arn
}

# ==============================================================================
# Route53 Health Checks
# ==============================================================================

output "primary_health_check_id" {
  description = "ID of the primary region health check"
  value       = var.enable_route53_failover ? aws_route53_health_check.primary[0].id : null
}

output "secondary_health_check_id" {
  description = "ID of the secondary region health check"
  value       = var.enable_route53_failover ? aws_route53_health_check.secondary[0].id : null
}

# ==============================================================================
# CloudWatch Alarms
# ==============================================================================

output "replication_lag_alarm_arn" {
  description = "ARN of the replication lag CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.replication_lag.arn
}

output "backup_failure_alarm_arn" {
  description = "ARN of the backup failure CloudWatch alarm"
  value       = var.enable_rds_dr ? aws_cloudwatch_metric_alarm.backup_failure[0].arn : null
}

output "rto_breach_alarm_arn" {
  description = "ARN of the RTO breach CloudWatch alarm"
  value       = var.enable_route53_failover ? aws_cloudwatch_metric_alarm.rto_breach[0].arn : null
}

# ==============================================================================
# SNS Topic
# ==============================================================================

output "dr_notifications_topic_arn" {
  description = "ARN of the SNS topic for DR notifications"
  value       = aws_sns_topic.dr_notifications.arn
}

output "dr_notifications_topic_name" {
  description = "Name of the SNS topic for DR notifications"
  value       = aws_sns_topic.dr_notifications.name
}

# ==============================================================================
# Systems Manager Documents
# ==============================================================================

output "failover_procedure_name" {
  description = "Name of the SSM document for failover procedure"
  value       = aws_ssm_document.failover_procedure.name
}

output "failover_procedure_arn" {
  description = "ARN of the SSM document for failover procedure"
  value       = aws_ssm_document.failover_procedure.arn
}

output "dr_test_procedure_name" {
  description = "Name of the SSM document for DR testing"
  value       = aws_ssm_document.dr_test_procedure.name
}

output "dr_test_procedure_arn" {
  description = "ARN of the SSM document for DR testing"
  value       = aws_ssm_document.dr_test_procedure.arn
}

# ==============================================================================
# CloudWatch Dashboard
# ==============================================================================

output "dr_dashboard_name" {
  description = "Name of the CloudWatch dashboard for DR monitoring"
  value       = aws_cloudwatch_dashboard.dr_monitoring.dashboard_name
}

output "dr_dashboard_arn" {
  description = "ARN of the CloudWatch dashboard for DR monitoring"
  value       = aws_cloudwatch_dashboard.dr_monitoring.dashboard_arn
}

# ==============================================================================
# Configuration Summary
# ==============================================================================

output "dr_configuration" {
  description = "Summary of DR configuration"
  value = {
    rto_threshold_seconds        = var.rto_threshold_seconds
    rpo_threshold_seconds        = var.rpo_threshold_seconds
    backup_retention_days        = var.backup_retention_days
    snapshot_retention_days      = var.snapshot_retention_days
    replication_lag_threshold    = var.replication_lag_threshold
    rds_dr_enabled               = var.enable_rds_dr
    route53_failover_enabled     = var.enable_route53_failover
    automated_dr_testing_enabled = var.enable_automated_dr_testing
    health_check_interval        = var.health_check_interval
    health_check_failure_threshold = var.health_check_failure_threshold
  }
}

output "regions" {
  description = "Primary and secondary regions configuration"
  value = {
    primary   = data.aws_region.primary.name
    secondary = data.aws_region.secondary.name
  }
}

output "backup_strategy" {
  description = "Backup strategy summary"
  value = {
    s3_cross_region_replication = "Enabled"
    rds_automated_snapshots     = var.enable_rds_dr ? "Enabled" : "Disabled"
    dynamodb_global_tables      = "Enabled"
    point_in_time_recovery      = var.enable_point_in_time_recovery ? "Enabled" : "Disabled"
    backup_encryption           = "KMS"
    lifecycle_policies          = "Multi-tier (7/30/90/365 days)"
  }
}

output "monitoring_endpoints" {
  description = "URLs for monitoring dashboards and resources"
  value = {
    cloudwatch_dashboard = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.primary.name}#dashboards:name=${aws_cloudwatch_dashboard.dr_monitoring.dashboard_name}"
    primary_bucket_url   = "https://s3.console.aws.amazon.com/s3/buckets/${aws_s3_bucket.backup_primary.id}"
    secondary_bucket_url = "https://s3.console.aws.amazon.com/s3/buckets/${aws_s3_bucket.backup_secondary.id}"
    dr_state_table_url   = "https://console.aws.amazon.com/dynamodbv2/home?region=${data.aws_region.primary.name}#table?name=${aws_dynamodb_table.dr_state.name}"
  }
}
