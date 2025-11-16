# ==============================================================================
# Application Insights Module - Custom Metrics & Anomaly Detection
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
# CloudWatch Anomaly Detector for Application Metrics
# ==============================================================================

resource "aws_cloudwatch_anomaly_detector" "response_time" {
  count = var.enable_anomaly_detection ? 1 : 0

  namespace   = var.application_namespace
  metric_name = "ResponseTime"
  stat        = "Average"

  dimensions = {
    Environment = var.environment
  }
}

resource "aws_cloudwatch_anomaly_detector" "request_count" {
  count = var.enable_anomaly_detection ? 1 : 0

  namespace   = var.application_namespace
  metric_name = "RequestCount"
  stat        = "Sum"

  dimensions = {
    Environment = var.environment
  }
}

resource "aws_cloudwatch_anomaly_detector" "error_rate" {
  count = var.enable_anomaly_detection ? 1 : 0

  namespace   = var.application_namespace
  metric_name = "ErrorRate"
  stat        = "Average"

  dimensions = {
    Environment = var.environment
  }
}

resource "aws_cloudwatch_anomaly_detector" "database_connections" {
  count = var.enable_database_monitoring ? 1 : 0

  namespace   = var.application_namespace
  metric_name = "DatabaseConnections"
  stat        = "Average"

  dimensions = {
    Environment = var.environment
  }
}

# ==============================================================================
# CloudWatch Metric Alarms with Anomaly Detection
# ==============================================================================

resource "aws_cloudwatch_metric_alarm" "response_time_anomaly" {
  count = var.enable_anomaly_detection ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-response-time-anomaly"
  comparison_operator = "GreaterThanUpperThreshold"
  evaluation_periods  = 2
  threshold_metric_id = "ad1"
  alarm_description   = "Response time shows anomalous behavior"
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "m1"
    return_data = true
    metric {
      metric_name = "ResponseTime"
      namespace   = var.application_namespace
      period      = 300
      stat        = "Average"
      dimensions = {
        Environment = var.environment
      }
    }
  }

  metric_query {
    id          = "ad1"
    expression  = "ANOMALY_DETECTION_BAND(m1, ${var.anomaly_detection_band})"
    label       = "ResponseTime (expected)"
    return_data = true
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-response-anomaly"
      Environment = var.environment
      Severity    = "warning"
      Type        = "anomaly"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "error_rate_anomaly" {
  count = var.enable_anomaly_detection ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-error-rate-anomaly"
  comparison_operator = "GreaterThanUpperThreshold"
  evaluation_periods  = 2
  threshold_metric_id = "ad1"
  alarm_description   = "Error rate shows anomalous behavior"
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "m1"
    return_data = true
    metric {
      metric_name = "ErrorRate"
      namespace   = var.application_namespace
      period      = 300
      stat        = "Average"
      dimensions = {
        Environment = var.environment
      }
    }
  }

  metric_query {
    id          = "ad1"
    expression  = "ANOMALY_DETECTION_BAND(m1, ${var.anomaly_detection_band})"
    label       = "ErrorRate (expected)"
    return_data = true
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-error-anomaly"
      Environment = var.environment
      Severity    = "critical"
      Type        = "anomaly"
    }
  )
}

# ==============================================================================
# Custom CloudWatch Metrics via Metric Filters
# ==============================================================================

resource "aws_cloudwatch_log_metric_filter" "business_transactions" {
  count = var.enable_business_metrics ? 1 : 0

  name           = "${var.project_name}-${var.environment}-business-transactions"
  pattern        = var.business_transaction_pattern
  log_group_name = var.application_log_group_name

  metric_transformation {
    name      = "BusinessTransactions"
    namespace = var.application_namespace
    value     = "1"
    unit      = "Count"
    dimensions = {
      Environment    = var.environment
      TransactionType = "$transactionType"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "user_signups" {
  count = var.enable_business_metrics ? 1 : 0

  name           = "${var.project_name}-${var.environment}-user-signups"
  pattern        = "[time, request_id, event=USER_SIGNUP, ...]"
  log_group_name = var.application_log_group_name

  metric_transformation {
    name      = "UserSignups"
    namespace = var.application_namespace
    value     = "1"
    unit      = "Count"
    dimensions = {
      Environment = var.environment
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "api_response_time" {
  count = var.enable_performance_metrics ? 1 : 0

  name           = "${var.project_name}-${var.environment}-api-response-time"
  pattern        = "[time, request_id, level, method, endpoint, status_code, response_time_ms]"
  log_group_name = var.application_log_group_name

  metric_transformation {
    name      = "ApiResponseTime"
    namespace = var.application_namespace
    value     = "$response_time_ms"
    unit      = "Milliseconds"
    dimensions = {
      Environment = var.environment
      Endpoint    = "$endpoint"
      Method      = "$method"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "cache_hit_rate" {
  count = var.enable_cache_metrics ? 1 : 0

  name           = "${var.project_name}-${var.environment}-cache-hits"
  pattern        = "[time, request_id, event=CACHE_HIT, cache_key]"
  log_group_name = var.application_log_group_name

  metric_transformation {
    name      = "CacheHits"
    namespace = var.application_namespace
    value     = "1"
    unit      = "Count"
    dimensions = {
      Environment = var.environment
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "cache_miss_rate" {
  count = var.enable_cache_metrics ? 1 : 0

  name           = "${var.project_name}-${var.environment}-cache-misses"
  pattern        = "[time, request_id, event=CACHE_MISS, cache_key]"
  log_group_name = var.application_log_group_name

  metric_transformation {
    name      = "CacheMisses"
    namespace = var.application_namespace
    value     = "1"
    unit      = "Count"
    dimensions = {
      Environment = var.environment
    }
  }
}

# ==============================================================================
# CloudWatch Contributor Insights Rules
# ==============================================================================

resource "aws_cloudwatch_log_contributor_insights_rule" "top_error_endpoints" {
  count = var.enable_contributor_insights ? 1 : 0

  name           = "${var.project_name}-${var.environment}-top-error-endpoints"
  log_group_name = var.application_log_group_name

  rule_body = jsonencode({
    Schema = {
      Name    = "CloudWatchLogRule"
      Version = 1
    }
    AggregateOn = "Count"
    Contribution = {
      Filters = [
        {
          Match = "$.level"
          In    = ["ERROR", "FATAL"]
        }
      ]
      Keys = [
        "$.endpoint"
      ]
    }
    LogFormat  = "JSON"
    LogGroupNames = [
      var.application_log_group_name
    ]
  })

  state = "ENABLED"
}

resource "aws_cloudwatch_log_contributor_insights_rule" "top_users_by_requests" {
  count = var.enable_contributor_insights ? 1 : 0

  name           = "${var.project_name}-${var.environment}-top-users"
  log_group_name = var.application_log_group_name

  rule_body = jsonencode({
    Schema = {
      Name    = "CloudWatchLogRule"
      Version = 1
    }
    AggregateOn = "Count"
    Contribution = {
      Keys = [
        "$.user_id"
      ]
    }
    LogFormat  = "JSON"
    LogGroupNames = [
      var.application_log_group_name
    ]
  })

  state = "ENABLED"
}

# ==============================================================================
# CloudWatch Synthetics Canary (Endpoint Monitoring)
# ==============================================================================

resource "aws_synthetics_canary" "api_health" {
  count = var.enable_synthetics ? 1 : 0

  name                 = "${var.project_name}-${var.environment}-api-health"
  artifact_s3_location = "s3://${var.synthetics_bucket_name}/canary-artifacts/"
  execution_role_arn   = aws_iam_role.synthetics[0].arn
  handler              = "apiCanaryBlueprint.handler"
  zip_file             = "${path.module}/canary/api-health.zip"
  runtime_version      = "syn-python-selenium-3.0"
  start_canary         = true

  schedule {
    expression = var.synthetics_schedule
  }

  run_config {
    timeout_in_seconds = 300
    memory_in_mb       = 960
    active_tracing     = var.enable_xray_tracing
  }

  success_retention_period = 2
  failure_retention_period = 14

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-synthetics"
      Environment = var.environment
    }
  )
}

resource "aws_iam_role" "synthetics" {
  count = var.enable_synthetics ? 1 : 0

  name = "${var.project_name}-${var.environment}-synthetics-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-synthetics-role"
      Environment = var.environment
    }
  )
}

resource "aws_iam_role_policy_attachment" "synthetics_basic" {
  count = var.enable_synthetics ? 1 : 0

  role       = aws_iam_role.synthetics[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchSyntheticsFullAccess"
}

# ==============================================================================
# CloudWatch Dashboard for Application Insights
# ==============================================================================

resource "aws_cloudwatch_dashboard" "application_insights" {
  count = var.enable_insights_dashboard ? 1 : 0

  dashboard_name = "${var.project_name}-${var.environment}-app-insights"

  dashboard_body = jsonencode({
    widgets = concat(
      [
        {
          type = "metric"
          properties = {
            metrics = [
              [var.application_namespace, "ResponseTime", { "stat" : "Average", "label" : "Avg Response Time" }],
              ["...", { "stat" : "p99", "label" : "P99 Response Time" }],
              ["ANOMALY_DETECTION_BAND", ".", { "label" : "Expected Range" }]
            ]
            period = 300
            stat   = "Average"
            region = data.aws_region.current.name
            title  = "Response Time with Anomaly Detection"
            yAxis = {
              left = { min = 0 }
            }
          }
        },
        {
          type = "metric"
          properties = {
            metrics = [
              [var.application_namespace, "RequestCount", { "stat" : "Sum" }],
              [var.application_namespace, "ErrorRate", { "stat" : "Average", "yAxis" : "right" }]
            ]
            period = 300
            stat   = "Sum"
            region = data.aws_region.current.name
            title  = "Request Volume & Error Rate"
            yAxis = {
              right = { min = 0, max = 100 }
            }
          }
        }
      ],
      var.enable_business_metrics ? [
        {
          type = "metric"
          properties = {
            metrics = [
              [var.application_namespace, "BusinessTransactions", { "stat" : "Sum" }],
              [var.application_namespace, "UserSignups", { "stat" : "Sum" }]
            ]
            period = 300
            stat   = "Sum"
            region = data.aws_region.current.name
            title  = "Business Metrics"
          }
        }
      ] : [],
      var.enable_cache_metrics ? [
        {
          type = "metric"
          properties = {
            metrics = [
              [var.application_namespace, "CacheHits", { "stat" : "Sum", "label" : "Cache Hits" }],
              [var.application_namespace, "CacheMisses", { "stat" : "Sum", "label" : "Cache Misses" }]
            ]
            period = 300
            stat   = "Sum"
            region = data.aws_region.current.name
            title  = "Cache Performance"
          }
        }
      ] : [],
      var.enable_synthetics ? [
        {
          type = "metric"
          properties = {
            metrics = [
              ["CloudWatchSynthetics", "SuccessPercent", { "stat" : "Average" }],
              [".", "Duration", { "stat" : "Average", "yAxis" : "right" }]
            ]
            period = 300
            stat   = "Average"
            region = data.aws_region.current.name
            title  = "Synthetic Monitoring"
          }
        }
      ] : []
    )
  })
}

# ==============================================================================
# CloudWatch Insights Queries for Application Analysis
# ==============================================================================

resource "aws_cloudwatch_query_definition" "slow_transactions" {
  name = "${var.project_name}-${var.environment}-slow-transactions"

  log_group_names = [var.application_log_group_name]

  query_string = <<-EOT
    fields @timestamp, endpoint, method, response_time_ms, user_id
    | filter response_time_ms > ${var.slow_transaction_threshold_ms}
    | sort response_time_ms desc
    | limit 50
  EOT
}

resource "aws_cloudwatch_query_definition" "error_patterns" {
  name = "${var.project_name}-${var.environment}-error-patterns"

  log_group_names = [var.application_log_group_name]

  query_string = <<-EOT
    fields @timestamp, level, message, endpoint, error_type
    | filter level in ["ERROR", "FATAL"]
    | stats count(*) as error_count by error_type, endpoint
    | sort error_count desc
  EOT
}

resource "aws_cloudwatch_query_definition" "user_activity" {
  name = "${var.project_name}-${var.environment}-user-activity"

  log_group_names = [var.application_log_group_name]

  query_string = <<-EOT
    fields @timestamp, user_id, event, endpoint
    | stats count(*) as action_count by user_id, event
    | sort action_count desc
    | limit 100
  EOT
}

resource "aws_cloudwatch_query_definition" "api_performance_by_endpoint" {
  name = "${var.project_name}-${var.environment}-api-performance"

  log_group_names = [var.application_log_group_name]

  query_string = <<-EOT
    fields @timestamp, endpoint, response_time_ms
    | stats avg(response_time_ms) as avg_response, 
            pct(response_time_ms, 99) as p99_response,
            max(response_time_ms) as max_response,
            count(*) as request_count
      by endpoint
    | sort avg_response desc
  EOT
}
