# ==============================================================================
# AWS X-Ray Tracing Module
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
# X-Ray Sampling Rules
# ==============================================================================

resource "aws_xray_sampling_rule" "default" {
  rule_name      = "${var.project_name}-${var.environment}-default"
  priority       = 10000
  version        = 1
  reservoir_size = var.default_reservoir_size
  fixed_rate     = var.default_sampling_rate
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = "*"
  resource_arn   = "*"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-default-sampling"
      Environment = var.environment
    }
  )
}

resource "aws_xray_sampling_rule" "high_priority" {
  count = var.enable_high_priority_sampling ? 1 : 0

  rule_name      = "${var.project_name}-${var.environment}-high-priority"
  priority       = 100
  version        = 1
  reservoir_size = var.high_priority_reservoir_size
  fixed_rate     = var.high_priority_sampling_rate
  url_path       = var.high_priority_url_pattern
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = var.service_name
  resource_arn   = "*"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-high-priority-sampling"
      Environment = var.environment
      Priority    = "high"
    }
  )
}

resource "aws_xray_sampling_rule" "api_endpoints" {
  count = var.enable_api_sampling ? 1 : 0

  rule_name      = "${var.project_name}-${var.environment}-api"
  priority       = 500
  version        = 1
  reservoir_size = var.api_reservoir_size
  fixed_rate     = var.api_sampling_rate
  url_path       = "/api/*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = var.service_name
  resource_arn   = "*"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-api-sampling"
      Environment = var.environment
      Type        = "api"
    }
  )
}

resource "aws_xray_sampling_rule" "error_traces" {
  count = var.enable_error_sampling ? 1 : 0

  rule_name      = "${var.project_name}-${var.environment}-errors"
  priority       = 50
  version        = 1
  reservoir_size = 10
  fixed_rate     = 1.0  # 100% sampling for errors
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = var.service_name
  resource_arn   = "*"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-error-sampling"
      Environment = var.environment
      Type        = "errors"
    }
  )
}

resource "aws_xray_sampling_rule" "slow_requests" {
  count = var.enable_slow_request_sampling ? 1 : 0

  rule_name      = "${var.project_name}-${var.environment}-slow"
  priority       = 200
  version        = 1
  reservoir_size = 5
  fixed_rate     = 1.0  # 100% sampling for slow requests
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = var.service_name
  resource_arn   = "*"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-slow-sampling"
      Environment = var.environment
      Type        = "performance"
    }
  )
}

# ==============================================================================
# X-Ray Group (for filtering and analysis)
# ==============================================================================

resource "aws_xray_group" "main" {
  group_name        = "${var.project_name}-${var.environment}"
  filter_expression = "service(\"${var.service_name}\")"

  insights_configuration {
    insights_enabled      = var.enable_insights
    notifications_enabled = var.enable_insights_notifications
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-xray-group"
      Environment = var.environment
    }
  )
}

resource "aws_xray_group" "errors" {
  count = var.enable_error_group ? 1 : 0

  group_name        = "${var.project_name}-${var.environment}-errors"
  filter_expression = "service(\"${var.service_name}\") AND error = true"

  insights_configuration {
    insights_enabled      = true
    notifications_enabled = true
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-errors"
      Environment = var.environment
      Type        = "errors"
    }
  )
}

resource "aws_xray_group" "slow_requests_group" {
  count = var.enable_slow_request_group ? 1 : 0

  group_name        = "${var.project_name}-${var.environment}-slow"
  filter_expression = "service(\"${var.service_name}\") AND duration >= ${var.slow_request_threshold}"

  insights_configuration {
    insights_enabled      = true
    notifications_enabled = var.enable_insights_notifications
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-slow-requests"
      Environment = var.environment
      Type        = "performance"
    }
  )
}

# ==============================================================================
# IAM Role for X-Ray (EC2/ECS/Lambda)
# ==============================================================================

resource "aws_iam_role" "xray" {
  count = var.create_xray_role ? 1 : 0

  name = "${var.project_name}-${var.environment}-xray-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "ec2.amazonaws.com",
            "ecs-tasks.amazonaws.com",
            "lambda.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-xray-role"
      Environment = var.environment
    }
  )
}

resource "aws_iam_role_policy_attachment" "xray_daemon" {
  count = var.create_xray_role ? 1 : 0

  role       = aws_iam_role.xray[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role_policy" "xray_custom" {
  count = var.create_xray_role ? 1 : 0

  name = "${var.project_name}-${var.environment}-xray-policy"
  role = aws_iam_role.xray[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets",
          "xray:GetSamplingStatisticSummaries"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "xray" {
  count = var.create_xray_role && var.create_instance_profile ? 1 : 0

  name = "${var.project_name}-${var.environment}-xray-profile"
  role = aws_iam_role.xray[0].name

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-xray-profile"
      Environment = var.environment
    }
  )
}

# ==============================================================================
# CloudWatch Alarms for X-Ray Metrics
# ==============================================================================

resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  count = var.enable_xray_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-xray-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FaultRate"
  namespace           = "AWS/XRay"
  period              = 300
  statistic           = "Average"
  threshold           = var.error_rate_threshold
  alarm_description   = "X-Ray error rate is above threshold"
  alarm_actions       = var.alarm_actions

  dimensions = {
    GroupName = aws_xray_group.main.group_name
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-xray-error-alarm"
      Environment = var.environment
      Severity    = "critical"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "high_latency" {
  count = var.enable_xray_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-xray-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "Duration"
  namespace           = "AWS/XRay"
  period              = 300
  statistic           = "Average"
  threshold           = var.latency_threshold
  alarm_description   = "X-Ray average latency is above threshold"
  alarm_actions       = var.alarm_actions

  dimensions = {
    GroupName = aws_xray_group.main.group_name
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-xray-latency-alarm"
      Environment = var.environment
      Severity    = "warning"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "throttle_rate" {
  count = var.enable_xray_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-xray-throttle"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ThrottleRate"
  namespace           = "AWS/XRay"
  period              = 300
  statistic           = "Average"
  threshold           = var.throttle_rate_threshold
  alarm_description   = "X-Ray throttle rate is above threshold"
  alarm_actions       = var.alarm_actions

  dimensions = {
    GroupName = aws_xray_group.main.group_name
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-xray-throttle-alarm"
      Environment = var.environment
      Severity    = "warning"
    }
  )
}

# ==============================================================================
# X-Ray Encryption Configuration (using KMS)
# ==============================================================================

resource "aws_xray_encryption_config" "main" {
  count = var.enable_encryption ? 1 : 0

  type   = var.kms_key_id != "" ? "KMS" : "NONE"
  key_id = var.kms_key_id != "" ? var.kms_key_id : null
}

# ==============================================================================
# Lambda Layer for X-Ray SDK (for Lambda functions)
# ==============================================================================

resource "aws_lambda_layer_version" "xray_sdk" {
  count = var.create_lambda_layer ? 1 : 0

  filename            = "${path.module}/lambda-layers/xray-sdk.zip"
  layer_name          = "${var.project_name}-${var.environment}-xray-sdk"
  compatible_runtimes = ["python3.11", "python3.10", "python3.9"]
  description         = "AWS X-Ray SDK for Python"

  lifecycle {
    create_before_destroy = true
  }
}

# ==============================================================================
# CloudWatch Dashboard for X-Ray Metrics
# ==============================================================================

resource "aws_cloudwatch_dashboard" "xray" {
  count = var.enable_xray_dashboard ? 1 : 0

  dashboard_name = "${var.project_name}-${var.environment}-xray"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/XRay", "FaultRate", { "stat" : "Average", "label" : "Error Rate (%)" }],
            [".", "ErrorRate", { "stat" : "Average", "label" : "4xx Error Rate (%)" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "X-Ray Error Rates"
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
            ["AWS/XRay", "Duration", { "stat" : "Average", "label" : "Average Duration" }],
            ["...", { "stat" : "p99", "label" : "P99 Duration" }],
            ["...", { "stat" : "p95", "label" : "P95 Duration" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "X-Ray Latency"
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
            ["AWS/XRay", "TracesRecorded", { "stat" : "Sum", "label" : "Traces Recorded" }],
            [".", "TracesIndexed", { "stat" : "Sum", "label" : "Traces Indexed" }]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "X-Ray Trace Volume"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/XRay", "ThrottleRate", { "stat" : "Average", "label" : "Throttle Rate (%)" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "X-Ray Throttling"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type = "log"
        properties = {
          query   = "SOURCE '${var.application_log_group_name}' | fields @timestamp, @message | filter @message like /X-Ray/ | sort @timestamp desc | limit 100"
          region  = data.aws_region.current.name
          title   = "X-Ray Application Logs"
          stacked = false
        }
      }
    ]
  })
}

# ==============================================================================
# Service Map Configuration
# ==============================================================================

# Note: Service Map is automatically generated by X-Ray from traces
# No explicit configuration needed, but we can create helpful documentation

locals {
  service_map_url = "https://console.aws.amazon.com/xray/home?region=${data.aws_region.current.name}#/service-map"
  traces_url      = "https://console.aws.amazon.com/xray/home?region=${data.aws_region.current.name}#/traces"
  analytics_url   = "https://console.aws.amazon.com/xray/home?region=${data.aws_region.current.name}#/analytics"
}
