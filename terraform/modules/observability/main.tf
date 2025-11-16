# ==============================================================================
# Observability 2.0 Module
# Unified Observability: Metrics + Logs + Traces + SLOs
# ==============================================================================

terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

# ------------------------------------------------------------------------------
# CloudWatch Log Groups
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "app_logs" {
  name = "/aws/${var.project_name}/${var.environment}/app"
  retention_in_days = var.log_retention_days
  kms_key_id = var.kms_key_id
  tags = var.tags
}

resource "aws_cloudwatch_log_group" "trace_logs" {
  name = "/aws/${var.project_name}/${var.environment}/traces"
  retention_in_days = var.log_retention_days
  kms_key_id = var.kms_key_id
  tags = var.tags
}

# ------------------------------------------------------------------------------
# X-Ray for Distributed Tracing
# ------------------------------------------------------------------------------

resource "aws_xray_sampling_rule" "default" {
  rule_name = "${var.project_name}-sampling-${var.environment}"
  priority = 1000
  version = 1
  reservoir_size = 10
  fixed_rate = 0.1  # 10% sampling
  url_path = "*"
  host = "*"
  http_method = "*"
  service_type = "*"
  service_name = "*"
  resource_arn = "*"
  
  attributes = {}
  tags = var.tags
}

# ------------------------------------------------------------------------------
# DynamoDB for SLO Tracking
# ------------------------------------------------------------------------------

resource "aws_dynamodb_table" "slo_tracking" {
  name = "${var.project_name}-slo-tracking-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "slo_id"
  range_key = "timestamp"

  attribute {
    name = "slo_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  ttl {
    attribute_name = "ttl"
    enabled = true
  }

  tags = merge(var.tags, {
    Name = "SLO Tracking"
  })
}

# ------------------------------------------------------------------------------
# CloudWatch Synthetic Monitoring (Canaries)
# ------------------------------------------------------------------------------

resource "aws_synthetics_canary" "api_health" {
  name = "${var.project_name}-api-health-${var.environment}"
  artifact_s3_location = "s3://${aws_s3_bucket.synthetics_artifacts.bucket}/canary-results"
  execution_role_arn = aws_iam_role.synthetics_role.arn
  handler = "apiCanaryBlueprint.handler"
  zip_file = data.archive_file.canary_script.output_path
  runtime_version = "syn-nodejs-puppeteer-6.2"

  schedule {
    expression = "rate(5 minutes)"
  }

  run_config {
    timeout_in_seconds = 60
    memory_in_mb = 960
    active_tracing = true
  }

  success_retention_period = 31
  failure_retention_period = 31

  tags = var.tags
}

data "archive_file" "canary_script" {
  type = "zip"
  output_path = "${path.module}/canary.zip"
  source {
    content = <<-EOF
      const synthetics = require('Synthetics');
      const log = require('SyntheticsLogger');

      const apiCanaryBlueprint = async function () {
        const url = process.env.API_ENDPOINT || 'https://example.com/health';
        const requestOptions = { method: 'GET', timeout: 5000 };
        
        await synthetics.executeHttpStep('ApiHealthCheck', url, requestOptions, function(res) {
          if (res.statusCode < 200 || res.statusCode > 299) {
            throw new Error('Health check failed with status ' + res.statusCode);
          }
        });
      };

      exports.handler = async () => {
        return await apiCanaryBlueprint();
      };
    EOF
    filename = "nodejs/node_modules/apiCanaryBlueprint.js"
  }
}

resource "aws_s3_bucket" "synthetics_artifacts" {
  bucket = "${var.project_name}-synthetics-${var.environment}"
  tags = var.tags
}

resource "aws_iam_role" "synthetics_role" {
  name = "${var.project_name}-synthetics-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "synthetics_policy" {
  role = aws_iam_role.synthetics_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchSyntheticsFullAccess"
}

# ------------------------------------------------------------------------------
# CloudWatch Composite Alarm (SLO Burn Rate)
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "error_rate_high" {
  alarm_name = "${var.project_name}-error-rate-high-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "5XXError"
  namespace = "AWS/ApiGateway"
  period = 300
  statistic = "Sum"
  threshold = 10
  alarm_description = "Error rate exceeds threshold"
  treat_missing_data = "notBreaching"
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "latency_high" {
  alarm_name = "${var.project_name}-latency-high-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Latency"
  namespace = "AWS/ApiGateway"
  period = 300
  statistic = "Average"
  threshold = 1000  # 1s
  alarm_description = "Latency exceeds 1 second"
  treat_missing_data = "notBreaching"
  tags = var.tags
}

resource "aws_cloudwatch_composite_alarm" "slo_burn_rate" {
  alarm_name = "${var.project_name}-slo-burn-rate-${var.environment}"
  alarm_description = "SLO error budget burn rate too fast"
  actions_enabled = true
  alarm_actions = [var.sns_topic_arn]
  
  alarm_rule = "ALARM(${aws_cloudwatch_metric_alarm.error_rate_high.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.latency_high.alarm_name})"
  
  tags = var.tags
}

# ------------------------------------------------------------------------------
# CloudWatch Dashboard (Unified Observability)
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "observability" {
  dashboard_name = "${var.project_name}-observability-${var.environment}"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title = "API Request Rate"
          metrics = [
            ["AWS/ApiGateway", "Count", { stat = "Sum", label = "Requests" }]
          ]
          period = 300
          stat = "Sum"
          region = var.aws_region
          yAxis = { left = { min = 0 } }
        }
      },
      {
        type = "metric"
        properties = {
          title = "API Error Rate (5XX)"
          metrics = [
            ["AWS/ApiGateway", "5XXError", { stat = "Sum", color = "#d62728" }]
          ]
          period = 300
          stat = "Sum"
          region = var.aws_region
        }
      },
      {
        type = "metric"
        properties = {
          title = "API Latency (P50, P95, P99)"
          metrics = [
            ["AWS/ApiGateway", "Latency", { stat = "p50", label = "P50" }],
            ["...", { stat = "p95", label = "P95", color = "#ff7f0e" }],
            ["...", { stat = "p99", label = "P99", color = "#d62728" }]
          ]
          period = 300
          region = var.aws_region
          yAxis = { left = { min = 0 } }
        }
      },
      {
        type = "metric"
        properties = {
          title = "X-Ray Trace Count"
          metrics = [
            ["AWS/XRay", "TraceCount", { stat = "Sum" }]
          ]
          period = 300
          stat = "Sum"
          region = var.aws_region
        }
      },
      {
        type = "metric"
        properties = {
          title = "Canary Success Rate"
          metrics = [
            ["AWS/Synthetics", "SuccessPercent", { stat = "Average", label = "Success %" }]
          ]
          period = 300
          stat = "Average"
          region = var.aws_region
          yAxis = { left = { min = 0, max = 100 } }
        }
      },
      {
        type = "log"
        properties = {
          title = "Recent Error Logs"
          query = "SOURCE '${aws_cloudwatch_log_group.app_logs.name}' | fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20"
          region = var.aws_region
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# CloudWatch Insights Query for SLO Calculation
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_query_definition" "slo_availability" {
  name = "${var.project_name}/slo-availability"
  log_group_names = [aws_cloudwatch_log_group.app_logs.name]
  
  query_string = <<-QUERY
    fields @timestamp, status_code
    | filter status_code >= 200
    | stats count() as total_requests, 
            sum(status_code < 500) as successful_requests
    | fields (successful_requests / total_requests) * 100 as availability_percent
  QUERY
}

# ------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------

output "log_group_name" {
  description = "CloudWatch Log Group name"
  value = aws_cloudwatch_log_group.app_logs.name
}

output "trace_log_group" {
  description = "X-Ray trace log group"
  value = aws_cloudwatch_log_group.trace_logs.name
}

output "canary_name" {
  description = "Synthetics canary name"
  value = aws_synthetics_canary.api_health.name
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.observability.dashboard_name}"
}

output "slo_tracking_table" {
  description = "SLO tracking DynamoDB table"
  value = aws_dynamodb_table.slo_tracking.name
}
