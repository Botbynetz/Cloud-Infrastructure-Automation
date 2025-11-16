# ==============================================================================
# Multi-Cloud & Hybrid Cloud Module
# Cloud Abstraction Layer for AWS + Azure + GCP
# ==============================================================================

terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

# ------------------------------------------------------------------------------
# S3 Bucket for Multi-Cloud State & Metadata
# ------------------------------------------------------------------------------

resource "aws_s3_bucket" "multi_cloud_state" {
  bucket = "${var.project_name}-multi-cloud-state-${var.environment}"
  tags = merge(var.tags, {
    Name = "Multi-Cloud State Storage"
  })
}

resource "aws_s3_bucket_versioning" "multi_cloud_state" {
  bucket = aws_s3_bucket.multi_cloud_state.id
  versioning_configuration { status = "Enabled" }
}

# ------------------------------------------------------------------------------
# DynamoDB for Resource Inventory (Multi-Cloud)
# ------------------------------------------------------------------------------

resource "aws_dynamodb_table" "resource_inventory" {
  name = "${var.project_name}-resource-inventory-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "resource_id"
  range_key = "cloud_provider"

  attribute {
    name = "resource_id"
    type = "S"
  }

  attribute {
    name = "cloud_provider"
    type = "S"
  }

  attribute {
    name = "resource_type"
    type = "S"
  }

  global_secondary_index {
    name = "TypeIndex"
    hash_key = "resource_type"
    range_key = "cloud_provider"
    projection_type = "ALL"
  }

  tags = merge(var.tags, {
    Name = "Multi-Cloud Resource Inventory"
  })
}

# ------------------------------------------------------------------------------
# DynamoDB for Cost Tracking (Multi-Cloud)
# ------------------------------------------------------------------------------

resource "aws_dynamodb_table" "cost_tracking" {
  name = "${var.project_name}-multi-cloud-costs-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "date"
  range_key = "cloud_provider"

  attribute {
    name = "date"
    type = "S"
  }

  attribute {
    name = "cloud_provider"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled = true
  }

  tags = merge(var.tags, {
    Name = "Multi-Cloud Cost Tracking"
  })
}

# ------------------------------------------------------------------------------
# API Gateway for Unified Multi-Cloud API
# ------------------------------------------------------------------------------

resource "aws_apigatewayv2_api" "multi_cloud_api" {
  name = "${var.project_name}-multi-cloud-api-${var.environment}"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE"]
    allow_headers = ["*"]
  }
  tags = var.tags
}

resource "aws_apigatewayv2_stage" "multi_cloud_api" {
  api_id = aws_apigatewayv2_api.multi_cloud_api.id
  name = var.environment
  auto_deploy = true
  tags = var.tags
}

# ------------------------------------------------------------------------------
# Lambda - Cloud Abstraction Layer
# ------------------------------------------------------------------------------

resource "aws_iam_role" "cloud_abstraction_role" {
  name = "${var.project_name}-cloud-abstraction-${var.environment}"
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

resource "aws_iam_role_policy" "cloud_abstraction_policy" {
  name = "cloud-abstraction-policy"
  role = aws_iam_role.cloud_abstraction_role.id
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
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          aws_dynamodb_table.resource_inventory.arn,
          aws_dynamodb_table.cost_tracking.arn,
          "${aws_dynamodb_table.resource_inventory.arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.cloud_credentials_secret_arn
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "rds:*",
          "s3:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "cloud_abstraction" {
  filename = "${path.module}/lambda/cloud_abstraction.zip"
  function_name = "${var.project_name}-cloud-abstraction-${var.environment}"
  role = aws_iam_role.cloud_abstraction_role.arn
  handler = "cloud_abstraction.handler"
  runtime = "python3.11"
  timeout = 300
  memory_size = 1024

  environment {
    variables = {
      INVENTORY_TABLE = aws_dynamodb_table.resource_inventory.name
      COST_TABLE = aws_dynamodb_table.cost_tracking.name
      CREDENTIALS_SECRET = var.cloud_credentials_secret_arn
      ENVIRONMENT = var.environment
    }
  }

  tags = merge(var.tags, {
    Name = "Cloud Abstraction Layer"
  })
}

# API Gateway integrations
resource "aws_apigatewayv2_integration" "provision" {
  api_id = aws_apigatewayv2_api.multi_cloud_api.id
  integration_type = "AWS_PROXY"
  integration_uri = aws_lambda_function.cloud_abstraction.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "provision" {
  api_id = aws_apigatewayv2_api.multi_cloud_api.id
  route_key = "POST /provision"
  target = "integrations/${aws_apigatewayv2_integration.provision.id}"
}

resource "aws_apigatewayv2_route" "list_resources" {
  api_id = aws_apigatewayv2_api.multi_cloud_api.id
  route_key = "GET /resources"
  target = "integrations/${aws_apigatewayv2_integration.provision.id}"
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloud_abstraction.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.multi_cloud_api.execution_arn}/*/*"
}

# ------------------------------------------------------------------------------
# Lambda - Cost Aggregator
# ------------------------------------------------------------------------------

resource "aws_iam_role" "cost_aggregator_role" {
  name = "${var.project_name}-cost-aggregator-${var.environment}"
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

resource "aws_iam_role_policy" "cost_aggregator_policy" {
  name = "cost-aggregator-policy"
  role = aws_iam_role.cost_aggregator_role.id
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
          "dynamodb:Query"
        ]
        Resource = aws_dynamodb_table.cost_tracking.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ce:GetCostAndUsage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.cloud_credentials_secret_arn
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "cost_aggregator" {
  filename = "${path.module}/lambda/cost_aggregator.zip"
  function_name = "${var.project_name}-cost-aggregator-${var.environment}"
  role = aws_iam_role.cost_aggregator_role.arn
  handler = "cost_aggregator.handler"
  runtime = "python3.11"
  timeout = 300
  memory_size = 512

  environment {
    variables = {
      COST_TABLE = aws_dynamodb_table.cost_tracking.name
      CREDENTIALS_SECRET = var.cloud_credentials_secret_arn
      ENVIRONMENT = var.environment
    }
  }

  tags = merge(var.tags, {
    Name = "Multi-Cloud Cost Aggregator"
  })
}

# Daily cost aggregation
resource "aws_cloudwatch_event_rule" "daily_cost_aggregation" {
  name = "${var.project_name}-daily-cost-agg-${var.environment}"
  description = "Aggregate multi-cloud costs daily"
  schedule_expression = "cron(0 3 * * ? *)"  # 3 AM daily
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "cost_aggregator" {
  rule = aws_cloudwatch_event_rule.daily_cost_aggregation.name
  arn = aws_lambda_function.cost_aggregator.arn
}

resource "aws_lambda_permission" "allow_eventbridge_cost" {
  statement_id = "AllowExecutionFromEventBridge"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_aggregator.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.daily_cost_aggregation.arn
}

# ------------------------------------------------------------------------------
# CloudWatch Dashboard
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "multi_cloud" {
  dashboard_name = "${var.project_name}-multi-cloud-${var.environment}"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title = "Multi-Cloud API Requests"
          metrics = [
            ["AWS/ApiGateway", "Count", { stat = "Sum" }]
          ]
          period = 300
          stat = "Sum"
          region = var.aws_region
        }
      },
      {
        type = "metric"
        properties = {
          title = "Cost Aggregator Invocations"
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum" }]
          ]
          period = 86400
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

output "api_endpoint" {
  description = "Multi-cloud API endpoint"
  value = aws_apigatewayv2_stage.multi_cloud_api.invoke_url
}

output "resource_inventory_table" {
  description = "Resource inventory DynamoDB table"
  value = aws_dynamodb_table.resource_inventory.name
}

output "cost_tracking_table" {
  description = "Cost tracking DynamoDB table"
  value = aws_dynamodb_table.cost_tracking.name
}

output "cloud_abstraction_function" {
  description = "Cloud abstraction Lambda ARN"
  value = aws_lambda_function.cloud_abstraction.arn
}
