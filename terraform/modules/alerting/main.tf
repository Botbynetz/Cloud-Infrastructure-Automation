# ==============================================================================
# Advanced Alerting Module
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
# SNS Topics for Different Severity Levels
# ==============================================================================

resource "aws_sns_topic" "critical" {
  count = var.enable_sns_notifications ? 1 : 0

  name              = "${var.project_name}-${var.environment}-alerts-critical"
  display_name      = "Critical Alerts - ${var.project_name} ${var.environment}"
  kms_master_key_id = var.enable_encryption ? var.kms_key_id : null

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-alerts-critical"
      Severity    = "critical"
      Environment = var.environment
    }
  )
}

resource "aws_sns_topic" "warning" {
  count = var.enable_sns_notifications ? 1 : 0

  name              = "${var.project_name}-${var.environment}-alerts-warning"
  display_name      = "Warning Alerts - ${var.project_name} ${var.environment}"
  kms_master_key_id = var.enable_encryption ? var.kms_key_id : null

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-alerts-warning"
      Severity    = "warning"
      Environment = var.environment
    }
  )
}

resource "aws_sns_topic" "info" {
  count = var.enable_sns_notifications ? 1 : 0

  name              = "${var.project_name}-${var.environment}-alerts-info"
  display_name      = "Info Alerts - ${var.project_name} ${var.environment}"
  kms_master_key_id = var.enable_encryption ? var.kms_key_id : null

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-alerts-info"
      Severity    = "info"
      Environment = var.environment
    }
  )
}

# ==============================================================================
# SNS Topic Policies
# ==============================================================================

resource "aws_sns_topic_policy" "critical" {
  count = var.enable_sns_notifications ? 1 : 0

  arn = aws_sns_topic.critical[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchToPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.critical[0].arn
      },
      {
        Sid    = "AllowLambdaToPublish"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.critical[0].arn
      }
    ]
  })
}

resource "aws_sns_topic_policy" "warning" {
  count = var.enable_sns_notifications ? 1 : 0

  arn = aws_sns_topic.warning[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchToPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.warning[0].arn
      }
    ]
  })
}

resource "aws_sns_topic_policy" "info" {
  count = var.enable_sns_notifications ? 1 : 0

  arn = aws_sns_topic.info[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchToPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.info[0].arn
      }
    ]
  })
}

# ==============================================================================
# Email Subscriptions
# ==============================================================================

resource "aws_sns_topic_subscription" "critical_email" {
  for_each = var.enable_sns_notifications ? toset(var.critical_email_endpoints) : []

  topic_arn = aws_sns_topic.critical[0].arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_sns_topic_subscription" "warning_email" {
  for_each = var.enable_sns_notifications ? toset(var.warning_email_endpoints) : []

  topic_arn = aws_sns_topic.warning[0].arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_sns_topic_subscription" "info_email" {
  for_each = var.enable_sns_notifications ? toset(var.info_email_endpoints) : []

  topic_arn = aws_sns_topic.info[0].arn
  protocol  = "email"
  endpoint  = each.value
}

# ==============================================================================
# SMS Subscriptions
# ==============================================================================

resource "aws_sns_topic_subscription" "critical_sms" {
  for_each = var.enable_sms_notifications ? toset(var.critical_sms_endpoints) : []

  topic_arn = aws_sns_topic.critical[0].arn
  protocol  = "sms"
  endpoint  = each.value
}

# ==============================================================================
# Slack Integration Lambda
# ==============================================================================

resource "aws_iam_role" "slack_lambda" {
  count = var.enable_slack_notifications ? 1 : 0

  name = "${var.project_name}-${var.environment}-slack-alerts"

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
      Name        = "${var.project_name}-${var.environment}-slack-alerts"
      Environment = var.environment
    }
  )
}

resource "aws_iam_role_policy_attachment" "slack_lambda_basic" {
  count = var.enable_slack_notifications ? 1 : 0

  role       = aws_iam_role.slack_lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "slack_notifier" {
  count = var.enable_slack_notifications ? 1 : 0

  filename         = "${path.module}/lambda/slack-notifier.zip"
  function_name    = "${var.project_name}-${var.environment}-slack-notifier"
  role             = aws_iam_role.slack_lambda[0].arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/slack-notifier.zip")
  runtime          = "python3.11"
  timeout          = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
      SLACK_CHANNEL     = var.slack_channel
      PROJECT_NAME      = var.project_name
      ENVIRONMENT       = var.environment
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-slack-notifier"
      Environment = var.environment
    }
  )
}

resource "aws_lambda_permission" "slack_sns_critical" {
  count = var.enable_slack_notifications ? 1 : 0

  statement_id  = "AllowExecutionFromSNSCritical"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_notifier[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.critical[0].arn
}

resource "aws_lambda_permission" "slack_sns_warning" {
  count = var.enable_slack_notifications ? 1 : 0

  statement_id  = "AllowExecutionFromSNSWarning"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_notifier[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.warning[0].arn
}

resource "aws_sns_topic_subscription" "slack_critical" {
  count = var.enable_slack_notifications ? 1 : 0

  topic_arn = aws_sns_topic.critical[0].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notifier[0].arn
}

resource "aws_sns_topic_subscription" "slack_warning" {
  count = var.enable_slack_notifications ? 1 : 0

  topic_arn = aws_sns_topic.warning[0].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notifier[0].arn
}

# ==============================================================================
# PagerDuty Integration Lambda
# ==============================================================================

resource "aws_iam_role" "pagerduty_lambda" {
  count = var.enable_pagerduty_notifications ? 1 : 0

  name = "${var.project_name}-${var.environment}-pagerduty-alerts"

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
      Name        = "${var.project_name}-${var.environment}-pagerduty-alerts"
      Environment = var.environment
    }
  )
}

resource "aws_iam_role_policy_attachment" "pagerduty_lambda_basic" {
  count = var.enable_pagerduty_notifications ? 1 : 0

  role       = aws_iam_role.pagerduty_lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "pagerduty_notifier" {
  count = var.enable_pagerduty_notifications ? 1 : 0

  filename         = "${path.module}/lambda/pagerduty-notifier.zip"
  function_name    = "${var.project_name}-${var.environment}-pagerduty-notifier"
  role             = aws_iam_role.pagerduty_lambda[0].arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/pagerduty-notifier.zip")
  runtime          = "python3.11"
  timeout          = 30

  environment {
    variables = {
      PAGERDUTY_INTEGRATION_KEY = var.pagerduty_integration_key
      PROJECT_NAME              = var.project_name
      ENVIRONMENT               = var.environment
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-pagerduty-notifier"
      Environment = var.environment
    }
  )
}

resource "aws_lambda_permission" "pagerduty_sns" {
  count = var.enable_pagerduty_notifications ? 1 : 0

  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pagerduty_notifier[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.critical[0].arn
}

resource "aws_sns_topic_subscription" "pagerduty" {
  count = var.enable_pagerduty_notifications ? 1 : 0

  topic_arn = aws_sns_topic.critical[0].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.pagerduty_notifier[0].arn
}

# ==============================================================================
# Alert Aggregation Lambda (Prevent Alert Fatigue)
# ==============================================================================

resource "aws_dynamodb_table" "alert_state" {
  count = var.enable_alert_aggregation ? 1 : 0

  name           = "${var.project_name}-${var.environment}-alert-state"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "AlertId"
  range_key      = "Timestamp"

  attribute {
    name = "AlertId"
    type = "S"
  }

  attribute {
    name = "Timestamp"
    type = "N"
  }

  ttl {
    attribute_name = "ExpirationTime"
    enabled        = true
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-alert-state"
      Environment = var.environment
    }
  )
}

resource "aws_iam_role" "alert_aggregator" {
  count = var.enable_alert_aggregation ? 1 : 0

  name = "${var.project_name}-${var.environment}-alert-aggregator"

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
      Name        = "${var.project_name}-${var.environment}-alert-aggregator"
      Environment = var.environment
    }
  )
}

resource "aws_iam_role_policy" "alert_aggregator" {
  count = var.enable_alert_aggregation ? 1 : 0

  name = "${var.project_name}-${var.environment}-alert-aggregator-policy"
  role = aws_iam_role.alert_aggregator[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]
        Resource = aws_dynamodb_table.alert_state[0].arn
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [
          aws_sns_topic.critical[0].arn,
          aws_sns_topic.warning[0].arn,
          aws_sns_topic.info[0].arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "alert_aggregator_basic" {
  count = var.enable_alert_aggregation ? 1 : 0

  role       = aws_iam_role.alert_aggregator[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "alert_aggregator" {
  count = var.enable_alert_aggregation ? 1 : 0

  filename         = "${path.module}/lambda/alert-aggregator.zip"
  function_name    = "${var.project_name}-${var.environment}-alert-aggregator"
  role             = aws_iam_role.alert_aggregator[0].arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/alert-aggregator.zip")
  runtime          = "python3.11"
  timeout          = 60

  environment {
    variables = {
      ALERT_STATE_TABLE        = aws_dynamodb_table.alert_state[0].name
      AGGREGATION_WINDOW       = var.alert_aggregation_window
      CRITICAL_TOPIC_ARN       = aws_sns_topic.critical[0].arn
      WARNING_TOPIC_ARN        = aws_sns_topic.warning[0].arn
      INFO_TOPIC_ARN           = aws_sns_topic.info[0].arn
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-alert-aggregator"
      Environment = var.environment
    }
  )
}

# ==============================================================================
# Escalation Rules (Step Functions)
# ==============================================================================

resource "aws_iam_role" "escalation_step_function" {
  count = var.enable_escalation ? 1 : 0

  name = "${var.project_name}-${var.environment}-escalation-sf"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-escalation-sf"
      Environment = var.environment
    }
  )
}

resource "aws_iam_role_policy" "escalation_step_function" {
  count = var.enable_escalation ? 1 : 0

  name = "${var.project_name}-${var.environment}-escalation-policy"
  role = aws_iam_role.escalation_step_function[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [
          aws_sns_topic.critical[0].arn,
          aws_sns_topic.warning[0].arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = var.enable_pagerduty_notifications ? [
          aws_lambda_function.pagerduty_notifier[0].arn
        ] : []
      }
    ]
  })
}

resource "aws_sfn_state_machine" "alert_escalation" {
  count = var.enable_escalation ? 1 : 0

  name     = "${var.project_name}-${var.environment}-alert-escalation"
  role_arn = aws_iam_role.escalation_step_function[0].arn

  definition = jsonencode({
    Comment = "Alert escalation workflow"
    StartAt = "WaitForAcknowledgment"
    States = {
      WaitForAcknowledgment = {
        Type    = "Wait"
        Seconds = var.escalation_wait_time
        Next    = "CheckAcknowledgment"
      }
      CheckAcknowledgment = {
        Type = "Task"
        Resource = "arn:aws:states:::dynamodb:getItem"
        Parameters = {
          TableName = aws_dynamodb_table.alert_state[0].name
          Key = {
            AlertId = {
              "S.$" = "$.alertId"
            }
          }
        }
        Next = "IsAcknowledged"
      }
      IsAcknowledged = {
        Type = "Choice"
        Choices = [
          {
            Variable     = "$.Item.Acknowledged.BOOL"
            BooleanEquals = true
            Next         = "Success"
          }
        ]
        Default = "EscalateAlert"
      }
      EscalateAlert = {
        Type = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = aws_sns_topic.critical[0].arn
          Message = {
            "default" = "ESCALATED: Alert not acknowledged within timeout"
            "alertId.$" = "$.alertId"
            "message.$" = "$.message"
          }
        }
        Next = "Success"
      }
      Success = {
        Type = "Succeed"
      }
    }
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-alert-escalation"
      Environment = var.environment
    }
  )
}
