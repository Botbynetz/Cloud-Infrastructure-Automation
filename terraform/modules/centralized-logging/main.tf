# ==============================================================================
# Centralized Logging Module
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
# S3 Bucket for Log Export
# ==============================================================================

resource "aws_s3_bucket" "logs" {
  count = var.enable_log_export ? 1 : 0

  bucket = "${var.project_name}-${var.environment}-cloudwatch-logs-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-cloudwatch-logs"
      Purpose     = "CloudWatch Logs Export"
      Environment = var.environment
    }
  )
}

resource "aws_s3_bucket_versioning" "logs" {
  count = var.enable_log_export ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count = var.enable_log_export ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"

    transition {
      days          = var.s3_transition_days
      storage_class = "GLACIER"
    }

    transition {
      days          = var.s3_deep_archive_days
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = var.s3_expiration_days
    }
  }

  rule {
    id     = "delete-old-versions"
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

resource "aws_s3_bucket_public_access_block" "logs" {
  count = var.enable_log_export ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count = var.enable_log_export ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.enable_log_encryption ? "aws:kms" : "AES256"
      kms_master_key_id = var.enable_log_encryption ? var.kms_key_id : null
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  count = var.enable_log_export ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudWatchLogsAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.logs[0].arn
      },
      {
        Sid    = "AWSCloudWatchLogsPutObject"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# ==============================================================================
# Kinesis Data Stream for Real-Time Processing
# ==============================================================================

resource "aws_kinesis_stream" "logs" {
  count = var.enable_kinesis_streaming ? 1 : 0

  name             = "${var.project_name}-${var.environment}-logs"
  shard_count      = var.kinesis_shard_count
  retention_period = var.kinesis_retention_hours

  shard_level_metrics = [
    "IncomingBytes",
    "IncomingRecords",
    "OutgoingBytes",
    "OutgoingRecords",
  ]

  stream_mode_details {
    stream_mode = var.kinesis_stream_mode
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-logs"
      Purpose     = "CloudWatch Logs Streaming"
      Environment = var.environment
    }
  )
}

resource "aws_kinesis_stream" "logs_encrypted" {
  count = var.enable_kinesis_streaming && var.enable_log_encryption ? 1 : 0

  name             = "${var.project_name}-${var.environment}-logs-encrypted"
  shard_count      = var.kinesis_shard_count
  retention_period = var.kinesis_retention_hours

  encryption_type = "KMS"
  kms_key_id      = var.kms_key_id

  shard_level_metrics = [
    "IncomingBytes",
    "IncomingRecords",
    "OutgoingBytes",
    "OutgoingRecords",
  ]

  stream_mode_details {
    stream_mode = var.kinesis_stream_mode
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-logs-encrypted"
      Purpose     = "CloudWatch Logs Streaming (Encrypted)"
      Environment = var.environment
    }
  )
}

# ==============================================================================
# IAM Role for CloudWatch Logs to Kinesis
# ==============================================================================

resource "aws_iam_role" "cloudwatch_logs_kinesis" {
  count = var.enable_kinesis_streaming ? 1 : 0

  name = "${var.project_name}-${var.environment}-cloudwatch-kinesis"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-cloudwatch-kinesis"
      Environment = var.environment
    }
  )
}

resource "aws_iam_role_policy" "cloudwatch_logs_kinesis" {
  count = var.enable_kinesis_streaming ? 1 : 0

  name = "${var.project_name}-${var.environment}-cloudwatch-kinesis-policy"
  role = aws_iam_role.cloudwatch_logs_kinesis[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:PutRecord",
          "kinesis:PutRecords"
        ]
        Resource = var.enable_log_encryption ? aws_kinesis_stream.logs_encrypted[0].arn : aws_kinesis_stream.logs[0].arn
      }
    ]
  })
}

# ==============================================================================
# CloudWatch Logs Subscription Filters
# ==============================================================================

resource "aws_cloudwatch_log_subscription_filter" "application_to_kinesis" {
  count = var.enable_kinesis_streaming ? 1 : 0

  name            = "${var.project_name}-${var.environment}-application-kinesis"
  log_group_name  = var.application_log_group_name
  filter_pattern  = var.kinesis_filter_pattern
  destination_arn = var.enable_log_encryption ? aws_kinesis_stream.logs_encrypted[0].arn : aws_kinesis_stream.logs[0].arn
  role_arn        = aws_iam_role.cloudwatch_logs_kinesis[0].arn
}

resource "aws_cloudwatch_log_subscription_filter" "infrastructure_to_kinesis" {
  count = var.enable_kinesis_streaming && var.stream_infrastructure_logs ? 1 : 0

  name            = "${var.project_name}-${var.environment}-infrastructure-kinesis"
  log_group_name  = var.infrastructure_log_group_name
  filter_pattern  = var.kinesis_filter_pattern
  destination_arn = var.enable_log_encryption ? aws_kinesis_stream.logs_encrypted[0].arn : aws_kinesis_stream.logs[0].arn
  role_arn        = aws_iam_role.cloudwatch_logs_kinesis[0].arn
}

resource "aws_cloudwatch_log_subscription_filter" "security_to_kinesis" {
  count = var.enable_kinesis_streaming && var.stream_security_logs ? 1 : 0

  name            = "${var.project_name}-${var.environment}-security-kinesis"
  log_group_name  = var.security_log_group_name
  filter_pattern  = var.kinesis_filter_pattern
  destination_arn = var.enable_log_encryption ? aws_kinesis_stream.logs_encrypted[0].arn : aws_kinesis_stream.logs[0].arn
  role_arn        = aws_iam_role.cloudwatch_logs_kinesis[0].arn
}

# ==============================================================================
# CloudWatch Logs Export Tasks (Manual trigger via Lambda)
# ==============================================================================

resource "aws_iam_role" "log_export_lambda" {
  count = var.enable_log_export ? 1 : 0

  name = "${var.project_name}-${var.environment}-log-export-lambda"

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
      Name        = "${var.project_name}-${var.environment}-log-export-lambda"
      Environment = var.environment
    }
  )
}

resource "aws_iam_role_policy" "log_export_lambda" {
  count = var.enable_log_export ? 1 : 0

  name = "${var.project_name}-${var.environment}-log-export-policy"
  role = aws_iam_role.log_export_lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateExportTask",
          "logs:DescribeExportTasks",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.logs[0].arn,
          "${aws_s3_bucket.logs[0].arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "log_export_lambda_basic" {
  count = var.enable_log_export ? 1 : 0

  role       = aws_iam_role.log_export_lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "log_export" {
  count = var.enable_log_export ? 1 : 0

  filename         = "${path.module}/lambda/log-export.zip"
  function_name    = "${var.project_name}-${var.environment}-log-export"
  role             = aws_iam_role.log_export_lambda[0].arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/log-export.zip")
  runtime          = "python3.11"
  timeout          = 60

  environment {
    variables = {
      S3_BUCKET              = aws_s3_bucket.logs[0].id
      APPLICATION_LOG_GROUP  = var.application_log_group_name
      INFRASTRUCTURE_LOG_GROUP = var.infrastructure_log_group_name
      SECURITY_LOG_GROUP     = var.security_log_group_name
      AUDIT_LOG_GROUP        = var.audit_log_group_name
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-log-export"
      Environment = var.environment
    }
  )
}

resource "aws_cloudwatch_event_rule" "daily_log_export" {
  count = var.enable_log_export && var.enable_scheduled_export ? 1 : 0

  name                = "${var.project_name}-${var.environment}-daily-log-export"
  description         = "Trigger daily CloudWatch Logs export to S3"
  schedule_expression = var.export_schedule_expression

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-daily-log-export"
      Environment = var.environment
    }
  )
}

resource "aws_cloudwatch_event_target" "log_export" {
  count = var.enable_log_export && var.enable_scheduled_export ? 1 : 0

  rule      = aws_cloudwatch_event_rule.daily_log_export[0].name
  target_id = "LogExportLambda"
  arn       = aws_lambda_function.log_export[0].arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  count = var.enable_log_export && var.enable_scheduled_export ? 1 : 0

  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log_export[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_log_export[0].arn
}

# ==============================================================================
# Cross-Account Log Aggregation (Optional)
# ==============================================================================

resource "aws_cloudwatch_log_destination" "cross_account" {
  count = var.enable_cross_account_logging ? 1 : 0

  name       = "${var.project_name}-${var.environment}-cross-account-logs"
  role_arn   = aws_iam_role.cloudwatch_logs_kinesis[0].arn
  target_arn = var.enable_log_encryption ? aws_kinesis_stream.logs_encrypted[0].arn : aws_kinesis_stream.logs[0].arn

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-cross-account-logs"
      Environment = var.environment
    }
  )
}

resource "aws_cloudwatch_log_destination_policy" "cross_account" {
  count = var.enable_cross_account_logging ? 1 : 0

  destination_name = aws_cloudwatch_log_destination.cross_account[0].name

  access_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.cross_account_ids
        }
        Action = [
          "logs:PutSubscriptionFilter"
        ]
        Resource = aws_cloudwatch_log_destination.cross_account[0].arn
      }
    ]
  })
}

# ==============================================================================
# CloudWatch Logs Insights Saved Queries for Centralized Logging
# ==============================================================================

resource "aws_cloudwatch_query_definition" "log_aggregation_stats" {
  name = "${var.project_name}-${var.environment}-log-aggregation-stats"

  log_group_names = [
    var.application_log_group_name,
    var.infrastructure_log_group_name,
    var.security_log_group_name,
    var.audit_log_group_name
  ]

  query_string = <<-QUERY
    fields @timestamp, @logStream, @message
    | stats count() by @logStream
    | sort count desc
  QUERY
}

resource "aws_cloudwatch_query_definition" "cross_log_group_errors" {
  name = "${var.project_name}-${var.environment}-cross-log-group-errors"

  log_group_names = [
    var.application_log_group_name,
    var.infrastructure_log_group_name,
    var.security_log_group_name
  ]

  query_string = <<-QUERY
    fields @timestamp, @logStream, @message
    | filter @message like /ERROR/ or @message like /FATAL/
    | sort @timestamp desc
    | limit 100
  QUERY
}

# ==============================================================================
# Log Analytics Workspace (Optional - for advanced analytics)
# ==============================================================================

resource "aws_cloudwatch_log_resource_policy" "elasticsearch" {
  count = var.enable_elasticsearch_integration ? 1 : 0

  policy_name = "${var.project_name}-${var.environment}-elasticsearch-logs"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "es.amazonaws.com"
        }
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream"
        ]
        Resource = "*"
      }
    ]
  })
}
