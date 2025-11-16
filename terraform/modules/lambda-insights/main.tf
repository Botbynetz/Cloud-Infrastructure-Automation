# ==============================================================================
# Lambda Insights Module
# ==============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# ==============================================================================
# Data Sources
# ==============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ==============================================================================
# Lambda Insights Layer (Official AWS Layer)
# ==============================================================================

# Lambda Insights Layer ARNs by region
# Reference: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Lambda-Insights-extension-versions.html

locals {
  lambda_insights_layers = {
    us-east-1      = "arn:aws:lambda:us-east-1:580247275435:layer:LambdaInsightsExtension:49"
    us-east-2      = "arn:aws:lambda:us-east-2:580247275435:layer:LambdaInsightsExtension:49"
    us-west-1      = "arn:aws:lambda:us-west-1:580247275435:layer:LambdaInsightsExtension:49"
    us-west-2      = "arn:aws:lambda:us-west-2:580247275435:layer:LambdaInsightsExtension:49"
    ap-southeast-1 = "arn:aws:lambda:ap-southeast-1:580247275435:layer:LambdaInsightsExtension:49"
    ap-southeast-2 = "arn:aws:lambda:ap-southeast-2:580247275435:layer:LambdaInsightsExtension:49"
    eu-west-1      = "arn:aws:lambda:eu-west-1:580247275435:layer:LambdaInsightsExtension:49"
    eu-central-1   = "arn:aws:lambda:eu-central-1:580247275435:layer:LambdaInsightsExtension:49"
  }

  lambda_insights_layer_arn = lookup(
    local.lambda_insights_layers,
    data.aws_region.current.name,
    local.lambda_insights_layers["us-east-1"]
  )
}

# ==============================================================================
# IAM Policy for Lambda Insights
# ==============================================================================

resource "aws_iam_policy" "lambda_insights" {
  name        = "${var.project_name}-${var.environment}-lambda-insights"
  description = "IAM policy for Lambda Insights"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda-insights:*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "LambdaInsights"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-lambda-insights"
      Environment = var.environment
    }
  )
}

# ==============================================================================
# IAM Role Attachment (for existing Lambda functions)
# ==============================================================================

resource "aws_iam_role_policy_attachment" "lambda_insights" {
  for_each = toset(var.lambda_role_names)

  role       = each.value
  policy_arn = aws_iam_policy.lambda_insights.arn
}

# ==============================================================================
# CloudWatch Log Group for Lambda Insights
# ==============================================================================

resource "aws_cloudwatch_log_group" "lambda_insights" {
  name              = "/aws/lambda-insights"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.enable_log_encryption ? var.kms_key_id : null

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-lambda-insights"
      Environment = var.environment
    }
  )
}

# ==============================================================================
# CloudWatch Alarms for Lambda Insights
# ==============================================================================

resource "aws_cloudwatch_metric_alarm" "lambda_high_duration" {
  count = var.enable_lambda_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-lambda-high-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "duration_max"
  namespace           = "LambdaInsights"
  period              = 300
  statistic           = "Maximum"
  threshold           = var.duration_threshold_ms
  alarm_description   = "Lambda function duration exceeds threshold"
  alarm_actions       = var.alarm_actions

  dimensions = {
    function_name = var.primary_function_name
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-lambda-duration-alarm"
      Environment = var.environment
      Severity    = "warning"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "lambda_high_memory" {
  count = var.enable_lambda_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-lambda-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "memory_utilization"
  namespace           = "LambdaInsights"
  period              = 300
  statistic           = "Average"
  threshold           = var.memory_utilization_threshold
  alarm_description   = "Lambda memory utilization exceeds threshold"
  alarm_actions       = var.alarm_actions

  dimensions = {
    function_name = var.primary_function_name
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-lambda-memory-alarm"
      Environment = var.environment
      Severity    = "warning"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "lambda_high_errors" {
  count = var.enable_lambda_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-lambda-high-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = var.error_threshold
  alarm_description   = "Lambda function errors exceed threshold"
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.primary_function_name
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-lambda-error-alarm"
      Environment = var.environment
      Severity    = "critical"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  count = var.enable_lambda_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = var.throttle_threshold
  alarm_description   = "Lambda function throttles exceed threshold"
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.primary_function_name
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-lambda-throttle-alarm"
      Environment = var.environment
      Severity    = "critical"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "lambda_cold_starts" {
  count = var.enable_lambda_alarms && var.monitor_cold_starts ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-lambda-cold-starts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "init_duration"
  namespace           = "LambdaInsights"
  period              = 300
  statistic           = "Average"
  threshold           = var.cold_start_threshold_ms
  alarm_description   = "Lambda cold start duration exceeds threshold"
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    function_name = var.primary_function_name
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-lambda-cold-start-alarm"
      Environment = var.environment
      Severity    = "info"
    }
  )
}

# ==============================================================================
# CloudWatch Dashboard for Lambda Insights
# ==============================================================================

resource "aws_cloudwatch_dashboard" "lambda_insights" {
  count = var.enable_lambda_dashboard ? 1 : 0

  dashboard_name = "${var.project_name}-${var.environment}-lambda-insights"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["LambdaInsights", "duration_max", { "stat" : "Maximum", "label" : "Max Duration" }],
            ["...", { "stat" : "Average", "label" : "Avg Duration" }],
            ["...", { "stat" : "p99", "label" : "P99 Duration" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Lambda Duration"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["LambdaInsights", "memory_utilization", { "stat" : "Average" }],
            ["AWS/Lambda", "ConcurrentExecutions", { "stat" : "Maximum" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Memory Utilization & Concurrency"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { "stat" : "Sum", "label" : "Invocations" }],
            [".", "Errors", { "stat" : "Sum", "label" : "Errors" }],
            [".", "Throttles", { "stat" : "Sum", "label" : "Throttles" }]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Lambda Invocations & Errors"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["LambdaInsights", "init_duration", { "stat" : "Average", "label" : "Cold Start Duration" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Lambda Cold Starts"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["LambdaInsights", "total_network", { "stat" : "Sum", "label" : "Network I/O" }],
            [".", "rx_bytes", { "stat" : "Sum", "label" : "Received" }],
            [".", "tx_bytes", { "stat" : "Sum", "label" : "Transmitted" }]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Lambda Network Traffic"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["LambdaInsights", "cpu_total_time", { "stat" : "Sum" }]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Lambda CPU Time"
        }
      },
      {
        type = "log"
        properties = {
          query   = "SOURCE '${aws_cloudwatch_log_group.lambda_insights.name}' | fields @timestamp, function_name, duration, memory_utilization | sort @timestamp desc | limit 100"
          region  = data.aws_region.current.name
          title   = "Recent Lambda Insights Metrics"
          stacked = false
        }
      }
    ]
  })
}

# ==============================================================================
# CloudWatch Insights Queries
# ==============================================================================

resource "aws_cloudwatch_query_definition" "lambda_performance" {
  name = "${var.project_name}-${var.environment}-lambda-performance"

  log_group_names = [
    aws_cloudwatch_log_group.lambda_insights.name
  ]

  query_string = <<-EOT
    fields @timestamp, function_name, duration, memory_utilization, init_duration
    | filter ispresent(duration)
    | stats avg(duration) as avg_duration, max(duration) as max_duration, avg(memory_utilization) as avg_memory, count(*) as invocations by function_name
    | sort avg_duration desc
  EOT
}

resource "aws_cloudwatch_query_definition" "lambda_cold_starts" {
  name = "${var.project_name}-${var.environment}-lambda-cold-starts"

  log_group_names = [
    aws_cloudwatch_log_group.lambda_insights.name
  ]

  query_string = <<-EOT
    fields @timestamp, function_name, init_duration
    | filter ispresent(init_duration)
    | stats count(*) as cold_starts, avg(init_duration) as avg_init_duration, max(init_duration) as max_init_duration by function_name
    | sort cold_starts desc
  EOT
}

resource "aws_cloudwatch_query_definition" "lambda_errors" {
  name = "${var.project_name}-${var.environment}-lambda-errors"

  log_group_names = var.lambda_log_group_names

  query_string = <<-EOT
    fields @timestamp, @message
    | filter @message like /ERROR/ or @message like /Exception/ or @message like /error/
    | sort @timestamp desc
    | limit 100
  EOT
}

resource "aws_cloudwatch_query_definition" "lambda_memory_analysis" {
  name = "${var.project_name}-${var.environment}-lambda-memory-analysis"

  log_group_names = [
    aws_cloudwatch_log_group.lambda_insights.name
  ]

  query_string = <<-EOT
    fields @timestamp, function_name, used_memory_max, memory_utilization
    | filter ispresent(used_memory_max)
    | stats max(used_memory_max) as max_memory_used, avg(memory_utilization) as avg_utilization by function_name
    | sort max_memory_used desc
  EOT
}

# ==============================================================================
# Lambda Insights Configuration Output
# ==============================================================================

locals {
  lambda_insights_config = {
    layer_arn = local.lambda_insights_layer_arn
    policy_arn = aws_iam_policy.lambda_insights.arn
    environment_variables = {
      AWS_LAMBDA_EXEC_WRAPPER     = "/opt/otel-instrument"
      LAMBDA_INSIGHTS_LOG_LEVEL   = var.insights_log_level
      LAMBDA_INSIGHTS_MULTI_LINE  = "true"
    }
  }
}
