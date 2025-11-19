# Secrets Rotation Automation
# Automatic rotation for RDS credentials, API keys, and service accounts

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ============================================
# Lambda Execution Role for Secrets Rotation
# ============================================

resource "aws_iam_role" "secrets_rotation" {
  name = "${var.project_name}-${var.environment}-secrets-rotation"
  
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
  
  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-secrets-rotation"
      Purpose = "Secrets Rotation Lambda"
    }
  )
}

resource "aws_iam_role_policy_attachment" "secrets_rotation_basic" {
  role       = aws_iam_role.secrets_rotation.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda policy for secrets operations
resource "aws_iam_role_policy" "secrets_rotation" {
  name = "${var.project_name}-secrets-rotation-policy"
  role = aws_iam_role.secrets_rotation.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSecretsManagerOperations"
        Effect = "Allow"
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:${var.project_name}/${var.environment}/*"
      },
      {
        Sid    = "AllowKMSDecryptEncrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.kms_key_arn
      },
      {
        Sid    = "AllowRDSPasswordUpdate"
        Effect = "Allow"
        Action = [
          "rds:ModifyDBInstance",
          "rds:ModifyDBCluster",
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters"
        ]
        Resource = [
          "arn:aws:rds:*:*:db:${var.project_name}-${var.environment}-*",
          "arn:aws:rds:*:*:cluster:${var.project_name}-${var.environment}-*"
        ]
      },
      {
        Sid    = "AllowVPCLambdaExecution"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================
# Lambda Function - RDS Password Rotation
# ============================================

resource "aws_lambda_function" "rotate_rds_password" {
  count = var.enable_rds_rotation ? 1 : 0
  
  filename         = "${path.module}/lambda/rotate_rds.zip"
  function_name    = "${var.project_name}-${var.environment}-rotate-rds"
  role            = aws_iam_role.secrets_rotation.arn
  handler         = "rotate_rds.lambda_handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/rotate_rds.zip")
  runtime         = "python3.11"
  timeout         = 300  # 5 minutes
  memory_size     = 256
  
  environment {
    variables = {
      PROJECT_NAME = var.project_name
      ENVIRONMENT  = var.environment
      KMS_KEY_ARN  = var.kms_key_arn
    }
  }
  
  vpc_config {
    subnet_ids         = var.lambda_subnet_ids
    security_group_ids = var.lambda_security_group_ids
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-rotate-rds"
    }
  )
}

resource "aws_lambda_permission" "rotate_rds_secrets_manager" {
  count = var.enable_rds_rotation ? 1 : 0
  
  statement_id  = "AllowExecutionFromSecretsManager"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotate_rds_password[0].function_name
  principal     = "secretsmanager.amazonaws.com"
}

# ============================================
# Lambda Function - API Key Rotation
# ============================================

resource "aws_lambda_function" "rotate_api_keys" {
  count = var.enable_api_key_rotation ? 1 : 0
  
  filename         = "${path.module}/lambda/rotate_api_keys.zip"
  function_name    = "${var.project_name}-${var.environment}-rotate-api-keys"
  role            = aws_iam_role.secrets_rotation.arn
  handler         = "rotate_api_keys.lambda_handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/rotate_api_keys.zip")
  runtime         = "python3.11"
  timeout         = 180
  memory_size     = 256
  
  environment {
    variables = {
      PROJECT_NAME     = var.project_name
      ENVIRONMENT      = var.environment
      KMS_KEY_ARN      = var.kms_key_arn
      API_ENDPOINT     = var.api_endpoint
    }
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-rotate-api-keys"
    }
  )
}

# ============================================
# EventBridge Rules for Automatic Rotation
# ============================================

# RDS password rotation - every 30 days
resource "aws_cloudwatch_event_rule" "rotate_rds_schedule" {
  count = var.enable_rds_rotation ? 1 : 0
  
  name                = "${var.project_name}-${var.environment}-rotate-rds-schedule"
  description         = "Trigger RDS password rotation every 30 days"
  schedule_expression = "rate(30 days)"
  
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "rotate_rds_lambda" {
  count = var.enable_rds_rotation ? 1 : 0
  
  rule      = aws_cloudwatch_event_rule.rotate_rds_schedule[0].name
  target_id = "RotateRDSPasswordLambda"
  arn       = aws_lambda_function.rotate_rds_password[0].arn
}

resource "aws_lambda_permission" "rotate_rds_eventbridge" {
  count = var.enable_rds_rotation ? 1 : 0
  
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotate_rds_password[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rotate_rds_schedule[0].arn
}

# API key rotation - every 90 days
resource "aws_cloudwatch_event_rule" "rotate_api_keys_schedule" {
  count = var.enable_api_key_rotation ? 1 : 0
  
  name                = "${var.project_name}-${var.environment}-rotate-api-keys-schedule"
  description         = "Trigger API key rotation every 90 days"
  schedule_expression = "rate(90 days)"
  
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "rotate_api_keys_lambda" {
  count = var.enable_api_key_rotation ? 1 : 0
  
  rule      = aws_cloudwatch_event_rule.rotate_api_keys_schedule[0].name
  target_id = "RotateAPIKeysLambda"
  arn       = aws_lambda_function.rotate_api_keys[0].arn
}

resource "aws_lambda_permission" "rotate_api_keys_eventbridge" {
  count = var.enable_api_key_rotation ? 1 : 0
  
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotate_api_keys[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rotate_api_keys_schedule[0].arn
}

# ============================================
# SNS Topic for Rotation Failure Alerts
# ============================================

resource "aws_sns_topic" "rotation_alerts" {
  count = var.enable_rotation_alerts ? 1 : 0
  
  name = "${var.project_name}-${var.environment}-secrets-rotation-alerts"
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-rotation-alerts"
    }
  )
}

resource "aws_sns_topic_subscription" "rotation_alerts_email" {
  count = var.enable_rotation_alerts && length(var.alert_email_addresses) > 0 ? length(var.alert_email_addresses) : 0
  
  topic_arn = aws_sns_topic.rotation_alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email_addresses[count.index]
}

# CloudWatch Log Metric Filter for rotation failures
resource "aws_cloudwatch_log_metric_filter" "rotation_failure" {
  count = var.enable_rotation_alerts ? 1 : 0
  
  name           = "${var.project_name}-${var.environment}-rotation-failure"
  log_group_name = "/aws/lambda/${var.project_name}-${var.environment}-rotate-*"
  pattern        = "[ERROR] Rotation failed"
  
  metric_transformation {
    name      = "SecretsRotationFailure"
    namespace = "${var.project_name}/${var.environment}/Secrets"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "rotation_failure" {
  count = var.enable_rotation_alerts ? 1 : 0
  
  alarm_name          = "${var.project_name}-${var.environment}-secrets-rotation-failure"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "SecretsRotationFailure"
  namespace           = "${var.project_name}/${var.environment}/Secrets"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Alerts when secrets rotation fails"
  alarm_actions       = [aws_sns_topic.rotation_alerts[0].arn]
  
  tags = var.tags
}

# ============================================
# CloudWatch Log Groups
# ============================================

resource "aws_cloudwatch_log_group" "rotate_rds" {
  count = var.enable_rds_rotation ? 1 : 0
  
  name              = "/aws/lambda/${aws_lambda_function.rotate_rds_password[0].function_name}"
  retention_in_days = 30
  kms_key_id        = var.kms_key_arn
  
  tags = var.tags
}

resource "aws_cloudwatch_log_group" "rotate_api_keys" {
  count = var.enable_api_key_rotation ? 1 : 0
  
  name              = "/aws/lambda/${aws_lambda_function.rotate_api_keys[0].function_name}"
  retention_in_days = 30
  kms_key_id        = var.kms_key_arn
  
  tags = var.tags
}
