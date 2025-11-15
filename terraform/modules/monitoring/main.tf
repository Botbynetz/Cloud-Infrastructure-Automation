# ==============================================================================
# CloudWatch Monitoring Module
# ==============================================================================
# Comprehensive monitoring with dashboards, alarms, and log aggregation

terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ==============================================================================
# Data Sources
# ==============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ==============================================================================
# CloudWatch Log Groups
# ==============================================================================

resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/${var.project_name}/${var.environment}/application"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.enable_log_encryption ? aws_kms_key.logs[0].arn : null
  
  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-app-logs"
    Environment = var.environment
    Type        = "application"
  })
}

resource "aws_cloudwatch_log_group" "infrastructure" {
  name              = "/aws/${var.project_name}/${var.environment}/infrastructure"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.enable_log_encryption ? aws_kms_key.logs[0].arn : null
  
  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-infra-logs"
    Environment = var.environment
    Type        = "infrastructure"
  })
}

resource "aws_cloudwatch_log_group" "security" {
  name              = "/aws/${var.project_name}/${var.environment}/security"
  retention_in_days = var.security_log_retention_days
  kms_key_id        = var.enable_log_encryption ? aws_kms_key.logs[0].arn : null
  
  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-security-logs"
    Environment = var.environment
    Type        = "security"
  })
}

resource "aws_cloudwatch_log_group" "audit" {
  name              = "/aws/${var.project_name}/${var.environment}/audit"
  retention_in_days = 365 # Keep audit logs for 1 year
  kms_key_id        = var.enable_log_encryption ? aws_kms_key.logs[0].arn : null
  
  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-audit-logs"
    Environment = var.environment
    Type        = "audit"
  })
}

# ==============================================================================
# KMS Key for Log Encryption
# ==============================================================================

resource "aws_kms_key" "logs" {
  count                   = var.enable_log_encryption ? 1 : 0
  description             = "KMS key for CloudWatch Logs encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-logs-key"
  })
}

resource "aws_kms_alias" "logs" {
  count         = var.enable_log_encryption ? 1 : 0
  name          = "alias/${var.project_name}-${var.environment}-logs"
  target_key_id = aws_kms_key.logs[0].key_id
}

# ==============================================================================
# CloudWatch Dashboard - Infrastructure Overview
# ==============================================================================

resource "aws_cloudwatch_dashboard" "infrastructure" {
  dashboard_name = "${var.project_name}-${var.environment}-infrastructure"
  
  dashboard_body = jsonencode({
    widgets = [
      # EC2 CPU Utilization
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average", period = 300 }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "EC2 CPU Utilization"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
        width  = 12
        height = 6
        x      = 0
        y      = 0
      },
      # EC2 Network In/Out
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn", { stat = "Sum", period = 300, label = "Network In" }],
            [".", "NetworkOut", { stat = "Sum", period = 300, label = "Network Out" }]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "EC2 Network Traffic"
        }
        width  = 12
        height = 6
        x      = 12
        y      = 0
      },
      # EBS Volume Read/Write
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EBS", "VolumeReadBytes", { stat = "Sum", period = 300 }],
            [".", "VolumeWriteBytes", { stat = "Sum", period = 300 }]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "EBS Volume I/O"
        }
        width  = 12
        height = 6
        x      = 0
        y      = 6
      },
      # Application Load Balancer
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", { stat = "Sum", period = 300 }],
            [".", "TargetResponseTime", { stat = "Average", period = 300 }],
            [".", "HTTPCode_Target_4XX_Count", { stat = "Sum", period = 300 }],
            [".", "HTTPCode_Target_5XX_Count", { stat = "Sum", period = 300 }]
          ]
          period = 300
          region = data.aws_region.current.name
          title  = "Application Load Balancer Metrics"
        }
        width  = 12
        height = 6
        x      = 12
        y      = 6
      },
      # RDS Database Performance
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", { stat = "Average", period = 300 }],
            [".", "DatabaseConnections", { stat = "Average", period = 300 }],
            [".", "FreeStorageSpace", { stat = "Average", period = 300 }]
          ]
          period = 300
          region = data.aws_region.current.name
          title  = "RDS Database Metrics"
        }
        width  = 24
        height = 6
        x      = 0
        y      = 12
      }
    ]
  })
}

# ==============================================================================
# CloudWatch Dashboard - Application Performance
# ==============================================================================

resource "aws_cloudwatch_dashboard" "application" {
  dashboard_name = "${var.project_name}-${var.environment}-application"
  
  dashboard_body = jsonencode({
    widgets = [
      # Request Count
      {
        type = "metric"
        properties = {
          metrics = [
            ["${var.project_name}/${var.environment}", "RequestCount", { stat = "Sum", period = 60 }]
          ]
          period = 60
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Application Request Count"
        }
        width  = 8
        height = 6
        x      = 0
        y      = 0
      },
      # Response Time
      {
        type = "metric"
        properties = {
          metrics = [
            ["${var.project_name}/${var.environment}", "ResponseTime", { stat = "Average", period = 60 }],
            ["...", { stat = "p99", period = 60 }]
          ]
          period = 60
          region = data.aws_region.current.name
          title  = "Application Response Time"
        }
        width  = 8
        height = 6
        x      = 8
        y      = 0
      },
      # Error Rate
      {
        type = "metric"
        properties = {
          metrics = [
            ["${var.project_name}/${var.environment}", "ErrorCount", { stat = "Sum", period = 60 }],
            [".", "4xxErrors", { stat = "Sum", period = 60 }],
            [".", "5xxErrors", { stat = "Sum", period = 60 }]
          ]
          period = 60
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Application Errors"
        }
        width  = 8
        height = 6
        x      = 16
        y      = 0
      },
      # Memory Utilization
      {
        type = "metric"
        properties = {
          metrics = [
            ["${var.project_name}/${var.environment}", "MemoryUtilization", { stat = "Average", period = 300 }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Memory Utilization"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
        width  = 12
        height = 6
        x      = 0
        y      = 6
      },
      # Disk Usage
      {
        type = "metric"
        properties = {
          metrics = [
            ["${var.project_name}/${var.environment}", "DiskUtilization", { stat = "Average", period = 300 }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Disk Utilization"
        }
        width  = 12
        height = 6
        x      = 12
        y      = 6
      }
    ]
  })
}

# ==============================================================================
# CloudWatch Dashboard - Cost & Usage
# ==============================================================================

resource "aws_cloudwatch_dashboard" "cost" {
  dashboard_name = "${var.project_name}-${var.environment}-cost"
  
  dashboard_body = jsonencode({
    widgets = [
      # Estimated Charges
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Billing", "EstimatedCharges", { stat = "Maximum", period = 21600 }]
          ]
          period = 21600
          stat   = "Maximum"
          region = "us-east-1" # Billing metrics only in us-east-1
          title  = "Estimated AWS Charges"
        }
        width  = 12
        height = 6
        x      = 0
        y      = 0
      },
      # EC2 Usage
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Usage", "ResourceCount", { stat = "Average", period = 300 }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Resource Usage"
        }
        width  = 12
        height = 6
        x      = 12
        y      = 0
      }
    ]
  })
}

# ==============================================================================
# CloudWatch Dashboard - Security
# ==============================================================================

resource "aws_cloudwatch_dashboard" "security" {
  dashboard_name = "${var.project_name}-${var.environment}-security"
  
  dashboard_body = jsonencode({
    widgets = [
      # Failed Login Attempts
      {
        type = "log"
        properties = {
          query   = "SOURCE '${aws_cloudwatch_log_group.security.name}' | fields @timestamp, @message | filter @message like /failed login/ | stats count() by bin(5m)"
          region  = data.aws_region.current.name
          title   = "Failed Login Attempts"
        }
        width  = 12
        height = 6
        x      = 0
        y      = 0
      },
      # Unauthorized Access Attempts
      {
        type = "log"
        properties = {
          query   = "SOURCE '${aws_cloudwatch_log_group.security.name}' | fields @timestamp, @message | filter @message like /unauthorized/ or @message like /403/ | stats count() by bin(5m)"
          region  = data.aws_region.current.name
          title   = "Unauthorized Access Attempts"
        }
        width  = 12
        height = 6
        x      = 12
        y      = 0
      },
      # Security Events Timeline
      {
        type = "log"
        properties = {
          query   = "SOURCE '${aws_cloudwatch_log_group.security.name}' | fields @timestamp, @message | sort @timestamp desc | limit 100"
          region  = data.aws_region.current.name
          title   = "Recent Security Events"
        }
        width  = 24
        height = 6
        x      = 0
        y      = 6
      }
    ]
  })
}

# ==============================================================================
# CloudWatch Alarms - Infrastructure
# ==============================================================================

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  alarm_description   = "This metric monitors EC2 CPU utilization"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions
  
  tags = merge(var.tags, {
    Name     = "${var.project_name}-${var.environment}-high-cpu-alarm"
    Severity = "high"
  })
}

resource "aws_cloudwatch_metric_alarm" "high_memory" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "${var.project_name}/${var.environment}"
  period              = 300
  statistic           = "Average"
  threshold           = var.memory_alarm_threshold
  alarm_description   = "This metric monitors memory utilization"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions
  
  tags = merge(var.tags, {
    Name     = "${var.project_name}-${var.environment}-high-memory-alarm"
    Severity = "high"
  })
}

resource "aws_cloudwatch_metric_alarm" "disk_full" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-disk-full"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DiskUtilization"
  namespace           = "${var.project_name}/${var.environment}"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Disk utilization is critically high"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions
  
  tags = merge(var.tags, {
    Name     = "${var.project_name}-${var.environment}-disk-full-alarm"
    Severity = "critical"
  })
}

# ==============================================================================
# CloudWatch Alarms - Application
# ==============================================================================

resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5xxErrors"
  namespace           = "${var.project_name}/${var.environment}"
  period              = 60
  statistic           = "Sum"
  threshold           = var.error_rate_threshold
  alarm_description   = "Application error rate is high"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions
  
  tags = merge(var.tags, {
    Name     = "${var.project_name}-${var.environment}-high-error-rate-alarm"
    Severity = "high"
  })
}

resource "aws_cloudwatch_metric_alarm" "slow_response_time" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-slow-response"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "ResponseTime"
  namespace           = "${var.project_name}/${var.environment}"
  period              = 60
  statistic           = "Average"
  threshold           = var.response_time_threshold
  alarm_description   = "Application response time is slow"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions
  
  tags = merge(var.tags, {
    Name     = "${var.project_name}-${var.environment}-slow-response-alarm"
    Severity = "medium"
  })
}

# ==============================================================================
# CloudWatch Alarms - Database
# ==============================================================================

resource "aws_cloudwatch_metric_alarm" "database_cpu" {
  count               = var.enable_alarms && var.enable_database_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-database-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU utilization is high"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions
  
  tags = merge(var.tags, {
    Name     = "${var.project_name}-${var.environment}-database-cpu-alarm"
    Severity = "high"
  })
}

resource "aws_cloudwatch_metric_alarm" "database_connections" {
  count               = var.enable_alarms && var.enable_database_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-database-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.database_connections_threshold
  alarm_description   = "Database connection count is high"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions
  
  tags = merge(var.tags, {
    Name     = "${var.project_name}-${var.environment}-database-connections-alarm"
    Severity = "medium"
  })
}

# ==============================================================================
# CloudWatch Composite Alarm
# ==============================================================================

resource "aws_cloudwatch_composite_alarm" "application_health" {
  count             = var.enable_alarms ? 1 : 0
  alarm_name        = "${var.project_name}-${var.environment}-application-unhealthy"
  alarm_description = "Composite alarm for overall application health"
  
  alarm_actions = var.alarm_actions
  ok_actions    = var.alarm_actions
  
  alarm_rule = join(" OR ", [
    "ALARM(${aws_cloudwatch_metric_alarm.high_cpu[0].alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.high_memory[0].alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.high_error_rate[0].alarm_name})"
  ])
  
  tags = merge(var.tags, {
    Name     = "${var.project_name}-${var.environment}-app-health-alarm"
    Severity = "critical"
  })
}

# ==============================================================================
# CloudWatch Log Metric Filters
# ==============================================================================

resource "aws_cloudwatch_log_metric_filter" "error_count" {
  name           = "${var.project_name}-${var.environment}-error-count"
  log_group_name = aws_cloudwatch_log_group.application.name
  pattern        = "[time, request_id, level = ERROR*, ...]"
  
  metric_transformation {
    name      = "ErrorCount"
    namespace = "${var.project_name}/${var.environment}"
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_log_metric_filter" "warning_count" {
  name           = "${var.project_name}-${var.environment}-warning-count"
  log_group_name = aws_cloudwatch_log_group.application.name
  pattern        = "[time, request_id, level = WARN*, ...]"
  
  metric_transformation {
    name      = "WarningCount"
    namespace = "${var.project_name}/${var.environment}"
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_log_metric_filter" "security_events" {
  name           = "${var.project_name}-${var.environment}-security-events"
  log_group_name = aws_cloudwatch_log_group.security.name
  pattern        = "[time, event_type = SecurityEvent*, ...]"
  
  metric_transformation {
    name      = "SecurityEventCount"
    namespace = "${var.project_name}/${var.environment}"
    value     = "1"
    unit      = "Count"
  }
}

# ==============================================================================
# CloudWatch Insights Query Definitions
# ==============================================================================

resource "aws_cloudwatch_query_definition" "top_errors" {
  name = "${var.project_name}/${var.environment}/TopErrors"
  
  log_group_names = [
    aws_cloudwatch_log_group.application.name
  ]
  
  query_string = <<-QUERY
    fields @timestamp, @message
    | filter @message like /ERROR/
    | stats count() as error_count by @message
    | sort error_count desc
    | limit 20
  QUERY
}

resource "aws_cloudwatch_query_definition" "slow_requests" {
  name = "${var.project_name}/${var.environment}/SlowRequests"
  
  log_group_names = [
    aws_cloudwatch_log_group.application.name
  ]
  
  query_string = <<-QUERY
    fields @timestamp, @message, duration
    | filter duration > 1000
    | sort duration desc
    | limit 50
  QUERY
}

resource "aws_cloudwatch_query_definition" "security_audit" {
  name = "${var.project_name}/${var.environment}/SecurityAudit"
  
  log_group_names = [
    aws_cloudwatch_log_group.security.name
  ]
  
  query_string = <<-QUERY
    fields @timestamp, user, action, resource, result
    | filter result = "DENIED" or result = "FAILED"
    | sort @timestamp desc
    | limit 100
  QUERY
}
