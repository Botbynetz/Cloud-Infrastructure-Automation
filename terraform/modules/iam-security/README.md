# IAM Security Module - Hardened Policies

Terraform module implementing least-privilege IAM policies, roles, and security best practices for AWS infrastructure.

## Overview

This module provides:
- Least-privilege IAM roles for EC2, bastion, and Lambda
- MFA enforcement policies
- Session duration limits
- Service Control Policies (SCPs)
- Permission boundaries
- IAM Access Analyzer integration

## Features

✅ Granular permission policies  
✅ MFA requirement enforcement  
✅ Time-based session limits  
✅ Automated policy validation  
✅ Cross-account access controls  
✅ Compliance-ready configurations

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Usage

### Basic EC2 Instance Role

```hcl
module "iam_ec2" {
  source = "./modules/iam-security"

  role_name    = "ec2-webserver-role"
  role_type    = "ec2"
  
  permissions = [
    "s3:GetObject",
    "secretsmanager:GetSecretValue",
    "logs:CreateLogGroup",
    "logs:CreateLogStream",
    "logs:PutLogEvents"
  ]
  
  resource_arns = [
    "arn:aws:s3:::my-app-bucket/*",
    "arn:aws:secretsmanager:*:*:secret:app/*"
  ]
  
  enable_session_manager = true
  max_session_duration   = 3600  # 1 hour
  
  tags = {
    Environment = "production"
    Purpose     = "web-application"
  }
}
```

### Bastion Host with MFA

```hcl
module "iam_bastion" {
  source = "./modules/iam-security"

  role_name  = "bastion-admin-role"
  role_type  = "ec2"
  
  permissions = [
    "ec2:DescribeInstances",
    "ssm:StartSession",
    "ssm:SendCommand"
  ]
  
  require_mfa              = true
  max_session_duration     = 1800  # 30 minutes
  enable_session_manager   = true
  
  tags = {
    SecurityLevel = "high"
    Purpose       = "administrative-access"
  }
}
```

### CI/CD Pipeline Role

```hcl
module "iam_cicd" {
  source = "./modules/iam-security"

  role_name  = "github-actions-deploy"
  role_type  = "federated"
  
  federated_principal = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
  
  permissions = [
    "ec2:DescribeInstances",
    "ec2:StartInstances",
    "ec2:StopInstances",
    "s3:PutObject",
    "s3:GetObject",
    "secretsmanager:GetSecretValue"
  ]
  
  max_session_duration = 3600
  
  condition = {
    test     = "StringEquals"
    variable = "token.actions.githubusercontent.com:sub"
    values   = ["repo:Botbynetz/Cloud-Infrastructure-Automation:*"]
  }
  
  tags = {
    Purpose = "ci-cd-automation"
  }
}
```

## Security Best Practices

### 1. Least Privilege Principle

```hcl
# ❌ Too Permissive
permissions = ["s3:*"]

# ✅ Least Privilege
permissions = [
  "s3:GetObject",
  "s3:PutObject"
]
resource_arns = ["arn:aws:s3:::specific-bucket/specific-prefix/*"]
```

### 2. MFA Enforcement

```hcl
module "admin_role" {
  source = "./modules/iam-security"

  role_name   = "admin-with-mfa"
  role_type   = "user"
  require_mfa = true  # Forces MFA for sensitive operations
  
  mfa_age_limit = 3600  # MFA token valid for 1 hour
}
```

### 3. Session Duration Limits

```hcl
module "temp_access" {
  source = "./modules/iam-security"

  role_name            = "temporary-contractor"
  max_session_duration = 900  # 15 minutes
  
  permissions = ["ec2:DescribeInstances"]
}
```

### 4. Permission Boundaries

```hcl
module "developer_role" {
  source = "./modules/iam-security"

  role_name           = "developer"
  permission_boundary = aws_iam_policy.developer_boundary.arn
  
  # Can't exceed permissions defined in boundary
  permissions = [
    "ec2:StartInstances",
    "ec2:StopInstances"
  ]
}
```

## Pre-defined Role Templates

### Web Application Server

```hcl
module "webapp_role" {
  source = "./modules/iam-security"

  role_template = "webapp"  # Pre-configured permissions
  
  # Automatically includes:
  # - S3 read access for assets
  # - Secrets Manager read
  # - CloudWatch Logs write
  # - Session Manager access
  
  custom_bucket_arns = [
    "arn:aws:s3:::my-app-assets/*"
  ]
}
```

### Database Server

```hcl
module "db_role" {
  source = "./modules/iam-security"

  role_template = "database"
  
  # Automatically includes:
  # - RDS authentication
  # - Secrets Manager for credentials
  # - CloudWatch Logs
  # - Automated backups to S3
  
  backup_bucket_arn = "arn:aws:s3:::db-backups/*"
}
```

### Monitoring & Logging

```hcl
module "monitoring_role" {
  source = "./modules/iam-security"

  role_template = "monitoring"
  
  # Automatically includes:
  # - CloudWatch full access
  # - X-Ray tracing
  # - SNS notifications
  # - EventBridge rules
}
```

## IAM Access Analyzer Integration

```hcl
resource "aws_accessanalyzer_analyzer" "main" {
  analyzer_name = "infrastructure-analyzer"
  type          = "ACCOUNT"

  tags = {
    Name      = "IAM Access Analyzer"
    ManagedBy = "terraform"
  }
}

# Analyze findings
data "aws_accessanalyzer_findings" "external_access" {
  analyzer_arn = aws_accessanalyzer_analyzer.main.arn
  
  filter {
    criterion = "status"
    eq        = ["ACTIVE"]
  }
}
```

## Compliance Policies

### PCI-DSS Compliant Role

```hcl
module "pci_compliant_role" {
  source = "./modules/iam-security"

  role_name        = "pci-application"
  compliance_level = "pci-dss"
  
  # Automatically enforces:
  # - MFA requirement
  # - Encrypted communications
  # - Audit logging
  # - Limited session duration
  # - No wildcard permissions
  
  max_session_duration = 900  # 15 minutes max
  require_mfa          = true
  enable_audit_logging = true
}
```

### HIPAA Compliant Role

```hcl
module "hipaa_role" {
  source = "./modules/iam-security"

  role_name        = "healthcare-app"
  compliance_level = "hipaa"
  
  # Additional requirements:
  # - Encryption in transit/at rest
  # - Access logging
  # - PHI data tagging
  # - Audit trail retention
}
```

## Real-World Examples

### Multi-Tier Application

```hcl
# Frontend servers
module "frontend_role" {
  source = "./modules/iam-security"

  role_name = "frontend-servers"
  
  permissions = [
    "s3:GetObject",  # Static assets
    "cloudfront:CreateInvalidation"  # Cache invalidation
  ]
  
  resource_arns = ["arn:aws:s3:::frontend-assets/*"]
}

# Backend API servers
module "backend_role" {
  source = "./modules/iam-security"

  role_name = "backend-api"
  
  permissions = [
    "dynamodb:PutItem",
    "dynamodb:GetItem",
    "dynamodb:Query",
    "sqs:SendMessage",
    "secretsmanager:GetSecretValue"
  ]
  
  resource_arns = [
    "arn:aws:dynamodb:*:*:table/AppData",
    "arn:aws:sqs:*:*:app-queue",
    "arn:aws:secretsmanager:*:*:secret:api-keys/*"
  ]
}

# Worker/Background jobs
module "worker_role" {
  source = "./modules/iam-security"

  role_name = "background-workers"
  
  permissions = [
    "sqs:ReceiveMessage",
    "sqs:DeleteMessage",
    "s3:PutObject",
    "ses:SendEmail"
  ]
  
  max_session_duration = 7200  # 2 hours for long-running jobs
}
```

## Monitoring & Auditing

### CloudWatch Alarms for IAM Changes

```hcl
resource "aws_cloudwatch_log_metric_filter" "iam_policy_changes" {
  name           = "IAMPolicyChanges"
  log_group_name = "/aws/cloudtrail"
  
  pattern = "{ $.eventName = PutUserPolicy || $.eventName = PutRolePolicy || $.eventName = PutGroupPolicy }"

  metric_transformation {
    name      = "IAMPolicyChangeCount"
    namespace = "Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "iam_changes" {
  alarm_name          = "iam-policy-changes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "IAMPolicyChangeCount"
  namespace           = "Security"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Alert when IAM policies are modified"
}
```

## Troubleshooting

### Access Denied Errors

```bash
# Check current permissions
aws iam get-role --role-name my-role
aws iam list-attached-role-policies --role-name my-role
aws iam get-policy-version --policy-arn arn:aws:iam::xxx:policy/my-policy --version-id v1

# Simulate policy
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::xxx:role/my-role \
  --action-names s3:GetObject \
  --resource-arns arn:aws:s3:::my-bucket/*
```

### MFA Issues

```bash
# Get MFA devices
aws iam list-mfa-devices --user-name myuser

# Generate session with MFA
aws sts get-session-token \
  --serial-number arn:aws:iam::xxx:mfa/user \
  --token-code 123456
```

## Security Checklist

- [ ] All roles use least-privilege permissions
- [ ] MFA enabled for privileged access
- [ ] Session durations limited appropriately
- [ ] Permission boundaries applied where needed
- [ ] IAM Access Analyzer enabled
- [ ] CloudTrail logging IAM events
- [ ] Regular access reviews scheduled
- [ ] Unused roles and policies removed
- [ ] Service-specific roles created
- [ ] No wildcard (*) permissions in production

## Related Documentation

- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Least Privilege Guide](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege)
- [IAM Access Analyzer](https://docs.aws.amazon.com/IAM/latest/UserGuide/what-is-access-analyzer.html)
