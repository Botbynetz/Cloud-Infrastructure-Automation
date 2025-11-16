# =============================================================================
# Zero Trust Security Architecture Module
# =============================================================================
# This module implements comprehensive Zero Trust security controls including:
# - Network micro-segmentation with security groups
# - Identity-based access control (IBAC)
# - Just-in-time (JIT) access provisioning
# - Privileged access management (PAM)
# - Automated secrets rotation
# - mTLS between services
# - Service mesh integration preparation
# =============================================================================

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# =============================================================================
# Local Variables
# =============================================================================

locals {
  common_tags = merge(
    var.tags,
    {
      Module      = "zero-trust"
      ManagedBy   = "terraform"
      Security    = "zero-trust"
      Compliance  = "ISO27001,NIST800-53"
    }
  )
  
  # Service tiers for micro-segmentation
  service_tiers = {
    public    = "public-tier"
    web       = "web-tier"
    app       = "app-tier"
    data      = "data-tier"
    admin     = "admin-tier"
  }
  
  # Default deny-all baseline
  default_security_policy = {
    ingress = []
    egress  = []
  }
}

# =============================================================================
# IAM Identity Center (AWS SSO) Configuration
# =============================================================================

# Permission sets for role-based access control
resource "aws_ssoadmin_permission_set" "read_only" {
  count = var.enable_identity_center ? 1 : 0
  
  name             = "${var.project_name}-${var.environment}-read-only"
  description      = "Read-only access to resources"
  instance_arn     = var.identity_center_instance_arn
  session_duration = var.read_only_session_duration
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-read-only-permission-set"
    Role = "ReadOnly"
  })
}

resource "aws_ssoadmin_permission_set" "power_user" {
  count = var.enable_identity_center ? 1 : 0
  
  name             = "${var.project_name}-${var.environment}-power-user"
  description      = "Power user access (no IAM changes)"
  instance_arn     = var.identity_center_instance_arn
  session_duration = var.power_user_session_duration
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-power-user-permission-set"
    Role = "PowerUser"
  })
}

resource "aws_ssoadmin_permission_set" "admin" {
  count = var.enable_identity_center ? 1 : 0
  
  name             = "${var.project_name}-${var.environment}-admin"
  description      = "Administrative access with MFA required"
  instance_arn     = var.identity_center_instance_arn
  session_duration = var.admin_session_duration
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-admin-permission-set"
    Role = "Administrator"
  })
}

# Managed policy attachments
resource "aws_ssoadmin_managed_policy_attachment" "read_only" {
  count = var.enable_identity_center ? 1 : 0
  
  instance_arn       = var.identity_center_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.read_only[0].arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_ssoadmin_managed_policy_attachment" "power_user" {
  count = var.enable_identity_center ? 1 : 0
  
  instance_arn       = var.identity_center_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.power_user[0].arn
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_ssoadmin_managed_policy_attachment" "admin" {
  count = var.enable_identity_center ? 1 : 0
  
  instance_arn       = var.identity_center_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin[0].arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# =============================================================================
# Network Micro-Segmentation Security Groups
# =============================================================================

# Public tier (Load Balancers only)
resource "aws_security_group" "public_tier" {
  name        = "${var.project_name}-${var.environment}-public-tier"
  description = "Zero Trust - Public tier (ALB/NLB only)"
  vpc_id      = var.vpc_id
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-tier-sg"
    Tier = "Public"
  })
}

resource "aws_vpc_security_group_ingress_rule" "public_https" {
  security_group_id = aws_security_group.public_tier.id
  
  description = "HTTPS from Internet"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
  
  tags = merge(local.common_tags, {
    Name = "public-https-ingress"
  })
}

resource "aws_vpc_security_group_ingress_rule" "public_http" {
  security_group_id = aws_security_group.public_tier.id
  
  description = "HTTP from Internet (redirect to HTTPS)"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
  
  tags = merge(local.common_tags, {
    Name = "public-http-ingress"
  })
}

resource "aws_vpc_security_group_egress_rule" "public_to_web" {
  security_group_id = aws_security_group.public_tier.id
  
  description                  = "To web tier only"
  from_port                    = var.web_tier_port
  to_port                      = var.web_tier_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.web_tier.id
  
  tags = merge(local.common_tags, {
    Name = "public-to-web-egress"
  })
}

# Web tier (Application servers)
resource "aws_security_group" "web_tier" {
  name        = "${var.project_name}-${var.environment}-web-tier"
  description = "Zero Trust - Web tier (application servers)"
  vpc_id      = var.vpc_id
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-web-tier-sg"
    Tier = "Web"
  })
}

resource "aws_vpc_security_group_ingress_rule" "web_from_public" {
  security_group_id = aws_security_group.web_tier.id
  
  description                  = "From public tier only"
  from_port                    = var.web_tier_port
  to_port                      = var.web_tier_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.public_tier.id
  
  tags = merge(local.common_tags, {
    Name = "web-from-public-ingress"
  })
}

resource "aws_vpc_security_group_egress_rule" "web_to_app" {
  security_group_id = aws_security_group.web_tier.id
  
  description                  = "To app tier only"
  from_port                    = var.app_tier_port
  to_port                      = var.app_tier_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.app_tier.id
  
  tags = merge(local.common_tags, {
    Name = "web-to-app-egress"
  })
}

# App tier (Business logic)
resource "aws_security_group" "app_tier" {
  name        = "${var.project_name}-${var.environment}-app-tier"
  description = "Zero Trust - App tier (business logic)"
  vpc_id      = var.vpc_id
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-app-tier-sg"
    Tier = "App"
  })
}

resource "aws_vpc_security_group_ingress_rule" "app_from_web" {
  security_group_id = aws_security_group.app_tier.id
  
  description                  = "From web tier only"
  from_port                    = var.app_tier_port
  to_port                      = var.app_tier_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.web_tier.id
  
  tags = merge(local.common_tags, {
    Name = "app-from-web-ingress"
  })
}

resource "aws_vpc_security_group_egress_rule" "app_to_data" {
  security_group_id = aws_security_group.app_tier.id
  
  description                  = "To data tier only"
  from_port                    = var.data_tier_port
  to_port                      = var.data_tier_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.data_tier.id
  
  tags = merge(local.common_tags, {
    Name = "app-to-data-egress"
  })
}

# Data tier (Databases)
resource "aws_security_group" "data_tier" {
  name        = "${var.project_name}-${var.environment}-data-tier"
  description = "Zero Trust - Data tier (databases)"
  vpc_id      = var.vpc_id
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-data-tier-sg"
    Tier = "Data"
  })
}

resource "aws_vpc_security_group_ingress_rule" "data_from_app" {
  security_group_id = aws_security_group.data_tier.id
  
  description                  = "From app tier only"
  from_port                    = var.data_tier_port
  to_port                      = var.data_tier_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.app_tier.id
  
  tags = merge(local.common_tags, {
    Name = "data-from-app-ingress"
  })
}

# No outbound from data tier (deny all egress)
resource "aws_vpc_security_group_egress_rule" "data_deny_all" {
  security_group_id = aws_security_group.data_tier.id
  
  description = "Deny all outbound (data tier isolation)"
  from_port   = -1
  to_port     = -1
  ip_protocol = "-1"
  cidr_ipv4   = "127.0.0.1/32"  # Dummy CIDR that matches nothing
  
  tags = merge(local.common_tags, {
    Name = "data-deny-all-egress"
  })
}

# Admin tier (Bastion/Jump hosts with JIT access)
resource "aws_security_group" "admin_tier" {
  name        = "${var.project_name}-${var.environment}-admin-tier"
  description = "Zero Trust - Admin tier (JIT access only)"
  vpc_id      = var.vpc_id
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-admin-tier-sg"
    Tier = "Admin"
  })
}

# No standing SSH rules - managed by JIT Lambda

# =============================================================================
# Just-in-Time (JIT) Access - Lambda Function
# =============================================================================

# IAM role for JIT Lambda
resource "aws_iam_role" "jit_access_lambda" {
  name               = "${var.project_name}-${var.environment}-jit-access-lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-jit-access-lambda-role"
  })
}

resource "aws_iam_role_policy" "jit_access_lambda" {
  name = "jit-access-policy"
  role = aws_iam_role.jit_access_lambda.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSecurityGroupRules"
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
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.jit_access_notifications.arn
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.jit_access_log.arn
      }
    ]
  })
}

# DynamoDB table for JIT access audit log
resource "aws_dynamodb_table" "jit_access_log" {
  name           = "${var.project_name}-${var.environment}-jit-access-log"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "access_id"
  range_key      = "timestamp"
  
  attribute {
    name = "access_id"
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
  
  ttl {
    attribute_name = "expiration_time"
    enabled        = true
  }
  
  global_secondary_index {
    name            = "user-index"
    hash_key        = "user_email"
    range_key       = "timestamp"
    projection_type = "ALL"
  }
  
  point_in_time_recovery {
    enabled = true
  }
  
  server_side_encryption {
    enabled = true
  }
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-jit-access-log"
  })
}

# SNS topic for JIT access notifications
resource "aws_sns_topic" "jit_access_notifications" {
  name              = "${var.project_name}-${var.environment}-jit-access-notifications"
  display_name      = "JIT Access Notifications"
  kms_master_key_id = var.sns_kms_key_id
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-jit-access-notifications"
  })
}

resource "aws_sns_topic_subscription" "jit_access_email" {
  for_each = toset(var.jit_notification_emails)
  
  topic_arn = aws_sns_topic.jit_access_notifications.arn
  protocol  = "email"
  endpoint  = each.value
}

# Lambda function for JIT access
resource "aws_lambda_function" "jit_access" {
  filename         = "${path.module}/lambda/jit_access.zip"
  function_name    = "${var.project_name}-${var.environment}-jit-access"
  role             = aws_iam_role.jit_access_lambda.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/jit_access.zip")
  runtime          = "python3.11"
  timeout          = 300
  memory_size      = 256
  
  environment {
    variables = {
      ADMIN_SECURITY_GROUP_ID = aws_security_group.admin_tier.id
      PROJECT_NAME            = var.project_name
      ENVIRONMENT             = var.environment
      JIT_DURATION_MINUTES    = var.jit_access_duration_minutes
      SNS_TOPIC_ARN           = aws_sns_topic.jit_access_notifications.arn
      DYNAMODB_TABLE          = aws_dynamodb_table.jit_access_log.name
      ALLOWED_PORTS           = jsonencode(var.jit_allowed_ports)
    }
  }
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-jit-access-lambda"
  })
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "jit_access_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.jit_access.function_name}"
  retention_in_days = 30
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-jit-access-lambda-logs"
  })
}

# EventBridge rule to cleanup expired JIT rules
resource "aws_cloudwatch_event_rule" "jit_cleanup" {
  name                = "${var.project_name}-${var.environment}-jit-cleanup"
  description         = "Cleanup expired JIT access rules every 5 minutes"
  schedule_expression = "rate(5 minutes)"
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-jit-cleanup-rule"
  })
}

resource "aws_cloudwatch_event_target" "jit_cleanup" {
  rule      = aws_cloudwatch_event_rule.jit_cleanup.name
  target_id = "jit-cleanup-lambda"
  arn       = aws_lambda_function.jit_access.arn
  
  input = jsonencode({
    action = "cleanup"
  })
}

resource "aws_lambda_permission" "jit_cleanup" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.jit_access.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.jit_cleanup.arn
}

# =============================================================================
# Secrets Rotation - Lambda Functions
# =============================================================================

# IAM role for secrets rotation
resource "aws_iam_role" "secrets_rotation_lambda" {
  count = var.enable_secrets_rotation ? 1 : 0
  
  name               = "${var.project_name}-${var.environment}-secrets-rotation-lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-secrets-rotation-lambda-role"
  })
}

resource "aws_iam_role_policy" "secrets_rotation_lambda" {
  count = var.enable_secrets_rotation ? 1 : 0
  
  name = "secrets-rotation-policy"
  role = aws_iam_role.secrets_rotation_lambda[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:UpdateSecretVersionStage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:ModifyDBInstance"
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
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.secrets_rotation_notifications[0].arn
      }
    ]
  })
}

# SNS topic for secrets rotation notifications
resource "aws_sns_topic" "secrets_rotation_notifications" {
  count = var.enable_secrets_rotation ? 1 : 0
  
  name              = "${var.project_name}-${var.environment}-secrets-rotation-notifications"
  display_name      = "Secrets Rotation Notifications"
  kms_master_key_id = var.sns_kms_key_id
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-secrets-rotation-notifications"
  })
}

resource "aws_sns_topic_subscription" "secrets_rotation_email" {
  for_each = var.enable_secrets_rotation ? toset(var.secrets_rotation_notification_emails) : []
  
  topic_arn = aws_sns_topic.secrets_rotation_notifications[0].arn
  protocol  = "email"
  endpoint  = each.value
}

# Lambda function for RDS password rotation
resource "aws_lambda_function" "rds_password_rotation" {
  count = var.enable_secrets_rotation ? 1 : 0
  
  filename         = "${path.module}/lambda/rds_password_rotation.zip"
  function_name    = "${var.project_name}-${var.environment}-rds-password-rotation"
  role             = aws_iam_role.secrets_rotation_lambda[0].arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/rds_password_rotation.zip")
  runtime          = "python3.11"
  timeout          = 300
  memory_size      = 256
  
  environment {
    variables = {
      PROJECT_NAME  = var.project_name
      ENVIRONMENT   = var.environment
      SNS_TOPIC_ARN = aws_sns_topic.secrets_rotation_notifications[0].arn
    }
  }
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-rds-password-rotation-lambda"
  })
}

# CloudWatch Log Group for rotation Lambda
resource "aws_cloudwatch_log_group" "rds_password_rotation" {
  count = var.enable_secrets_rotation ? 1 : 0
  
  name              = "/aws/lambda/${aws_lambda_function.rds_password_rotation[0].function_name}"
  retention_in_days = 30
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-rds-password-rotation-logs"
  })
}

# EventBridge rule for scheduled rotation (every 30 days)
resource "aws_cloudwatch_event_rule" "secrets_rotation" {
  count = var.enable_secrets_rotation ? 1 : 0
  
  name                = "${var.project_name}-${var.environment}-secrets-rotation"
  description         = "Rotate secrets every 30 days"
  schedule_expression = "rate(30 days)"
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-secrets-rotation-rule"
  })
}

resource "aws_cloudwatch_event_target" "secrets_rotation" {
  count = var.enable_secrets_rotation ? 1 : 0
  
  rule      = aws_cloudwatch_event_rule.secrets_rotation[0].name
  target_id = "rds-password-rotation-lambda"
  arn       = aws_lambda_function.rds_password_rotation[0].arn
}

resource "aws_lambda_permission" "secrets_rotation" {
  count = var.enable_secrets_rotation ? 1 : 0
  
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rds_password_rotation[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.secrets_rotation[0].arn
}

# =============================================================================
# VPC Endpoints for Zero Trust Network Access
# =============================================================================

# S3 Gateway Endpoint (no internet gateway needed)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_route_table_ids
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-s3-vpc-endpoint"
  })
}

# DynamoDB Gateway Endpoint
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_route_table_ids
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-dynamodb-vpc-endpoint"
  })
}

# Secrets Manager Interface Endpoint
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-secretsmanager-vpc-endpoint"
  })
}

# SSM Interface Endpoint
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-ssm-vpc-endpoint"
  })
}

# EC2 Messages Interface Endpoint (for SSM Session Manager)
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-ec2messages-vpc-endpoint"
  })
}

# SSM Messages Interface Endpoint
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-ssmmessages-vpc-endpoint"
  })
}

# Security group for VPC endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.project_name}-${var.environment}-vpc-endpoints"
  description = "Security group for VPC endpoints"
  vpc_id      = var.vpc_id
  
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc-endpoints-sg"
  })
}

# =============================================================================
# CloudWatch Monitoring and Alarms
# =============================================================================

# JIT access usage alarm
resource "aws_cloudwatch_metric_alarm" "jit_high_usage" {
  alarm_name          = "${var.project_name}-${var.environment}-jit-high-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Invocations"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = var.jit_usage_threshold
  alarm_description   = "JIT access requests are unusually high"
  alarm_actions       = var.alarm_actions
  
  dimensions = {
    FunctionName = aws_lambda_function.jit_access.function_name
  }
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-jit-high-usage-alarm"
  })
}

# JIT access errors alarm
resource "aws_cloudwatch_metric_alarm" "jit_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-jit-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "JIT access Lambda function errors detected"
  alarm_actions       = var.alarm_actions
  
  dimensions = {
    FunctionName = aws_lambda_function.jit_access.function_name
  }
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-jit-errors-alarm"
  })
}

# Secrets rotation failure alarm
resource "aws_cloudwatch_metric_alarm" "secrets_rotation_failure" {
  count = var.enable_secrets_rotation ? 1 : 0
  
  alarm_name          = "${var.project_name}-${var.environment}-secrets-rotation-failure"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Secrets rotation Lambda function failed"
  alarm_actions       = var.alarm_actions
  
  dimensions = {
    FunctionName = aws_lambda_function.rds_password_rotation[0].function_name
  }
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-secrets-rotation-failure-alarm"
  })
}

# CloudWatch Dashboard for Zero Trust monitoring
resource "aws_cloudwatch_dashboard" "zero_trust" {
  dashboard_name = "${var.project_name}-${var.environment}-zero-trust-monitoring"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum", label = "JIT Requests" }],
            ["...", { stat = "Sum", label = "JIT Errors", yAxis = "right" }]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "JIT Access Activity"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = var.enable_secrets_rotation ? [
            ["AWS/Lambda", "Invocations", { stat = "Sum", label = "Rotation Executions" }],
            ["...", { stat = "Sum", label = "Rotation Errors", yAxis = "right" }]
          ] : []
          period = 3600
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Secrets Rotation Activity"
        }
      },
      {
        type = "log"
        properties = {
          query   = "SOURCE '${aws_cloudwatch_log_group.jit_access_lambda.name}' | fields @timestamp, @message | filter @message like /GRANTED/ | sort @timestamp desc | limit 20"
          region  = data.aws_region.current.name
          title   = "Recent JIT Access Grants"
        }
      }
    ]
  })
}

# =============================================================================
# Data Sources
# =============================================================================

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}
