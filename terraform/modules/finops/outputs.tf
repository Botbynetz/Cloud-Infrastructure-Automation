# FinOps Module Outputs

# ============================================================
# Cost and Usage Report Outputs
# ============================================================

output "cost_reports_bucket_id" {
  description = "S3 bucket ID for Cost and Usage Reports"
  value       = aws_s3_bucket.cost_reports.id
}

output "cost_reports_bucket_arn" {
  description = "S3 bucket ARN for Cost and Usage Reports"
  value       = aws_s3_bucket.cost_reports.arn
}

output "cur_report_name" {
  description = "Cost and Usage Report name"
  value       = aws_cur_report_definition.finops.report_name
}

# ============================================================
# Cost Anomaly Detection Outputs
# ============================================================

output "service_monitor_arn" {
  description = "ARN of the service-level cost anomaly monitor"
  value       = aws_ce_anomaly_monitor.service_monitor.arn
}

output "account_monitor_arn" {
  description = "ARN of the account-level cost anomaly monitor (if enabled)"
  value       = var.enable_multi_account_tracking ? aws_ce_anomaly_monitor.account_monitor[0].arn : null
}

output "anomaly_subscription_arn" {
  description = "ARN of the cost anomaly subscription"
  value       = aws_ce_anomaly_subscription.anomaly_alerts.arn
}

# ============================================================
# Budget Outputs
# ============================================================

output "monthly_budget_name" {
  description = "Name of the monthly budget"
  value       = aws_budgets_budget.monthly_budget.name
}

output "monthly_budget_limit" {
  description = "Monthly budget limit in USD"
  value       = var.monthly_budget_limit
}

# ============================================================
# Lambda Function Outputs
# ============================================================

output "cost_analyzer_lambda_arn" {
  description = "ARN of the cost analyzer Lambda function"
  value       = aws_lambda_function.cost_analyzer.arn
}

output "cost_analyzer_lambda_name" {
  description = "Name of the cost analyzer Lambda function"
  value       = aws_lambda_function.cost_analyzer.function_name
}

output "rightsizing_advisor_lambda_arn" {
  description = "ARN of the rightsizing advisor Lambda function"
  value       = aws_lambda_function.rightsizing_advisor.arn
}

output "rightsizing_advisor_lambda_name" {
  description = "Name of the rightsizing advisor Lambda function"
  value       = aws_lambda_function.rightsizing_advisor.function_name
}

output "waste_elimination_lambda_arn" {
  description = "ARN of the waste elimination Lambda function"
  value       = aws_lambda_function.waste_elimination.arn
}

output "waste_elimination_lambda_name" {
  description = "Name of the waste elimination Lambda function"
  value       = aws_lambda_function.waste_elimination.function_name
}

# ============================================================
# Glue Catalog Outputs
# ============================================================

output "cost_analytics_database_name" {
  description = "Glue catalog database name for cost analytics"
  value       = aws_glue_catalog_database.cost_analytics.name
}

output "cost_analytics_database_arn" {
  description = "Glue catalog database ARN for cost analytics"
  value       = aws_glue_catalog_database.cost_analytics.arn
}

# ============================================================
# SNS Topic Outputs
# ============================================================

output "finops_alerts_topic_arn" {
  description = "ARN of the FinOps alerts SNS topic"
  value       = aws_sns_topic.finops_alerts.arn
}

output "finops_alerts_topic_name" {
  description = "Name of the FinOps alerts SNS topic"
  value       = aws_sns_topic.finops_alerts.name
}

# ============================================================
# KMS Key Outputs
# ============================================================

output "finops_kms_key_id" {
  description = "KMS key ID for FinOps data encryption"
  value       = aws_kms_key.finops.key_id
}

output "finops_kms_key_arn" {
  description = "KMS key ARN for FinOps data encryption"
  value       = aws_kms_key.finops.arn
}

# ============================================================
# CloudWatch Dashboard Outputs
# ============================================================

output "finops_dashboard_name" {
  description = "Name of the FinOps CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.finops.dashboard_name
}

output "finops_dashboard_arn" {
  description = "ARN of the FinOps CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.finops.dashboard_arn
}

# ============================================================
# EventBridge Schedule Outputs
# ============================================================

output "cost_analysis_schedule" {
  description = "Cost analysis EventBridge schedule expression"
  value       = aws_cloudwatch_event_rule.cost_analysis_daily.schedule_expression
}

output "rightsizing_schedule" {
  description = "Rightsizing analysis EventBridge schedule expression"
  value       = aws_cloudwatch_event_rule.rightsizing_weekly.schedule_expression
}

output "waste_elimination_schedule" {
  description = "Waste elimination EventBridge schedule expression"
  value       = aws_cloudwatch_event_rule.waste_elimination_daily.schedule_expression
}

# ============================================================
# Configuration Summary
# ============================================================

output "finops_summary" {
  description = "Comprehensive summary of FinOps configuration"
  value = {
    project_name                 = var.project_name
    environment                  = var.environment
    region                       = var.aws_region
    
    cost_tracking = {
      cur_bucket                 = aws_s3_bucket.cost_reports.id
      cur_report_name            = aws_cur_report_definition.finops.report_name
      data_retention_days        = var.cost_data_retention_days
      multi_account_enabled      = var.enable_multi_account_tracking
    }
    
    anomaly_detection = {
      enabled                    = true
      alert_frequency            = var.anomaly_alert_frequency
      threshold_amount_usd       = var.anomaly_threshold_amount
      threshold_percentage       = var.anomaly_threshold_percentage
    }
    
    budget_management = {
      enabled                    = var.monthly_budget_limit > 0
      monthly_limit_usd          = var.monthly_budget_limit
      alert_thresholds           = [80, 90, 100]
    }
    
    rightsizing = {
      enabled                    = true
      cpu_threshold_low          = var.rightsizing_cpu_threshold_low
      cpu_threshold_high         = var.rightsizing_cpu_threshold_high
      auto_apply                 = var.auto_apply_rightsizing
      dry_run_mode               = var.rightsizing_dry_run
      schedule                   = "Weekly on Monday 7 AM UTC"
    }
    
    waste_elimination = {
      enabled                    = true
      threshold_usd              = var.waste_threshold_usd
      unused_days_threshold      = var.unused_resource_days
      auto_delete                = var.auto_delete_waste
      dry_run_mode               = var.waste_cleanup_dry_run
      schedule                   = "Daily at 6 AM UTC"
    }
    
    automation = {
      cost_analyzer_function     = aws_lambda_function.cost_analyzer.function_name
      rightsizing_function       = aws_lambda_function.rightsizing_advisor.function_name
      waste_elimination_function = aws_lambda_function.waste_elimination.function_name
      cost_analysis_schedule     = "Daily at 8 AM UTC"
    }
    
    monitoring = {
      sns_topic                  = aws_sns_topic.finops_alerts.name
      dashboard_name             = aws_cloudwatch_dashboard.finops.dashboard_name
      notification_emails        = length(var.finops_notification_emails)
    }
    
    estimated_monthly_cost = {
      s3_storage                 = "$10-30"
      lambda_executions          = "$5-15"
      glue_catalog               = "$1-5"
      cloudwatch_logs            = "$2-8"
      sns_notifications          = "$1-2"
      total                      = "$19-60"
      note                       = "Actual costs may vary based on AWS usage volume"
    }
    
    expected_savings = {
      rightsizing                = "10-25% on EC2 costs"
      waste_elimination          = "5-15% on overall costs"
      ri_optimization            = "30-60% on committed usage"
      total_potential            = "15-30% overall cost reduction"
    }
  }
}
