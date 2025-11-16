# Self-Service Portal Module
# Internal Developer Platform (IDP) for infrastructure provisioning

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# API Gateway for portal backend
resource "aws_apigatewayv2_api" "portal" {
  name          = "${var.project_name}-${var.environment}-portal-api"
  protocol_type = "HTTP"
  
  cors_configuration {
    allow_origins = var.allowed_origins
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["*"]
    max_age       = 3600
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-portal-api"
  })
}

# Cognito User Pool for authentication
resource "aws_cognito_user_pool" "portal" {
  name = "${var.project_name}-${var.environment}-portal-users"

  password_policy {
    minimum_length    = 12
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = true
  }

  mfa_configuration = "OPTIONAL"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-portal-users"
  })
}

# DynamoDB for request tracking
resource "aws_dynamodb_table" "requests" {
  name           = "${var.project_name}-${var.environment}-portal-requests"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "request_id"
  range_key      = "timestamp"

  attribute {
    name = "request_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  attribute {
    name = "user_email"
    type = "S"
  }

  global_secondary_index {
    name            = "UserEmailIndex"
    hash_key        = "user_email"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-portal-requests"
  })
}

# Lambda: Provision Infrastructure
resource "aws_lambda_function" "provision_infra" {
  filename         = "${path.module}/lambda/provision_infra.zip"
  function_name    = "${var.project_name}-${var.environment}-provision-infra"
  role             = aws_iam_role.portal_lambda.arn
  handler          = "provision_infra.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/provision_infra.zip")
  runtime          = "python3.11"
  timeout          = 900
  memory_size      = 1024

  environment {
    variables = {
      PROJECT_NAME       = var.project_name
      ENVIRONMENT        = var.environment
      REQUESTS_TABLE     = aws_dynamodb_table.requests.name
      ENABLE_AUTO_APPROVE = var.enable_auto_approve
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-provision-infra"
  })
}

# IAM role for Lambda
resource "aws_iam_role" "portal_lambda" {
  name = "${var.project_name}-${var.environment}-portal-lambda"

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
    Name = "${var.project_name}-${var.environment}-portal-lambda-role"
  })
}

resource "aws_iam_role_policy" "portal_lambda" {
  name = "portal-lambda-policy"
  role = aws_iam_role.portal_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          aws_dynamodb_table.requests.arn,
          "${aws_dynamodb_table.requests.arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "rds:*",
          "s3:*",
          "elasticloadbalancing:*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
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

# API Gateway integration
resource "aws_apigatewayv2_integration" "provision" {
  api_id           = aws_apigatewayv2_api.portal.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.provision_infra.arn
}

resource "aws_apigatewayv2_route" "provision" {
  api_id    = aws_apigatewayv2_api.portal.id
  route_key = "POST /provision"
  target    = "integrations/${aws_apigatewayv2_integration.provision.id}"
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.provision_infra.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.portal.execution_arn}/*/*"
}

# API Gateway stage
resource "aws_apigatewayv2_stage" "portal" {
  api_id      = aws_apigatewayv2_api.portal.id
  name        = var.environment
  auto_deploy = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-portal-stage"
  })
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "portal" {
  dashboard_name = "${var.project_name}-${var.environment}-portal-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Count", { stat = "Sum" }],
            [".", "4XXError", { stat = "Sum" }],
            [".", "5XXError", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "API Gateway Metrics"
        }
      }
    ]
  })
}

output "api_endpoint" {
  description = "Portal API endpoint"
  value       = aws_apigatewayv2_api.portal.api_endpoint
}

output "cognito_user_pool_id" {
  description = "Cognito user pool ID"
  value       = aws_cognito_user_pool.portal.id
}

output "requests_table_name" {
  description = "DynamoDB requests table name"
  value       = aws_dynamodb_table.requests.name
}

data "aws_caller_identity" "current" {}
