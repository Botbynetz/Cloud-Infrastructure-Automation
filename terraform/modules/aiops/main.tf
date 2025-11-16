# AIOps Module - AI/ML-Powered Operations
# Predictive auto-scaling, anomaly detection, intelligent alerting

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
# S3 Bucket for ML Training Data
# ============================================================

resource "aws_s3_bucket" "ml_data" {
  bucket = "${var.project_name}-${var.environment}-ml-data-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.tags, {
    Name    = "${var.project_name}-${var.environment}-ml-data"
    Purpose = "AIOps ML training and inference data"
  })
}

resource "aws_s3_bucket_versioning" "ml_data" {
  bucket = aws_s3_bucket.ml_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "ml_data" {
  bucket = aws_s3_bucket.ml_data.id

  rule {
    id     = "ml-data-lifecycle"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = var.ml_data_retention_days
    }
  }
}

# ============================================================
# Kinesis Data Stream for Real-Time Metrics
# ============================================================

resource "aws_kinesis_stream" "metrics_stream" {
  name             = "${var.project_name}-${var.environment}-metrics-stream"
  shard_count      = var.kinesis_shard_count
  retention_period = 168  # 7 days

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-metrics-stream"
  })
}

# ============================================================
# Glue Database for ML Data Catalog
# ============================================================

resource "aws_glue_catalog_database" "aiops" {
  name        = "${var.project_name}_${var.environment}_aiops"
  description = "AIOps ML data catalog"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-aiops-catalog"
  })
}

# ============================================================
# SageMaker IAM Role
# ============================================================

resource "aws_iam_role" "sagemaker" {
  name = "${var.project_name}-${var.environment}-sagemaker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "sagemaker.amazonaws.com"
      }
    }]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-sagemaker-role"
  })
}

resource "aws_iam_role_policy_attachment" "sagemaker_full_access" {
  role       = aws_iam_role.sagemaker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_role_policy" "sagemaker_custom" {
  name = "sagemaker-aiops-policy"
  role = aws_iam_role.sagemaker.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.ml_data.arn,
          "${aws_s3_bucket.ml_data.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================
# Lambda: Metrics Collector
# ============================================================

resource "aws_lambda_function" "metrics_collector" {
  filename         = "${path.module}/lambda/metrics_collector.zip"
  function_name    = "${var.project_name}-${var.environment}-metrics-collector"
  role             = aws_iam_role.metrics_collector_lambda.arn
  handler          = "metrics_collector.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/metrics_collector.zip")
  runtime          = "python3.11"
  timeout          = 300
  memory_size      = 512

  environment {
    variables = {
      PROJECT_NAME    = var.project_name
      ENVIRONMENT     = var.environment
      KINESIS_STREAM  = aws_kinesis_stream.metrics_stream.name
      S3_BUCKET       = aws_s3_bucket.ml_data.id
      ML_ENABLED      = var.enable_ml_predictions
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-metrics-collector"
  })
}

# EventBridge rule for metrics collection (every 5 minutes)
resource "aws_cloudwatch_event_rule" "metrics_collection" {
  name                = "${var.project_name}-${var.environment}-metrics-collection"
  description         = "Collect metrics every 5 minutes for ML training"
  schedule_expression = "rate(5 minutes)"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-metrics-collection"
  })
}

resource "aws_cloudwatch_event_target" "metrics_collection" {
  rule      = aws_cloudwatch_event_rule.metrics_collection.name
  target_id = "MetricsCollectorLambda"
  arn       = aws_lambda_function.metrics_collector.arn
}

resource "aws_lambda_permission" "metrics_collection" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.metrics_collector.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.metrics_collection.arn
}

# IAM role for metrics collector
resource "aws_iam_role" "metrics_collector_lambda" {
  name = "${var.project_name}-${var.environment}-metrics-collector-lambda"

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
    Name = "${var.project_name}-${var.environment}-metrics-collector-lambda-role"
  })
}

resource "aws_iam_role_policy" "metrics_collector_lambda" {
  name = "metrics-collector-policy"
  role = aws_iam_role.metrics_collector_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kinesis:PutRecord",
          "kinesis:PutRecords"
        ]
        Resource = aws_kinesis_stream.metrics_stream.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.ml_data.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "rds:DescribeDBInstances",
          "elasticloadbalancing:DescribeLoadBalancers"
        ]
        Resource = "*"
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
# Lambda: Anomaly Detector
# ============================================================

resource "aws_lambda_function" "anomaly_detector" {
  filename         = "${path.module}/lambda/anomaly_detector.zip"
  function_name    = "${var.project_name}-${var.environment}-anomaly-detector"
  role             = aws_iam_role.anomaly_detector_lambda.arn
  handler          = "anomaly_detector.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/anomaly_detector.zip")
  runtime          = "python3.11"
  timeout          = 600
  memory_size      = 1024

  environment {
    variables = {
      PROJECT_NAME           = var.project_name
      ENVIRONMENT            = var.environment
      KINESIS_STREAM         = aws_kinesis_stream.metrics_stream.name
      SNS_TOPIC_ARN          = aws_sns_topic.aiops_alerts.arn
      ANOMALY_THRESHOLD      = var.anomaly_detection_threshold
      ENABLE_AUTO_REMEDIATION = var.enable_auto_remediation
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-anomaly-detector"
  })
}

# Kinesis trigger for anomaly detection
resource "aws_lambda_event_source_mapping" "kinesis_anomaly" {
  event_source_arn  = aws_kinesis_stream.metrics_stream.arn
  function_name     = aws_lambda_function.anomaly_detector.arn
  starting_position = "LATEST"
  batch_size        = 100
}

# IAM role for anomaly detector
resource "aws_iam_role" "anomaly_detector_lambda" {
  name = "${var.project_name}-${var.environment}-anomaly-detector-lambda"

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
    Name = "${var.project_name}-${var.environment}-anomaly-detector-lambda-role"
  })
}

resource "aws_iam_role_policy" "anomaly_detector_lambda" {
  name = "anomaly-detector-policy"
  role = aws_iam_role.anomaly_detector_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:ListStreams"
        ]
        Resource = aws_kinesis_stream.metrics_stream.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.aiops_alerts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
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
# Lambda: Predictive Scaler
# ============================================================

resource "aws_lambda_function" "predictive_scaler" {
  filename         = "${path.module}/lambda/predictive_scaler.zip"
  function_name    = "${var.project_name}-${var.environment}-predictive-scaler"
  role             = aws_iam_role.predictive_scaler_lambda.arn
  handler          = "predictive_scaler.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/predictive_scaler.zip")
  runtime          = "python3.11"
  timeout          = 600
  memory_size      = 1024

  environment {
    variables = {
      PROJECT_NAME       = var.project_name
      ENVIRONMENT        = var.environment
      S3_BUCKET          = aws_s3_bucket.ml_data.id
      SNS_TOPIC_ARN      = aws_sns_topic.aiops_alerts.arn
      PREDICTION_WINDOW  = var.prediction_window_hours
      ENABLE_AUTO_SCALING = var.enable_predictive_scaling
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-predictive-scaler"
  })
}

# EventBridge rule for predictive scaling (every 15 minutes)
resource "aws_cloudwatch_event_rule" "predictive_scaling" {
  name                = "${var.project_name}-${var.environment}-predictive-scaling"
  description         = "Run predictive scaling every 15 minutes"
  schedule_expression = "rate(15 minutes)"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-predictive-scaling"
  })
}

resource "aws_cloudwatch_event_target" "predictive_scaling" {
  rule      = aws_cloudwatch_event_rule.predictive_scaling.name
  target_id = "PredictiveScalerLambda"
  arn       = aws_lambda_function.predictive_scaler.arn
}

resource "aws_lambda_permission" "predictive_scaling" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.predictive_scaler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.predictive_scaling.arn
}

# IAM role for predictive scaler
resource "aws_iam_role" "predictive_scaler_lambda" {
  name = "${var.project_name}-${var.environment}-predictive-scaler-lambda"

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
    Name = "${var.project_name}-${var.environment}-predictive-scaler-lambda-role"
  })
}

resource "aws_iam_role_policy" "predictive_scaler_lambda" {
  name = "predictive-scaler-policy"
  role = aws_iam_role.predictive_scaler_lambda.id

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
          aws_s3_bucket.ml_data.arn,
          "${aws_s3_bucket.ml_data.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:DescribeAutoScalingGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.aiops_alerts.arn
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
# SNS Topic for AIOps Alerts
# ============================================================

resource "aws_sns_topic" "aiops_alerts" {
  name = "${var.project_name}-${var.environment}-aiops-alerts"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-aiops-alerts"
  })
}

resource "aws_sns_topic_subscription" "aiops_email" {
  for_each = toset(var.aiops_notification_emails)

  topic_arn = aws_sns_topic.aiops_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

# ============================================================
# CloudWatch Dashboard
# ============================================================

resource "aws_cloudwatch_dashboard" "aiops" {
  dashboard_name = "${var.project_name}-${var.environment}-aiops-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["${var.project_name}/${var.environment}/AIOps", "AnomaliesDetected", { stat = "Sum" }],
            [".", "PredictiveScalingActions", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "AIOps Activity"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Kinesis", "IncomingRecords", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Metrics Stream Activity"
        }
      }
    ]
  })
}

# ============================================================
# CloudWatch Log Groups
# ============================================================

resource "aws_cloudwatch_log_group" "metrics_collector" {
  name              = "/aws/lambda/${aws_lambda_function.metrics_collector.function_name}"
  retention_in_days = 30

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-metrics-collector-logs"
  })
}

resource "aws_cloudwatch_log_group" "anomaly_detector" {
  name              = "/aws/lambda/${aws_lambda_function.anomaly_detector.function_name}"
  retention_in_days = 30

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-anomaly-detector-logs"
  })
}

resource "aws_cloudwatch_log_group" "predictive_scaler" {
  name              = "/aws/lambda/${aws_lambda_function.predictive_scaler.function_name}"
  retention_in_days = 30

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-predictive-scaler-logs"
  })
}

# ============================================================
# Data Sources
# ============================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
