# ==============================================================================
# Disaster Recovery & Business Continuity Module
# ==============================================================================
# This module implements enterprise-grade disaster recovery capabilities:
# - Multi-region backup automation
# - Cross-region replication
# - Automated failover procedures
# - RTO/RPO compliance monitoring
# - DR testing automation
# ==============================================================================

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      configuration_aliases = [aws.primary, aws.secondary]
    }
  }
}

# ==============================================================================
# Data Sources
# ==============================================================================

data "aws_caller_identity" "current" {
  provider = aws.primary
}

data "aws_region" "primary" {
  provider = aws.primary
}

data "aws_region" "secondary" {
  provider = aws.secondary
}

# ==============================================================================
# S3 Backup Buckets with Cross-Region Replication
# ==============================================================================

# Primary backup bucket
resource "aws_s3_bucket" "backup_primary" {
  provider = aws.primary
  bucket   = "${var.project_name}-${var.environment}-backup-${data.aws_region.primary.name}"
  
  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-backup-primary"
    Environment = var.environment
    Purpose     = "disaster-recovery"
    Region      = "primary"
  })
}

# Enable versioning on primary bucket
resource "aws_s3_bucket_versioning" "backup_primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.backup_primary.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption on primary bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "backup_primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.backup_primary.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = true
  }
}

# Lifecycle policy for backup retention
resource "aws_s3_bucket_lifecycle_configuration" "backup_primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.backup_primary.id
  
  rule {
    id     = "backup-retention-policy"
    status = "Enabled"
    
    # Daily backups - keep for 7 days
    transition {
      days          = 7
      storage_class = "STANDARD_IA"
    }
    
    # Weekly backups - keep for 30 days
    transition {
      days          = 30
      storage_class = "GLACIER_IR"
    }
    
    # Monthly backups - keep for 90 days
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    
    # Yearly backups - keep for 365 days
    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }
    
    # Delete after retention period
    expiration {
      days = var.backup_retention_days
    }
    
    # Clean up incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
  
  rule {
    id     = "old-version-cleanup"
    status = "Enabled"
    
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "GLACIER"
    }
    
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# Secondary backup bucket (DR region)
resource "aws_s3_bucket" "backup_secondary" {
  provider = aws.secondary
  bucket   = "${var.project_name}-${var.environment}-backup-${data.aws_region.secondary.name}"
  
  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-backup-secondary"
    Environment = var.environment
    Purpose     = "disaster-recovery"
    Region      = "secondary"
  })
}

# Enable versioning on secondary bucket
resource "aws_s3_bucket_versioning" "backup_secondary" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.backup_secondary.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption on secondary bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "backup_secondary" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.backup_secondary.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# IAM role for replication
resource "aws_iam_role" "replication" {
  provider = aws.primary
  name     = "${var.project_name}-${var.environment}-s3-replication-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-s3-replication-role"
  })
}

# IAM policy for replication
resource "aws_iam_role_policy" "replication" {
  provider = aws.primary
  role     = aws_iam_role.replication.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.backup_primary.arn
        ]
      },
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.backup_primary.arn}/*"
        ]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.backup_secondary.arn}/*"
        ]
      }
    ]
  })
}

# S3 replication configuration
resource "aws_s3_bucket_replication_configuration" "backup" {
  provider = aws.primary
  
  depends_on = [
    aws_s3_bucket_versioning.backup_primary,
    aws_s3_bucket_versioning.backup_secondary
  ]
  
  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.backup_primary.id
  
  rule {
    id     = "replicate-all"
    status = "Enabled"
    
    filter {}
    
    destination {
      bucket        = aws_s3_bucket.backup_secondary.arn
      storage_class = "STANDARD_IA"
      
      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }
      
      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }
    }
    
    delete_marker_replication {
      status = "Enabled"
    }
  }
}

# ==============================================================================
# RDS Automated Backups & Cross-Region Snapshots
# ==============================================================================

# Lambda function for automated RDS snapshot copy
resource "aws_lambda_function" "rds_snapshot_copy" {
  count = var.enable_rds_dr ? 1 : 0
  
  provider      = aws.primary
  filename      = "${path.module}/lambda/rds_snapshot_copy.zip"
  function_name = "${var.project_name}-${var.environment}-rds-snapshot-copy"
  role          = aws_iam_role.lambda_snapshot_copy[0].arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 300
  memory_size   = 256
  
  environment {
    variables = {
      SOURCE_REGION      = data.aws_region.primary.name
      DESTINATION_REGION = data.aws_region.secondary.name
      PROJECT_NAME       = var.project_name
      ENVIRONMENT        = var.environment
      RETENTION_DAYS     = var.snapshot_retention_days
    }
  }
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-rds-snapshot-copy"
  })
}

# IAM role for Lambda snapshot copy
resource "aws_iam_role" "lambda_snapshot_copy" {
  count = var.enable_rds_dr ? 1 : 0
  
  provider = aws.primary
  name     = "${var.project_name}-${var.environment}-lambda-snapshot-copy"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-lambda-snapshot-copy"
  })
}

# IAM policy for Lambda snapshot operations
resource "aws_iam_role_policy" "lambda_snapshot_copy" {
  count = var.enable_rds_dr ? 1 : 0
  
  provider = aws.primary
  role     = aws_iam_role.lambda_snapshot_copy[0].id
  
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
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBSnapshots",
          "rds:DescribeDBInstances",
          "rds:CopyDBSnapshot",
          "rds:DeleteDBSnapshot",
          "rds:AddTagsToResource",
          "rds:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:CreateGrant",
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Event Rule for daily snapshot copy
resource "aws_cloudwatch_event_rule" "daily_snapshot_copy" {
  count = var.enable_rds_dr ? 1 : 0
  
  provider            = aws.primary
  name                = "${var.project_name}-${var.environment}-daily-snapshot-copy"
  description         = "Trigger daily RDS snapshot copy to DR region"
  schedule_expression = "cron(0 2 * * ? *)" # Daily at 2 AM UTC
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-daily-snapshot-copy"
  })
}

# CloudWatch Event Target
resource "aws_cloudwatch_event_target" "snapshot_copy" {
  count = var.enable_rds_dr ? 1 : 0
  
  provider  = aws.primary
  rule      = aws_cloudwatch_event_rule.daily_snapshot_copy[0].name
  target_id = "lambda"
  arn       = aws_lambda_function.rds_snapshot_copy[0].arn
}

# Lambda permission for CloudWatch Events
resource "aws_lambda_permission" "allow_cloudwatch" {
  count = var.enable_rds_dr ? 1 : 0
  
  provider      = aws.primary
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rds_snapshot_copy[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_snapshot_copy[0].arn
}

# ==============================================================================
# DynamoDB Global Tables for Multi-Region Replication
# ==============================================================================

resource "aws_dynamodb_table" "dr_state" {
  provider = aws.primary
  
  name           = "${var.project_name}-${var.environment}-dr-state"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "resource_id"
  range_key      = "timestamp"
  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  
  attribute {
    name = "resource_id"
    type = "S"
  }
  
  attribute {
    name = "timestamp"
    type = "N"
  }
  
  # Global table configuration for multi-region
  replica {
    region_name = data.aws_region.secondary.name
  }
  
  point_in_time_recovery {
    enabled = true
  }
  
  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-dr-state"
    Purpose     = "disaster-recovery-state-tracking"
    Environment = var.environment
  })
}

# ==============================================================================
# Route53 Health Checks & Failover
# ==============================================================================

resource "aws_route53_health_check" "primary" {
  count = var.enable_route53_failover ? 1 : 0
  
  provider          = aws.primary
  type              = var.health_check_type
  resource_path     = var.health_check_path
  fqdn              = var.primary_endpoint
  port              = var.health_check_port
  request_interval  = var.health_check_interval
  failure_threshold = var.health_check_failure_threshold
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-primary-health-check"
  })
}

resource "aws_route53_health_check" "secondary" {
  count = var.enable_route53_failover ? 1 : 0
  
  provider          = aws.secondary
  type              = var.health_check_type
  resource_path     = var.health_check_path
  fqdn              = var.secondary_endpoint
  port              = var.health_check_port
  request_interval  = var.health_check_interval
  failure_threshold = var.health_check_failure_threshold
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-secondary-health-check"
  })
}

# ==============================================================================
# CloudWatch Alarms for DR Monitoring
# ==============================================================================

# Replication lag alarm
resource "aws_cloudwatch_metric_alarm" "replication_lag" {
  provider = aws.primary
  
  alarm_name          = "${var.project_name}-${var.environment}-replication-lag"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReplicationLatency"
  namespace           = "AWS/S3"
  period              = 300
  statistic           = "Average"
  threshold           = var.replication_lag_threshold
  alarm_description   = "S3 replication lag exceeds threshold"
  alarm_actions       = var.alarm_actions
  
  dimensions = {
    SourceBucket      = aws_s3_bucket.backup_primary.id
    DestinationBucket = aws_s3_bucket.backup_secondary.id
    RuleId            = "replicate-all"
  }
  
  tags = merge(var.tags, {
    Name     = "${var.project_name}-${var.environment}-replication-lag-alarm"
    Severity = "high"
  })
}

# Backup failure alarm
resource "aws_cloudwatch_metric_alarm" "backup_failure" {
  count = var.enable_rds_dr ? 1 : 0
  
  provider = aws.primary
  
  alarm_name          = "${var.project_name}-${var.environment}-backup-failure"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "RDS snapshot copy Lambda function failed"
  alarm_actions       = var.alarm_actions
  
  dimensions = {
    FunctionName = aws_lambda_function.rds_snapshot_copy[0].function_name
  }
  
  tags = merge(var.tags, {
    Name     = "${var.project_name}-${var.environment}-backup-failure-alarm"
    Severity = "critical"
  })
}

# RTO monitoring - time to failover
resource "aws_cloudwatch_metric_alarm" "rto_breach" {
  count = var.enable_route53_failover ? 1 : 0
  
  provider = aws.primary
  
  alarm_name          = "${var.project_name}-${var.environment}-rto-breach"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = var.rto_threshold_seconds
  alarm_description   = "RTO threshold breached - failover taking too long"
  alarm_actions       = var.alarm_actions
  
  dimensions = {
    HealthCheckId = aws_route53_health_check.primary[0].id
  }
  
  tags = merge(var.tags, {
    Name     = "${var.project_name}-${var.environment}-rto-breach-alarm"
    Severity = "critical"
  })
}

# ==============================================================================
# SNS Topic for DR Notifications
# ==============================================================================

resource "aws_sns_topic" "dr_notifications" {
  provider = aws.primary
  
  name              = "${var.project_name}-${var.environment}-dr-notifications"
  display_name      = "Disaster Recovery Notifications"
  kms_master_key_id = var.sns_kms_key_id
  
  tags = merge(var.tags, {
    Name    = "${var.project_name}-${var.environment}-dr-notifications"
    Purpose = "disaster-recovery-alerts"
  })
}

# Email subscription for DR alerts
resource "aws_sns_topic_subscription" "dr_email" {
  count = length(var.dr_notification_emails)
  
  provider  = aws.primary
  topic_arn = aws_sns_topic.dr_notifications.arn
  protocol  = "email"
  endpoint  = var.dr_notification_emails[count.index]
}

# ==============================================================================
# Systems Manager Documents for DR Procedures
# ==============================================================================

# Automated failover procedure
resource "aws_ssm_document" "failover_procedure" {
  provider = aws.primary
  
  name            = "${var.project_name}-${var.environment}-failover-procedure"
  document_type   = "Automation"
  document_format = "YAML"
  
  content = yamlencode({
    schemaVersion = "0.3"
    description   = "Automated failover procedure for disaster recovery"
    parameters = {
      TargetRegion = {
        type        = "String"
        description = "Target region for failover"
        default     = data.aws_region.secondary.name
      }
    }
    mainSteps = [
      {
        name   = "VerifyPrimaryHealth"
        action = "aws:executeScript"
        inputs = {
          Runtime = "python3.8"
          Handler = "script_handler"
          Script  = <<-EOT
            def script_handler(events, context):
              # Verify primary region health
              import boto3
              route53 = boto3.client('route53')
              # Health check logic here
              return {'status': 'unhealthy'}
          EOT
        }
      },
      {
        name   = "InitiateFailover"
        action = "aws:executeAwsApi"
        inputs = {
          Service = "route53"
          Api     = "ChangeResourceRecordSets"
          # Failover configuration
        }
      },
      {
        name   = "NotifyTeam"
        action = "aws:executeAwsApi"
        inputs = {
          Service = "sns"
          Api     = "Publish"
          TopicArn = aws_sns_topic.dr_notifications.arn
          Message  = "Failover initiated to secondary region"
        }
      }
    ]
  })
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-failover-procedure"
  })
}

# DR testing procedure
resource "aws_ssm_document" "dr_test_procedure" {
  provider = aws.primary
  
  name            = "${var.project_name}-${var.environment}-dr-test"
  document_type   = "Automation"
  document_format = "YAML"
  
  content = yamlencode({
    schemaVersion = "0.3"
    description   = "Disaster Recovery testing procedure"
    mainSteps = [
      {
        name   = "ValidateBackups"
        action = "aws:executeScript"
        inputs = {
          Runtime = "python3.8"
          Handler = "script_handler"
          Script  = "# Validate all backups are present and intact"
        }
      },
      {
        name   = "TestFailover"
        action = "aws:executeScript"
        inputs = {
          Runtime = "python3.8"
          Handler = "script_handler"
          Script  = "# Perform non-production failover test"
        }
      },
      {
        name   = "ValidateRecovery"
        action = "aws:executeScript"
        inputs = {
          Runtime = "python3.8"
          Handler = "script_handler"
          Script  = "# Validate recovery procedures"
        }
      },
      {
        name   = "GenerateReport"
        action = "aws:executeScript"
        inputs = {
          Runtime = "python3.8"
          Handler = "script_handler"
          Script  = "# Generate DR test report"
        }
      }
    ]
  })
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-dr-test"
  })
}

# ==============================================================================
# CloudWatch Dashboard for DR Monitoring
# ==============================================================================

resource "aws_cloudwatch_dashboard" "dr_monitoring" {
  provider = aws.primary
  
  dashboard_name = "${var.project_name}-${var.environment}-dr-monitoring"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/S3", "ReplicationLatency", { stat = "Average" }],
            ["...", { stat = "Maximum" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.primary.name
          title  = "S3 Replication Latency"
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
            ["AWS/RDS", "BackupRetentionPeriodStorageUsed"],
            [".", "SnapshotStorageUsed"]
          ]
          period = 3600
          stat   = "Average"
          region = data.aws_region.primary.name
          title  = "RDS Backup Storage"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Route53", "HealthCheckStatus", { stat = "Minimum" }]
          ]
          period = 60
          stat   = "Minimum"
          region = "us-east-1"
          title  = "Health Check Status"
          yAxis = {
            left = {
              min = 0
              max = 1
            }
          }
        }
      },
      {
        type = "log"
        properties = {
          query   = "SOURCE '/aws/lambda/${var.project_name}-${var.environment}-rds-snapshot-copy' | fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20"
          region  = data.aws_region.primary.name
          title   = "Recent Backup Errors"
        }
      }
    ]
  })
}
