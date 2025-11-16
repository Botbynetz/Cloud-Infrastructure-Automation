# ==============================================================================
# Advanced Compliance & Audit Module
# Policy-as-Code with OPA, Continuous Compliance, Auto-Remediation
# ==============================================================================

terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

# ------------------------------------------------------------------------------
# S3 Bucket for Compliance Evidence & Audit Logs
# ------------------------------------------------------------------------------

resource "aws_s3_bucket" "compliance_evidence" {
  bucket = "${var.project_name}-compliance-evidence-${var.environment}"
  tags = merge(var.tags, {
    Name = "Compliance Evidence Storage"
    Purpose = "Audit Logs & Policy Evidence"
  })
}

resource "aws_s3_bucket_versioning" "compliance_evidence" {
  bucket = aws_s3_bucket.compliance_evidence.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "compliance_evidence" {
  bucket = aws_s3_bucket.compliance_evidence.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "compliance_evidence" {
  bucket = aws_s3_bucket.compliance_evidence.id
  rule {
    id = "archive-old-logs"
    status = "Enabled"
    transition {
      days = 90
      storage_class = "GLACIER"
    }
    expiration {
      days = 2555  # 7 years retention for compliance
    }
  }
}

# ------------------------------------------------------------------------------
# DynamoDB for Policy Evaluation Results
# ------------------------------------------------------------------------------

resource "aws_dynamodb_table" "policy_evaluations" {
  name = "${var.project_name}-policy-evaluations-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "resource_arn"
  range_key = "timestamp"

  attribute {
    name = "resource_arn"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  attribute {
    name = "policy_id"
    type = "S"
  }

  attribute {
    name = "compliance_status"
    type = "S"
  }

  global_secondary_index {
    name = "PolicyIndex"
    hash_key = "policy_id"
    range_key = "timestamp"
    projection_type = "ALL"
  }

  global_secondary_index {
    name = "StatusIndex"
    hash_key = "compliance_status"
    range_key = "timestamp"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ttl"
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(var.tags, {
    Name = "Policy Evaluation Results"
  })
}

# ------------------------------------------------------------------------------
# Config Rules for Compliance Monitoring
# ------------------------------------------------------------------------------

resource "aws_config_configuration_recorder" "compliance" {
  name = "${var.project_name}-compliance-recorder-${var.environment}"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "compliance" {
  name = "${var.project_name}-compliance-delivery-${var.environment}"
  s3_bucket_name = aws_s3_bucket.compliance_evidence.bucket
  depends_on = [aws_config_configuration_recorder.compliance]
}

resource "aws_config_configuration_recorder_status" "compliance" {
  name = aws_config_configuration_recorder.compliance.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.compliance]
}

# Config Rules
resource "aws_config_config_rule" "encrypted_volumes" {
  name = "encrypted-volumes"
  description = "Ensure all EBS volumes are encrypted"

  source {
    owner = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }

  depends_on = [aws_config_configuration_recorder.compliance]
}

resource "aws_config_config_rule" "rds_encryption" {
  name = "rds-encryption-enabled"
  description = "Ensure RDS instances are encrypted"

  source {
    owner = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }

  depends_on = [aws_config_configuration_recorder.compliance]
}

resource "aws_config_config_rule" "s3_bucket_public_read" {
  name = "s3-bucket-public-read-prohibited"
  description = "Ensure S3 buckets prohibit public read access"

  source {
    owner = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder.compliance]
}

resource "aws_config_config_rule" "s3_bucket_public_write" {
  name = "s3-bucket-public-write-prohibited"
  description = "Ensure S3 buckets prohibit public write access"

  source {
    owner = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder.compliance]
}

resource "aws_config_config_rule" "iam_password_policy" {
  name = "iam-password-policy"
  description = "Ensure IAM password policy meets requirements"

  source {
    owner = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }

  input_parameters = jsonencode({
    RequireUppercaseCharacters = true
    RequireLowercaseCharacters = true
    RequireSymbols = true
    RequireNumbers = true
    MinimumPasswordLength = 14
    PasswordReusePrevention = 24
    MaxPasswordAge = 90
  })

  depends_on = [aws_config_configuration_recorder.compliance]
}

resource "aws_config_config_rule" "cloudtrail_enabled" {
  name = "cloudtrail-enabled"
  description = "Ensure CloudTrail is enabled"

  source {
    owner = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.compliance]
}

# ------------------------------------------------------------------------------
# IAM Role for Config
# ------------------------------------------------------------------------------

resource "aws_iam_role" "config_role" {
  name = "${var.project_name}-config-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "config.amazonaws.com"
      }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "config_policy" {
  role = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/ConfigRole"
}

resource "aws_iam_role_policy" "config_s3_policy" {
  name = "config-s3-policy"
  role = aws_iam_role.config_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:GetBucketVersioning"
      ]
      Resource = [
        aws_s3_bucket.compliance_evidence.arn,
        "${aws_s3_bucket.compliance_evidence.arn}/*"
      ]
    }]
  })
}

# ------------------------------------------------------------------------------
# Lambda Function - Policy Evaluator
# ------------------------------------------------------------------------------

resource "aws_iam_role" "policy_evaluator_role" {
  name = "${var.project_name}-policy-evaluator-${var.environment}"
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

resource "aws_iam_role_policy" "policy_evaluator_policy" {
  name = "policy-evaluator-policy"
  role = aws_iam_role.policy_evaluator_role.id
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
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.policy_evaluations.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.compliance_evidence.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "config:DescribeComplianceByConfigRule",
          "config:DescribeComplianceByResource"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "rds:Describe*",
          "s3:List*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "policy_evaluator" {
  filename = "${path.module}/lambda/policy_evaluator.zip"
  function_name = "${var.project_name}-policy-evaluator-${var.environment}"
  role = aws_iam_role.policy_evaluator_role.arn
  handler = "policy_evaluator.handler"
  runtime = "python3.11"
  timeout = 300
  memory_size = 512

  environment {
    variables = {
      EVALUATIONS_TABLE = aws_dynamodb_table.policy_evaluations.name
      EVIDENCE_BUCKET = aws_s3_bucket.compliance_evidence.bucket
      ENVIRONMENT = var.environment
    }
  }

  tags = merge(var.tags, {
    Name = "Policy Evaluator Lambda"
  })
}

# EventBridge rule - Daily compliance scan
resource "aws_cloudwatch_event_rule" "daily_compliance_scan" {
  name = "${var.project_name}-daily-compliance-${var.environment}"
  description = "Trigger daily compliance policy evaluation"
  schedule_expression = "cron(0 2 * * ? *)"  # 2 AM daily
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "policy_evaluator_target" {
  rule = aws_cloudwatch_event_rule.daily_compliance_scan.name
  arn = aws_lambda_function.policy_evaluator.arn
}

resource "aws_lambda_permission" "allow_eventbridge_policy" {
  statement_id = "AllowExecutionFromEventBridge"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.policy_evaluator.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.daily_compliance_scan.arn
}

# ------------------------------------------------------------------------------
# Lambda Function - Auto-Remediation
# ------------------------------------------------------------------------------

resource "aws_iam_role" "auto_remediation_role" {
  name = "${var.project_name}-auto-remediation-${var.environment}"
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

resource "aws_iam_role_policy" "auto_remediation_policy" {
  name = "auto-remediation-policy"
  role = aws_iam_role.auto_remediation_role.id
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
          "dynamodb:Query",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.policy_evaluations.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutBucketPublicAccessBlock",
          "s3:PutBucketVersioning",
          "s3:PutEncryptionConfiguration"
        ]
        Resource = "arn:aws:s3:::*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:ModifyInstanceAttribute",
          "ec2:CreateTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = var.sns_topic_arn
      }
    ]
  })
}

resource "aws_lambda_function" "auto_remediation" {
  filename = "${path.module}/lambda/auto_remediation.zip"
  function_name = "${var.project_name}-auto-remediation-${var.environment}"
  role = aws_iam_role.auto_remediation_role.arn
  handler = "auto_remediation.handler"
  runtime = "python3.11"
  timeout = 300
  memory_size = 512

  environment {
    variables = {
      EVALUATIONS_TABLE = aws_dynamodb_table.policy_evaluations.name
      SNS_TOPIC_ARN = var.sns_topic_arn
      ENVIRONMENT = var.environment
      AUTO_REMEDIATE = var.enable_auto_remediation ? "true" : "false"
    }
  }

  tags = merge(var.tags, {
    Name = "Auto-Remediation Lambda"
  })
}

# EventBridge rule - On Config non-compliance
resource "aws_cloudwatch_event_rule" "config_compliance_change" {
  name = "${var.project_name}-config-compliance-change-${var.environment}"
  description = "Trigger on Config compliance status change"
  event_pattern = jsonencode({
    source = ["aws.config"]
    detail-type = ["Config Rules Compliance Change"]
    detail = {
      newEvaluationResult = {
        complianceType = ["NON_COMPLIANT"]
      }
    }
  })
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "auto_remediation_target" {
  rule = aws_cloudwatch_event_rule.config_compliance_change.name
  arn = aws_lambda_function.auto_remediation.arn
}

resource "aws_lambda_permission" "allow_eventbridge_remediation" {
  statement_id = "AllowExecutionFromEventBridge"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_remediation.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.config_compliance_change.arn
}

# ------------------------------------------------------------------------------
# CloudWatch Dashboard for Compliance Metrics
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "compliance_dashboard" {
  dashboard_name = "${var.project_name}-compliance-${var.environment}"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title = "Config Rule Compliance"
          metrics = [
            ["AWS/Config", "ComplianceScore"]
          ]
          period = 300
          stat = "Average"
          region = var.aws_region
        }
      },
      {
        type = "metric"
        properties = {
          title = "Policy Evaluator Invocations"
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum", label = "Policy Evaluator" }]
          ]
          period = 3600
          stat = "Sum"
          region = var.aws_region
        }
      },
      {
        type = "metric"
        properties = {
          title = "Auto-Remediation Actions"
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum", label = "Auto-Remediation" }]
          ]
          period = 3600
          stat = "Sum"
          region = var.aws_region
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------

output "compliance_evidence_bucket" {
  description = "S3 bucket for compliance evidence storage"
  value = aws_s3_bucket.compliance_evidence.bucket
}

output "policy_evaluations_table" {
  description = "DynamoDB table for policy evaluation results"
  value = aws_dynamodb_table.policy_evaluations.name
}

output "policy_evaluator_function" {
  description = "Policy evaluator Lambda function ARN"
  value = aws_lambda_function.policy_evaluator.arn
}

output "auto_remediation_function" {
  description = "Auto-remediation Lambda function ARN"
  value = aws_lambda_function.auto_remediation.arn
}

output "config_rules" {
  description = "Active AWS Config rules"
  value = [
    aws_config_config_rule.encrypted_volumes.name,
    aws_config_config_rule.rds_encryption.name,
    aws_config_config_rule.s3_bucket_public_read.name,
    aws_config_config_rule.s3_bucket_public_write.name,
    aws_config_config_rule.iam_password_policy.name,
    aws_config_config_rule.cloudtrail_enabled.name
  ]
}
