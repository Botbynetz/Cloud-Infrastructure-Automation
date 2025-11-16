# ==============================================================================
# GitOps & Advanced CI/CD Module
# Git as Single Source of Truth with ArgoCD/FluxCD Integration
# ==============================================================================

terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

# ------------------------------------------------------------------------------
# S3 Bucket for GitOps State & Artifacts
# ------------------------------------------------------------------------------

resource "aws_s3_bucket" "gitops_artifacts" {
  bucket = "${var.project_name}-gitops-artifacts-${var.environment}"
  tags = merge(var.tags, {
    Name = "GitOps Artifacts Storage"
  })
}

resource "aws_s3_bucket_versioning" "gitops_artifacts" {
  bucket = aws_s3_bucket.gitops_artifacts.id
  versioning_configuration { status = "Enabled" }
}

# ------------------------------------------------------------------------------
# DynamoDB for Deployment Tracking
# ------------------------------------------------------------------------------

resource "aws_dynamodb_table" "deployments" {
  name = "${var.project_name}-deployments-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "deployment_id"
  range_key = "timestamp"

  attribute {
    name = "deployment_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "git_commit"
    type = "S"
  }

  global_secondary_index {
    name = "StatusIndex"
    hash_key = "status"
    range_key = "timestamp"
    projection_type = "ALL"
  }

  global_secondary_index {
    name = "CommitIndex"
    hash_key = "git_commit"
    range_key = "timestamp"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ttl"
    enabled = true
  }

  tags = merge(var.tags, {
    Name = "GitOps Deployment Tracking"
  })
}

# ------------------------------------------------------------------------------
# DynamoDB for DORA Metrics
# ------------------------------------------------------------------------------

resource "aws_dynamodb_table" "dora_metrics" {
  name = "${var.project_name}-dora-metrics-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "metric_type"
  range_key = "timestamp"

  attribute {
    name = "metric_type"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  ttl {
    attribute_name = "ttl"
    enabled = true
  }

  tags = merge(var.tags, {
    Name = "DORA Metrics Storage"
  })
}

# ------------------------------------------------------------------------------
# CodePipeline for GitOps
# ------------------------------------------------------------------------------

resource "aws_codepipeline" "gitops" {
  name = "${var.project_name}-gitops-pipeline-${var.environment}"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.gitops_artifacts.bucket
    type = "S3"
  }

  stage {
    name = "Source"
    action {
      name = "Source"
      category = "Source"
      owner = "AWS"
      provider = "CodeStarSourceConnection"
      version = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn = var.codestar_connection_arn
        FullRepositoryId = var.git_repository
        BranchName = var.git_branch
        DetectChanges = true
      }
    }
  }

  stage {
    name = "Build"
    action {
      name = "Build"
      category = "Build"
      owner = "AWS"
      provider = "CodeBuild"
      version = "1"
      input_artifacts = ["source_output"]
      output_artifacts = ["build_output"]
      configuration = {
        ProjectName = aws_codebuild_project.gitops_build.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name = "Deploy"
      category = "Invoke"
      owner = "AWS"
      provider = "Lambda"
      version = "1"
      input_artifacts = ["build_output"]
      configuration = {
        FunctionName = aws_lambda_function.gitops_deployer.function_name
      }
    }
  }

  tags = var.tags
}

# ------------------------------------------------------------------------------
# CodeBuild for GitOps Build
# ------------------------------------------------------------------------------

resource "aws_codebuild_project" "gitops_build" {
  name = "${var.project_name}-gitops-build-${var.environment}"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/standard:7.0"
    type = "LINUX_CONTAINER"
    privileged_mode = true  # For Docker builds

    environment_variable {
      name = "ENVIRONMENT"
      value = var.environment
    }
  }

  source {
    type = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name = "/aws/codebuild/${var.project_name}-gitops"
      stream_name = var.environment
    }
  }

  tags = var.tags
}

# ------------------------------------------------------------------------------
# IAM Roles
# ------------------------------------------------------------------------------

resource "aws_iam_role" "codepipeline_role" {
  name = "${var.project_name}-codepipeline-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "codepipeline.amazonaws.com" }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline-policy"
  role = aws_iam_role.codepipeline_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.gitops_artifacts.arn,
          "${aws_s3_bucket.gitops_artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = aws_codebuild_project.gitops_build.arn
      },
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = var.codestar_connection_arn
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.gitops_deployer.arn
      }
    ]
  })
}

resource "aws_iam_role" "codebuild_role" {
  name = "${var.project_name}-codebuild-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "codebuild.amazonaws.com" }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "codebuild-policy"
  role = aws_iam_role.codebuild_role.id
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
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.gitops_artifacts.arn}/*"
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# Lambda - GitOps Deployer
# ------------------------------------------------------------------------------

resource "aws_iam_role" "gitops_deployer_role" {
  name = "${var.project_name}-gitops-deployer-${var.environment}"
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

resource "aws_iam_role_policy" "gitops_deployer_policy" {
  name = "gitops-deployer-policy"
  role = aws_iam_role.gitops_deployer_role.id
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
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]
        Resource = [
          aws_dynamodb_table.deployments.arn,
          aws_dynamodb_table.dora_metrics.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.gitops_artifacts.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "lambda:UpdateFunctionCode"
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

resource "aws_lambda_function" "gitops_deployer" {
  filename = "${path.module}/lambda/gitops_deployer.zip"
  function_name = "${var.project_name}-gitops-deployer-${var.environment}"
  role = aws_iam_role.gitops_deployer_role.arn
  handler = "gitops_deployer.handler"
  runtime = "python3.11"
  timeout = 300
  memory_size = 512

  environment {
    variables = {
      DEPLOYMENTS_TABLE = aws_dynamodb_table.deployments.name
      DORA_METRICS_TABLE = aws_dynamodb_table.dora_metrics.name
      SNS_TOPIC_ARN = var.sns_topic_arn
      ENVIRONMENT = var.environment
    }
  }

  tags = merge(var.tags, {
    Name = "GitOps Deployer Lambda"
  })
}

# ------------------------------------------------------------------------------
# Lambda - DORA Metrics Collector
# ------------------------------------------------------------------------------

resource "aws_iam_role" "dora_collector_role" {
  name = "${var.project_name}-dora-collector-${var.environment}"
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

resource "aws_iam_role_policy" "dora_collector_policy" {
  name = "dora-collector-policy"
  role = aws_iam_role.dora_collector_role.id
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
          "dynamodb:Scan",
          "dynamodb:PutItem"
        ]
        Resource = [
          aws_dynamodb_table.deployments.arn,
          aws_dynamodb_table.dora_metrics.arn,
          "${aws_dynamodb_table.deployments.arn}/index/*"
        ]
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

resource "aws_lambda_function" "dora_collector" {
  filename = "${path.module}/lambda/dora_collector.zip"
  function_name = "${var.project_name}-dora-collector-${var.environment}"
  role = aws_iam_role.dora_collector_role.arn
  handler = "dora_collector.handler"
  runtime = "python3.11"
  timeout = 300
  memory_size = 512

  environment {
    variables = {
      DEPLOYMENTS_TABLE = aws_dynamodb_table.deployments.name
      DORA_METRICS_TABLE = aws_dynamodb_table.dora_metrics.name
      ENVIRONMENT = var.environment
    }
  }

  tags = merge(var.tags, {
    Name = "DORA Metrics Collector"
  })
}

# Daily DORA metrics calculation
resource "aws_cloudwatch_event_rule" "daily_dora" {
  name = "${var.project_name}-daily-dora-${var.environment}"
  description = "Calculate DORA metrics daily"
  schedule_expression = "cron(0 1 * * ? *)"  # 1 AM daily
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "dora_collector" {
  rule = aws_cloudwatch_event_rule.daily_dora.name
  arn = aws_lambda_function.dora_collector.arn
}

resource "aws_lambda_permission" "allow_eventbridge_dora" {
  statement_id = "AllowExecutionFromEventBridge"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dora_collector.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.daily_dora.arn
}

# ------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------

output "pipeline_name" {
  description = "CodePipeline name"
  value = aws_codepipeline.gitops.name
}

output "deployments_table" {
  description = "Deployments DynamoDB table"
  value = aws_dynamodb_table.deployments.name
}

output "dora_metrics_table" {
  description = "DORA metrics DynamoDB table"
  value = aws_dynamodb_table.dora_metrics.name
}
