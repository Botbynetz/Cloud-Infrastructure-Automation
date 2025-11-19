# IAM Least-Privilege Policies
# Implements principle of least privilege for Terraform automation

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ============================================
# Terraform Automation IAM Roles
# ============================================

# IAM policy document for Terraform assume role
data "aws_iam_policy_document" "terraform_assume_role" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "AWS"
      identifiers = var.allowed_assume_role_principals
    }
    
    actions = ["sts:AssumeRole"]
    
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id]
    }
  }
  
  # Allow GitHub Actions OIDC
  dynamic "statement" {
    for_each = var.enable_github_oidc ? [1] : []
    
    content {
      effect = "Allow"
      
      principals {
        type        = "Federated"
        identifiers = [var.github_oidc_provider_arn]
      }
      
      actions = ["sts:AssumeRoleWithWebIdentity"]
      
      condition {
        test     = "StringLike"
        variable = "token.actions.githubusercontent.com:sub"
        values   = ["repo:${var.github_repository}:*"]
      }
    }
  }
}

# ============================================
# Development Environment Role (Least Privilege)
# ============================================

resource "aws_iam_role" "terraform_dev" {
  count = var.create_dev_role ? 1 : 0
  
  name               = "${var.project_name}-${var.environment}-terraform-dev"
  assume_role_policy = data.aws_iam_policy_document.terraform_assume_role.json
  
  max_session_duration = 3600  # 1 hour
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-terraform-dev"
      Environment = "dev"
      Purpose     = "Terraform Development"
    }
  )
}

# Dev policy - Limited resources, specific VPC CIDR
resource "aws_iam_role_policy" "terraform_dev" {
  count = var.create_dev_role ? 1 : 0
  
  name = "${var.project_name}-dev-policy"
  role = aws_iam_role.terraform_dev[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEC2DescribeAll"
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ec2:Get*",
          "ec2:List*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowEC2InstancesInDevVPC"
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ec2:InstanceType" = ["t2.micro", "t3.micro", "t3.small"]
          }
        }
      },
      {
        Sid    = "AllowVPCOperationsDevCIDR"
        Effect = "Allow"
        Action = [
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:ModifyVpcAttribute",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:CreateInternetGateway",
          "ec2:DeleteInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:DetachInternetGateway",
          "ec2:CreateRouteTable",
          "ec2:DeleteRouteTable",
          "ec2:CreateRoute",
          "ec2:DeleteRoute",
          "ec2:AssociateRouteTable",
          "ec2:DisassociateRouteTable"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ec2:Vpc" = "10.0.0.0/16"  # Dev VPC CIDR
          }
        }
      },
      {
        Sid    = "AllowS3DevBuckets"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-dev-*",
          "arn:aws:s3:::${var.project_name}-dev-*/*"
        ]
      },
      {
        Sid    = "AllowKMSForDev"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.dev_kms_key_arn
      },
      {
        Sid    = "DenyProductionResources"
        Effect = "Deny"
        Action = "*"
        Resource = [
          "arn:aws:ec2:*:*:instance/*",
          "arn:aws:s3:::${var.project_name}-prod-*",
          "arn:aws:s3:::${var.project_name}-prod-*/*",
          "arn:aws:rds:*:*:db:*prod*"
        ]
        Condition = {
          StringLike = {
            "aws:ResourceTag/Environment" = "prod"
          }
        }
      }
    ]
  })
}

# ============================================
# Production Environment Role (Restricted)
# ============================================

resource "aws_iam_role" "terraform_prod" {
  count = var.create_prod_role ? 1 : 0
  
  name               = "${var.project_name}-${var.environment}-terraform-prod"
  assume_role_policy = data.aws_iam_policy_document.terraform_assume_role.json
  
  max_session_duration = 7200  # 2 hours (longer for production deploys)
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-terraform-prod"
      Environment = "prod"
      Purpose     = "Terraform Production"
      Critical    = "true"
    }
  )
}

# Production policy - Full access but with MFA requirement
resource "aws_iam_role_policy" "terraform_prod" {
  count = var.create_prod_role ? 1 : 0
  
  name = "${var.project_name}-prod-policy"
  role = aws_iam_role.terraform_prod[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowDescribeWithoutMFA"
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "rds:Describe*",
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowProductionOperationsWithMFA"
        Effect = "Allow"
        Action = [
          "ec2:*",
          "rds:*",
          "s3:*",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "cloudwatch:*",
          "logs:*"
        ]
        Resource = "*"
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = var.require_mfa_for_prod ? "true" : "false"
          }
          StringLike = {
            "aws:ResourceTag/Environment" = "prod"
          }
        }
      },
      {
        Sid    = "AllowKMSForProduction"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = var.prod_kms_key_arn
      },
      {
        Sid    = "DenyDeletionOfCriticalResources"
        Effect = "Deny"
        Action = [
          "rds:DeleteDBInstance",
          "rds:DeleteDBCluster",
          "s3:DeleteBucket",
          "dynamodb:DeleteTable"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Critical" = "true"
          }
        }
      }
    ]
  })
}

# ============================================
# CI/CD Service Role (GitHub Actions)
# ============================================

resource "aws_iam_role" "cicd" {
  count = var.create_cicd_role ? 1 : 0
  
  name               = "${var.project_name}-${var.environment}-cicd"
  assume_role_policy = data.aws_iam_policy_document.terraform_assume_role.json
  
  max_session_duration = 3600
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-cicd"
      Environment = var.environment
      Purpose     = "CI/CD Automation"
    }
  )
}

# CI/CD policy - Read secrets, plan only (no apply)
resource "aws_iam_role_policy" "cicd" {
  count = var.create_cicd_role ? 1 : 0
  
  name = "${var.project_name}-cicd-policy"
  role = aws_iam_role.cicd[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowDescribeAll"
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "rds:Describe*",
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowSecretsRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:${var.project_name}/${var.environment}/*"
      },
      {
        Sid    = "AllowKMSDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowTerraformState"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::${var.terraform_state_bucket}/*"
      },
      {
        Sid    = "AllowDynamoDBLock"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:*:*:table/${var.terraform_lock_table}"
      },
      {
        Sid    = "DenyDestructiveActions"
        Effect = "Deny"
        Action = [
          "ec2:Terminate*",
          "ec2:Delete*",
          "rds:Delete*",
          "s3:Delete*"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================
# Read-Only Role (Auditing)
# ============================================

resource "aws_iam_role" "readonly" {
  count = var.create_readonly_role ? 1 : 0
  
  name               = "${var.project_name}-${var.environment}-readonly"
  assume_role_policy = data.aws_iam_policy_document.terraform_assume_role.json
  
  max_session_duration = 43200  # 12 hours
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-readonly"
      Environment = var.environment
      Purpose     = "Read-Only Audit"
    }
  )
}

resource "aws_iam_role_policy_attachment" "readonly" {
  count = var.create_readonly_role ? 1 : 0
  
  role       = aws_iam_role.readonly[0].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
