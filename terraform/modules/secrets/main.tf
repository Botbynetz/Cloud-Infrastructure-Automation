resource "aws_secretsmanager_secret" "this" {
  for_each = var.secrets

  name        = each.key
  description = each.value.description
  kms_key_id  = var.kms_key_id

  recovery_window_in_days = each.value.recovery_window

  dynamic "replica" {
    for_each = var.enable_replication ? [1] : []
    content {
      region     = var.replica_region
      kms_key_id = var.kms_key_id
    }
  }

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name      = each.key
      ManagedBy = "terraform"
    }
  )
}

resource "aws_secretsmanager_secret_version" "this" {
  for_each = var.secrets

  secret_id     = aws_secretsmanager_secret.this[each.key].id
  secret_string = each.value.secret_string
}

resource "aws_secretsmanager_secret_rotation" "this" {
  for_each = { for k, v in var.secrets : k => v if v.rotation_enabled }

  secret_id           = aws_secretsmanager_secret.this[each.key].id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = each.value.rotation_days
  }

  depends_on = [aws_secretsmanager_secret_version.this]
}

# KMS Key for encrypting secrets
resource "aws_kms_key" "secrets" {
  count = var.kms_key_id == null ? 1 : 0

  description             = "KMS key for encrypting secrets in Secrets Manager"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name      = "secrets-manager-key"
      ManagedBy = "terraform"
    }
  )
}

resource "aws_kms_alias" "secrets" {
  count = var.kms_key_id == null ? 1 : 0

  name          = "alias/secrets-manager"
  target_key_id = aws_kms_key.secrets[0].key_id
}

# IAM Policy for reading secrets
data "aws_iam_policy_document" "secret_read" {
  statement {
    sid    = "AllowSecretsManagerRead"
    effect = "Allow"
    
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    
    resources = [for secret in aws_secretsmanager_secret.this : secret.arn]
  }

  statement {
    sid    = "AllowKMSDecrypt"
    effect = "Allow"
    
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    
    resources = var.kms_key_id != null ? [var.kms_key_id] : (
      length(aws_kms_key.secrets) > 0 ? [aws_kms_key.secrets[0].arn] : []
    )
  }
}

resource "aws_iam_policy" "secret_read" {
  name        = "secrets-manager-read-policy"
  description = "Policy to allow reading secrets from Secrets Manager"
  policy      = data.aws_iam_policy_document.secret_read.json

  tags = var.tags
}

# CloudWatch Log Group for monitoring
resource "aws_cloudwatch_log_group" "secrets" {
  name              = "/aws/secretsmanager/audit"
  retention_in_days = 30

  tags = merge(
    var.tags,
    {
      Name      = "secrets-manager-audit-logs"
      ManagedBy = "terraform"
    }
  )
}

# CloudWatch Alarm for rotation failures
resource "aws_cloudwatch_metric_alarm" "rotation_failed" {
  for_each = { for k, v in var.secrets : k => v if v.rotation_enabled }

  alarm_name          = "secret-rotation-failed-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "RotationFailed"
  namespace           = "AWS/SecretsManager"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Alert when secret rotation fails for ${each.key}"
  treat_missing_data  = "notBreaching"

  dimensions = {
    SecretId = aws_secretsmanager_secret.this[each.key].id
  }

  tags = var.tags
}
