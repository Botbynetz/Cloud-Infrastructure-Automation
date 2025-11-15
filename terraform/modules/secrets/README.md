# Secrets Manager Module

Terraform module for managing secrets in AWS Secrets Manager with automatic rotation and comprehensive access control.

## Overview

This module provides:
- Secret creation and management
- Automatic secret rotation (optional)
- KMS encryption for secrets
- IAM policies for secret access
- Secret versioning and recovery
- CloudWatch monitoring integration

## Usage

```hcl
module "secrets" {
  source = "./modules/secrets"

  secrets = {
    database = {
      description     = "Database credentials"
      secret_string   = jsonencode({
        username = "admin"
        password = "ChangeMe123!"
        host     = "db.example.com"
        port     = 5432
      })
      rotation_enabled = true
      rotation_days    = 30
    }
    
    api_key = {
      description   = "External API key"
      secret_string = "api-key-value-here"
      rotation_enabled = false
    }
  }

  kms_key_id = aws_kms_key.secrets.id
  
  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Features

✅ Multi-secret management in single module  
✅ Automatic rotation with Lambda integration  
✅ KMS encryption at rest  
✅ Version tracking and recovery  
✅ IAM policy generation  
✅ CloudWatch Events integration

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

### Database Credentials

```hcl
module "db_secrets" {
  source = "./modules/secrets"

  secrets = {
    postgres_main = {
      description = "Main PostgreSQL database credentials"
      secret_string = jsonencode({
        username = "dbadmin"
        password = var.db_password
        host     = aws_db_instance.main.endpoint
        port     = 5432
        dbname   = "production"
      })
      rotation_enabled = true
      rotation_days    = 30
      recovery_window  = 7
    }
  }

  kms_key_id = aws_kms_key.db_encryption.id
}
```

### API Keys and Tokens

```hcl
module "api_secrets" {
  source = "./modules/secrets"

  secrets = {
    github_token = {
      description      = "GitHub API token for CI/CD"
      secret_string    = var.github_token
      rotation_enabled = false
      recovery_window  = 30
    }
    
    slack_webhook = {
      description      = "Slack webhook URL for notifications"
      secret_string    = var.slack_webhook
      rotation_enabled = false
    }
  }
}
```

### SSH Keys

```hcl
module "ssh_secrets" {
  source = "./modules/secrets"

  secrets = {
    bastion_key = {
      description      = "SSH private key for bastion host"
      secret_string    = file("~/.ssh/bastion_rsa")
      rotation_enabled = true
      rotation_days    = 90
      recovery_window  = 14
    }
  }

  kms_key_id = aws_kms_key.ssh_keys.id
  
  tags = {
    Purpose = "SSH Authentication"
    CriticalityLevel = "High"
  }
}
```

## Security Best Practices

### Encryption
- Always use KMS encryption for sensitive secrets
- Use separate KMS keys for different secret types
- Enable automatic key rotation for KMS keys
- Restrict KMS key access with IAM policies

### Access Control
- Apply least-privilege IAM policies
- Use IAM roles instead of access keys
- Enable CloudTrail logging for secret access
- Implement resource-based policies when needed

### Rotation
- Enable automatic rotation for database credentials
- Set appropriate rotation periods (30-90 days)
- Test rotation Lambda functions regularly
- Monitor rotation failures with CloudWatch

### Recovery
- Set appropriate recovery windows (7-30 days)
- Document recovery procedures
- Test secret recovery in non-production
- Maintain backup of critical secrets

## Rotation Setup

To enable automatic rotation, you need a Lambda function:

```hcl
module "rotation_lambda" {
  source = "./modules/lambda-rotation"

  secret_arn    = module.secrets.secret_arns["database"]
  database_type = "postgres"
  vpc_id        = module.vpc.vpc_id
  subnet_ids    = module.vpc.private_subnet_ids
}
```

## IAM Policies

### Read-Only Access

```hcl
data "aws_iam_policy_document" "secret_read" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [module.secrets.secret_arns["api_key"]]
  }
  
  statement {
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.secrets.arn]
  }
}
```

### Full Access for Administrators

```hcl
data "aws_iam_policy_document" "secret_admin" {
  statement {
    actions = [
      "secretsmanager:*"
    ]
    resources = ["*"]
    
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["ap-southeast-1"]
    }
  }
}
```

## Monitoring

### CloudWatch Alarms

Monitor secret rotation failures:

```hcl
resource "aws_cloudwatch_metric_alarm" "rotation_failed" {
  alarm_name          = "secret-rotation-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "SecretRotationFailed"
  namespace           = "AWS/SecretsManager"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Alert when secret rotation fails"
  
  dimensions = {
    SecretId = module.secrets.secret_ids["database"]
  }
}
```

## Troubleshooting

### Cannot Access Secret

**Problem**: `AccessDeniedException` when reading secret

**Solution**:
1. Verify IAM permissions include `secretsmanager:GetSecretValue`
2. Check KMS key policy allows `kms:Decrypt`
3. Ensure secret exists and is not scheduled for deletion
4. Verify correct secret ARN or name is used

### Rotation Failed

**Problem**: Automatic rotation fails

**Solution**:
1. Check Lambda function logs in CloudWatch
2. Verify Lambda has network access to database
3. Ensure Lambda IAM role has required permissions
4. Test database connectivity from Lambda VPC

### Secret Not Found

**Problem**: Secret returns "ResourceNotFoundException"

**Solution**:
1. Check secret name spelling
2. Verify secret is in correct AWS region
3. Check if secret is scheduled for deletion
4. Restore from recovery window if applicable

## Compliance

This module supports:
- **PCI-DSS** - Encryption, access logging, rotation
- **HIPAA** - Encrypted storage, audit trails
- **SOC 2** - Access controls, monitoring
- **ISO 27001** - Key management, documentation

## Cost Optimization

- Secrets Manager: $0.40/secret/month
- API calls: $0.05 per 10,000 calls
- Use tags to track secret costs
- Delete unused secrets after recovery window
- Consider Parameter Store for non-sensitive config

## Related Resources

- [AWS Secrets Manager Documentation](https://docs.aws.amazon.com/secretsmanager/)
- [Rotation Lambda Functions](https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets.html)
- [Best Practices Guide](https://docs.aws.amazon.com/secretsmanager/latest/userguide/best-practices.html)
