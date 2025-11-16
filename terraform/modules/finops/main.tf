# FinOps & Advanced Cost Management Module
# ML-powered cost optimization and waste elimination

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ============================================================
# Cost and Usage Report (CUR) - Foundation for Cost Analytics
# ============================================================

resource "aws_cur_report_definition" "finops" {
  report_name                = "${var.project_name}-${var.environment}-cur"
  time_unit                  = "HOURLY"
  format                     = "Parquet"
  compression                = "Parquet"
  additional_schema_elements = ["RESOURCES"]
  
  s3_bucket                  = aws_s3_bucket.cost_reports.id
  s3_region                  = var.cur_region
  s3_prefix                  = "cur"
  
  additional_artifacts       = ["ATHENA"]
  refresh_closed_reports     = true
  report_versioning          = "OVERWRITE_REPORT"
}

# S3 bucket for Cost and Usage Reports
resource "aws_s3_bucket" "cost_reports" {
  bucket = "${var.project_name}-${var.environment}-cost-reports-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-cost-reports"
    Purpose     = "FinOps cost and usage data storage"
    Compliance  = "FinOps-Framework"
  })
}

resource "aws_s3_bucket_versioning" "cost_reports" {
  bucket = aws_s3_bucket.cost_reports.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cost_reports" {
  bucket = aws_s3_bucket.cost_reports.id

  rule {
    id     = "cost-report-retention"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    expiration {
      days = var.cost_data_retention_days
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cost_reports" {
  bucket = aws_s3_bucket.cost_reports.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.finops.arn
    }
  }
}

# KMS key for FinOps data encryption
resource "aws_kms_key" "finops" {
  description             = "FinOps data encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name    = "${var.project_name}-${var.environment}-finops-key"
    Purpose = "FinOps data encryption"
  })
}

resource "aws_kms_alias" "finops" {
  name          = "alias/${var.project_name}-${var.environment}-finops"
  target_key_id = aws_kms_key.finops.key_id
}

# S3 bucket policy for CUR delivery
resource "aws_s3_bucket_policy" "cost_reports" {
  bucket = aws_s3_bucket.cost_reports.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCURDelivery"
        Effect = "Allow"
        Principal = {
          Service = "billingreports.amazonaws.com"
        }
        Action = [
          "s3:GetBucketAcl",
          "s3:GetBucketPolicy"
        ]
        Resource = aws_s3_bucket.cost_reports.arn
      },
      {
        Sid    = "AllowCURWrite"
        Effect = "Allow"
        Principal = {
          Service = "billingreports.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cost_reports.arn}/*"
      }
    ]
  })
}

# ============================================================
# AWS Cost Anomaly Detection - ML-Powered Anomaly Detection
# ============================================================

resource "aws_ce_anomaly_monitor" "service_monitor" {
  name              = "${var.project_name}-${var.environment}-service-monitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"

  tags = merge(var.tags, {
    Name    = "${var.project_name}-${var.environment}-service-monitor"
    Purpose = "Service-level cost anomaly detection"
  })
}

resource "aws_ce_anomaly_monitor" "account_monitor" {
  count = var.enable_multi_account_tracking ? 1 : 0

  name              = "${var.project_name}-${var.environment}-account-monitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "LINKED_ACCOUNT"

  tags = merge(var.tags, {
    Name    = "${var.project_name}-${var.environment}-account-monitor"
    Purpose = "Account-level cost anomaly detection"
  })
}

resource "aws_ce_anomaly_subscription" "anomaly_alerts" {
  name      = "${var.project_name}-${var.environment}-anomaly-alerts"
  frequency = var.anomaly_alert_frequency

  monitor_arn_list = concat(
    [aws_ce_anomaly_monitor.service_monitor.arn],
    var.enable_multi_account_tracking ? [aws_ce_anomaly_monitor.account_monitor[0].arn] : []
  )

  subscriber {
    type    = "SNS"
    address = aws_sns_topic.finops_alerts.arn
  }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      values        = [tostring(var.anomaly_threshold_amount)]
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }

  tags = merge(var.tags, {
    Name    = "${var.project_name}-${var.environment}-anomaly-subscription"
    Purpose = "Cost anomaly alert subscription"
  })
}

# SNS topic for FinOps alerts
resource "aws_sns_topic" "finops_alerts" {
  name              = "${var.project_name}-${var.environment}-finops-alerts"
  kms_master_key_id = aws_kms_key.finops.id

  tags = merge(var.tags, {
    Name    = "${var.project_name}-${var.environment}-finops-alerts"
    Purpose = "FinOps notifications"
  })
}

resource "aws_sns_topic_subscription" "finops_email" {
  for_each = toset(var.finops_notification_emails)

  topic_arn = aws_sns_topic.finops_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

# ============================================================
# AWS Budgets - Proactive Budget Management
# ============================================================

resource "aws_budgets_budget" "monthly_budget" {
  name              = "${var.project_name}-${var.environment}-monthly-budget"
  budget_type       = "COST"
  limit_amount      = var.monthly_budget_limit
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = formatdate("YYYY-MM-01_00:00", timestamp())

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.finops_notification_emails
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.finops_notification_emails
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 90
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.finops_notification_emails
  }
}

# ============================================================
# Glue Database for Cost Analytics
# ============================================================

resource "aws_glue_catalog_database" "cost_analytics" {
  name        = "${var.project_name}_${var.environment}_cost_analytics"
  description = "FinOps cost and usage data catalog"

  tags = merge(var.tags, {
    Name    = "${var.project_name}-${var.environment}-cost-analytics"
    Purpose = "FinOps data catalog"
  })
}

# ============================================================
# Lambda: Cost Analyzer - Advanced Cost Analysis
# ============================================================

resource "aws_lambda_function" "cost_analyzer" {
  filename         = "${path.module}/lambda/cost_analyzer.zip"
  function_name    = "${var.project_name}-${var.environment}-cost-analyzer"
  role             = aws_iam_role.cost_analyzer_lambda.arn
  handler          = "cost_analyzer.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/cost_analyzer.zip")
  runtime          = "python3.11"
  timeout          = 300
  memory_size      = 512

  environment {
    variables = {
      PROJECT_NAME          = var.project_name
      ENVIRONMENT           = var.environment
      COST_BUCKET           = aws_s3_bucket.cost_reports.id
      ATHENA_DATABASE       = aws_glue_catalog_database.cost_analytics.name
      SNS_TOPIC_ARN         = aws_sns_topic.finops_alerts.arn
      WASTE_THRESHOLD_USD   = var.waste_threshold_usd
      ANOMALY_THRESHOLD_PCT = var.anomaly_threshold_percentage
    }
  }

  tags = merge(var.tags, {
    Name    = "${var.project_name}-${var.environment}-cost-analyzer"
    Purpose = "FinOps cost analysis automation"
  })
}

# EventBridge rule for daily cost analysis
resource "aws_cloudwatch_event_rule" "cost_analysis_daily" {
  name                = "${var.project_name}-${var.environment}-cost-analysis-daily"
  description         = "Trigger cost analysis daily at 8 AM UTC"
  schedule_expression = "cron(0 8 * * ? *)"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-cost-analysis-daily"
  })
}

resource "aws_cloudwatch_event_target" "cost_analysis_daily" {
  rule      = aws_cloudwatch_event_rule.cost_analysis_daily.name
  target_id = "CostAnalyzerLambda"
  arn       = aws_lambda_function.cost_analyzer.arn
}

resource "aws_lambda_permission" "cost_analysis_daily" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_analyzer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cost_analysis_daily.arn
}

# IAM role for cost analyzer Lambda
resource "aws_iam_role" "cost_analyzer_lambda" {
  name = "${var.project_name}-${var.environment}-cost-analyzer-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-cost-analyzer-lambda-role"
  })
}

resource "aws_iam_role_policy" "cost_analyzer_lambda" {
  name = "cost-analyzer-policy"
  role = aws_iam_role.cost_analyzer_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.cost_reports.arn,
          "${aws_s3_bucket.cost_reports.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetTable",
          "glue:GetPartitions"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ce:GetCostAndUsage",
          "ce:GetCostForecast",
          "ce:GetReservationUtilization",
          "ce:GetSavingsPlansUtilization"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.finops_alerts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# ============================================================
# Lambda: Rightsizing Advisor - Automated Rightsizing
# ============================================================

resource "aws_lambda_function" "rightsizing_advisor" {
  filename         = "${path.module}/lambda/rightsizing_advisor.zip"
  function_name    = "${var.project_name}-${var.environment}-rightsizing-advisor"
  role             = aws_iam_role.rightsizing_lambda.arn
  handler          = "rightsizing_advisor.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/rightsizing_advisor.zip")
  runtime          = "python3.11"
  timeout          = 600
  memory_size      = 1024

  environment {
    variables = {
      PROJECT_NAME             = var.project_name
      ENVIRONMENT              = var.environment
      SNS_TOPIC_ARN            = aws_sns_topic.finops_alerts.arn
      CPU_THRESHOLD_LOW        = var.rightsizing_cpu_threshold_low
      CPU_THRESHOLD_HIGH       = var.rightsizing_cpu_threshold_high
      AUTO_APPLY_RECOMMENDATIONS = var.auto_apply_rightsizing
      DRY_RUN                  = var.rightsizing_dry_run
    }
  }

  tags = merge(var.tags, {
    Name    = "${var.project_name}-${var.environment}-rightsizing-advisor"
    Purpose = "Automated EC2 rightsizing recommendations"
  })
}

# EventBridge rule for weekly rightsizing analysis
resource "aws_cloudwatch_event_rule" "rightsizing_weekly" {
  name                = "${var.project_name}-${var.environment}-rightsizing-weekly"
  description         = "Trigger rightsizing analysis weekly on Monday at 7 AM UTC"
  schedule_expression = "cron(0 7 ? * MON *)"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-rightsizing-weekly"
  })
}

resource "aws_cloudwatch_event_target" "rightsizing_weekly" {
  rule      = aws_cloudwatch_event_rule.rightsizing_weekly.name
  target_id = "RightsizingAdvisorLambda"
  arn       = aws_lambda_function.rightsizing_advisor.arn
}

resource "aws_lambda_permission" "rightsizing_weekly" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rightsizing_advisor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rightsizing_weekly.arn
}

# IAM role for rightsizing advisor Lambda
resource "aws_iam_role" "rightsizing_lambda" {
  name = "${var.project_name}-${var.environment}-rightsizing-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-rightsizing-lambda-role"
  })
}

resource "aws_iam_role_policy" "rightsizing_lambda" {
  name = "rightsizing-policy"
  role = aws_iam_role.rightsizing_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData",
          "ce:GetRightsizingRecommendation"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:ModifyInstanceAttribute",
          "ec2:StopInstances",
          "ec2:StartInstances"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.finops_alerts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# ============================================================
# Lambda: Waste Elimination - Automated Cleanup
# ============================================================

resource "aws_lambda_function" "waste_elimination" {
  filename         = "${path.module}/lambda/waste_elimination.zip"
  function_name    = "${var.project_name}-${var.environment}-waste-elimination"
  role             = aws_iam_role.waste_elimination_lambda.arn
  handler          = "waste_elimination.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/waste_elimination.zip")
  runtime          = "python3.11"
  timeout          = 600
  memory_size      = 512

  environment {
    variables = {
      PROJECT_NAME          = var.project_name
      ENVIRONMENT           = var.environment
      SNS_TOPIC_ARN         = aws_sns_topic.finops_alerts.arn
      AUTO_DELETE_RESOURCES = var.auto_delete_waste
      DRY_RUN               = var.waste_cleanup_dry_run
      UNUSED_DAYS_THRESHOLD = var.unused_resource_days
    }
  }

  tags = merge(var.tags, {
    Name    = "${var.project_name}-${var.environment}-waste-elimination"
    Purpose = "Automated waste detection and cleanup"
  })
}

# EventBridge rule for daily waste detection
resource "aws_cloudwatch_event_rule" "waste_elimination_daily" {
  name                = "${var.project_name}-${var.environment}-waste-elimination-daily"
  description         = "Trigger waste elimination daily at 6 AM UTC"
  schedule_expression = "cron(0 6 * * ? *)"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-waste-elimination-daily"
  })
}

resource "aws_cloudwatch_event_target" "waste_elimination_daily" {
  rule      = aws_cloudwatch_event_rule.waste_elimination_daily.name
  target_id = "WasteEliminationLambda"
  arn       = aws_lambda_function.waste_elimination.arn
}

resource "aws_lambda_permission" "waste_elimination_daily" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.waste_elimination.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.waste_elimination_daily.arn
}

# IAM role for waste elimination Lambda
resource "aws_iam_role" "waste_elimination_lambda" {
  name = "${var.project_name}-${var.environment}-waste-elimination-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-waste-elimination-lambda-role"
  })
}

resource "aws_iam_role_policy" "waste_elimination_lambda" {
  name = "waste-elimination-policy"
  role = aws_iam_role.waste_elimination_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:DescribeImages",
          "ec2:DescribeAddresses",
          "elb:DescribeLoadBalancers",
          "rds:DescribeDBInstances",
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation",
          "s3:GetBucketTagging",
          "cloudwatch:GetMetricStatistics"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DeleteVolume",
          "ec2:DeleteSnapshot",
          "ec2:DeregisterImage",
          "ec2:ReleaseAddress"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.finops_alerts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# ============================================================
# CloudWatch Dashboard for FinOps
# ============================================================

resource "aws_cloudwatch_dashboard" "finops" {
  dashboard_name = "${var.project_name}-${var.environment}-finops-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum", label = "Cost Analyzer Invocations" }],
            [".", "Errors", { stat = "Sum", label = "Cost Analyzer Errors" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Cost Analyzer Lambda Metrics"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum", label = "Rightsizing Invocations" }],
            [".", "Duration", { stat = "Average", label = "Avg Duration (ms)" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Rightsizing Advisor Metrics"
        }
      },
      {
        type = "log"
        properties = {
          query   = <<-EOT
            SOURCE '${aws_lambda_function.cost_analyzer.function_name}'
            | fields @timestamp, @message
            | filter @message like /WASTE_DETECTED/
            | sort @timestamp desc
            | limit 20
          EOT
          region  = var.aws_region
          title   = "Recent Waste Detections"
        }
      }
    ]
  })
}

# ============================================================
# CloudWatch Log Groups
# ============================================================

resource "aws_cloudwatch_log_group" "cost_analyzer" {
  name              = "/aws/lambda/${aws_lambda_function.cost_analyzer.function_name}"
  retention_in_days = 30

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-cost-analyzer-logs"
  })
}

resource "aws_cloudwatch_log_group" "rightsizing_advisor" {
  name              = "/aws/lambda/${aws_lambda_function.rightsizing_advisor.function_name}"
  retention_in_days = 30

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-rightsizing-advisor-logs"
  })
}

resource "aws_cloudwatch_log_group" "waste_elimination" {
  name              = "/aws/lambda/${aws_lambda_function.waste_elimination.function_name}"
  retention_in_days = 30

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-waste-elimination-logs"
  })
}

# ============================================================
# CloudWatch Alarms
# ============================================================

resource "aws_cloudwatch_metric_alarm" "cost_analyzer_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-cost-analyzer-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Cost analyzer Lambda function errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.cost_analyzer.function_name
  }

  alarm_actions = var.alarm_actions != null ? var.alarm_actions : [aws_sns_topic.finops_alerts.arn]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-cost-analyzer-errors-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "budget_exceeded" {
  count = var.monthly_budget_limit > 0 ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-budget-exceeded"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 21600 # 6 hours
  statistic           = "Maximum"
  threshold           = var.monthly_budget_limit * 0.9
  alarm_description   = "Monthly budget approaching limit (90%)"
  treat_missing_data  = "notBreaching"

  dimensions = {
    Currency = "USD"
  }

  alarm_actions = var.alarm_actions != null ? var.alarm_actions : [aws_sns_topic.finops_alerts.arn]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-budget-exceeded-alarm"
  })
}

# ============================================================
# Data Sources
# ============================================================

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
