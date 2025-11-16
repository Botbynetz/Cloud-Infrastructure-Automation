# ==============================================================================
# AWS Config Compliance Module
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
data "aws_partition" "current" {}

# ==============================================================================
# S3 Bucket for AWS Config
# ==============================================================================

resource "aws_s3_bucket" "config" {
  bucket = "${var.project_name}-${var.environment}-config-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-config"
      Environment = var.environment
      Purpose     = "AWS Config storage"
    }
  )
}

resource "aws_s3_bucket_versioning" "config" {
  bucket = aws_s3_bucket.config.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  bucket = aws_s3_bucket.config.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.enable_config_encryption ? "aws:kms" : "AES256"
      kms_master_key_id = var.enable_config_encryption ? var.kms_key_id : null
    }
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  bucket = aws_s3_bucket.config.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "config" {
  bucket = aws_s3_bucket.config.id

  rule {
    id     = "config-retention"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }

    expiration {
      days = var.config_retention_days
    }
  }
}

resource "aws_s3_bucket_policy" "config" {
  bucket = aws_s3_bucket.config.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config.arn
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AWSConfigBucketExistenceCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.config.arn
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AWSConfigBucketWrite"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# ==============================================================================
# IAM Role for AWS Config
# ==============================================================================

resource "aws_iam_role" "config" {
  name = "${var.project_name}-${var.environment}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-config-role"
      Environment = var.environment
    }
  )
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/ConfigRole"
}

resource "aws_iam_role_policy" "config" {
  name = "${var.project_name}-${var.environment}-config-policy"
  role = aws_iam_role.config.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketVersioning",
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = [
          aws_s3_bucket.config.arn,
          "${aws_s3_bucket.config.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = var.config_sns_topic_arn != "" ? var.config_sns_topic_arn : aws_sns_topic.config[0].arn
      }
    ]
  })
}

# ==============================================================================
# SNS Topic for AWS Config Notifications
# ==============================================================================

resource "aws_sns_topic" "config" {
  count = var.config_sns_topic_arn == "" ? 1 : 0

  name              = "${var.project_name}-${var.environment}-config-notifications"
  kms_master_key_id = var.enable_config_encryption ? var.kms_key_id : null

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-config-notifications"
      Environment = var.environment
    }
  )
}

# ==============================================================================
# AWS Config Recorder
# ==============================================================================

resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project_name}-${var.environment}-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = var.record_all_resources
    include_global_resource_types = var.include_global_resources
    
    dynamic "recording_strategy" {
      for_each = var.recording_frequency != "CONTINUOUS" ? [1] : []
      content {
        use_only = var.recording_frequency
      }
    }

    dynamic "exclusion_by_resource_types" {
      for_each = length(var.excluded_resource_types) > 0 ? [1] : []
      content {
        resource_types = var.excluded_resource_types
      }
    }
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "${var.project_name}-${var.environment}-delivery"
  s3_bucket_name = aws_s3_bucket.config.id
  sns_topic_arn  = var.config_sns_topic_arn != "" ? var.config_sns_topic_arn : aws_sns_topic.config[0].arn

  snapshot_delivery_properties {
    delivery_frequency = var.snapshot_delivery_frequency
  }

  depends_on = [
    aws_s3_bucket_policy.config
  ]
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = var.enable_config_recorder

  depends_on = [
    aws_config_delivery_channel.main
  ]
}

# ==============================================================================
# AWS Config Rules - Security Best Practices
# ==============================================================================

# Encryption Rules
resource "aws_config_config_rule" "encrypted_volumes" {
  count = var.enable_encryption_rules ? 1 : 0

  name = "${var.project_name}-${var.environment}-encrypted-volumes"

  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }

  depends_on = [
    aws_config_configuration_recorder.main
  ]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-encrypted-volumes"
      Environment = var.environment
      Compliance  = "Security"
    }
  )
}

resource "aws_config_config_rule" "rds_encryption_enabled" {
  count = var.enable_encryption_rules ? 1 : 0

  name = "${var.project_name}-${var.environment}-rds-encryption"

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }

  depends_on = [
    aws_config_configuration_recorder.main
  ]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-rds-encryption"
      Environment = var.environment
      Compliance  = "Security"
    }
  )
}

resource "aws_config_config_rule" "s3_bucket_encryption" {
  count = var.enable_encryption_rules ? 1 : 0

  name = "${var.project_name}-${var.environment}-s3-encryption"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }

  depends_on = [
    aws_config_configuration_recorder.main
  ]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-s3-encryption"
      Environment = var.environment
      Compliance  = "Security"
    }
  )
}

# Access Control Rules
resource "aws_config_config_rule" "root_account_mfa" {
  count = var.enable_access_control_rules ? 1 : 0

  name = "${var.project_name}-${var.environment}-root-mfa"

  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }

  depends_on = [
    aws_config_configuration_recorder.main
  ]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-root-mfa"
      Environment = var.environment
      Compliance  = "Security"
    }
  )
}

resource "aws_config_config_rule" "iam_user_mfa" {
  count = var.enable_access_control_rules ? 1 : 0

  name = "${var.project_name}-${var.environment}-iam-user-mfa"

  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_MFA_ENABLED"
  }

  depends_on = [
    aws_config_configuration_recorder.main
  ]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-iam-user-mfa"
      Environment = var.environment
      Compliance  = "Security"
    }
  )
}

resource "aws_config_config_rule" "iam_password_policy" {
  count = var.enable_access_control_rules ? 1 : 0

  name = "${var.project_name}-${var.environment}-iam-password-policy"

  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }

  input_parameters = jsonencode({
    RequireUppercaseCharacters = true
    RequireLowercaseCharacters = true
    RequireSymbols             = true
    RequireNumbers             = true
    MinimumPasswordLength      = 14
    PasswordReusePrevention    = 24
    MaxPasswordAge             = 90
  })

  depends_on = [
    aws_config_configuration_recorder.main
  ]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-iam-password-policy"
      Environment = var.environment
      Compliance  = "Security"
    }
  )
}

resource "aws_config_config_rule" "s3_bucket_public_read" {
  count = var.enable_access_control_rules ? 1 : 0

  name = "${var.project_name}-${var.environment}-s3-no-public-read"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [
    aws_config_configuration_recorder.main
  ]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-s3-no-public-read"
      Environment = var.environment
      Compliance  = "Security"
    }
  )
}

resource "aws_config_config_rule" "s3_bucket_public_write" {
  count = var.enable_access_control_rules ? 1 : 0

  name = "${var.project_name}-${var.environment}-s3-no-public-write"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
  }

  depends_on = [
    aws_config_configuration_recorder.main
  ]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-s3-no-public-write"
      Environment = var.environment
      Compliance  = "Security"
    }
  )
}

# Network Security Rules
resource "aws_config_config_rule" "vpc_default_security_group" {
  count = var.enable_network_rules ? 1 : 0

  name = "${var.project_name}-${var.environment}-vpc-default-sg"

  source {
    owner             = "AWS"
    source_identifier = "VPC_DEFAULT_SECURITY_GROUP_CLOSED"
  }

  depends_on = [
    aws_config_configuration_recorder.main
  ]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-vpc-default-sg"
      Environment = var.environment
      Compliance  = "Network"
    }
  )
}

resource "aws_config_config_rule" "restricted_ssh" {
  count = var.enable_network_rules ? 1 : 0

  name = "${var.project_name}-${var.environment}-restricted-ssh"

  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }

  depends_on = [
    aws_config_configuration_recorder.main
  ]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-restricted-ssh"
      Environment = var.environment
      Compliance  = "Network"
    }
  )
}

resource "aws_config_config_rule" "restricted_common_ports" {
  count = var.enable_network_rules ? 1 : 0

  name = "${var.project_name}-${var.environment}-restricted-ports"

  source {
    owner             = "AWS"
    source_identifier = "RESTRICTED_INCOMING_TRAFFIC"
  }

  input_parameters = jsonencode({
    blockedPort1 = 20
    blockedPort2 = 21
    blockedPort3 = 3389
    blockedPort4 = 3306
    blockedPort5 = 5432
  })

  depends_on = [
    aws_config_configuration_recorder.main
  ]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-restricted-ports"
      Environment = var.environment
      Compliance  = "Network"
    }
  )
}

# Logging Rules
resource "aws_config_config_rule" "cloudtrail_enabled" {
  count = var.enable_logging_rules ? 1 : 0

  name = "${var.project_name}-${var.environment}-cloudtrail-enabled"

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }

  depends_on = [
    aws_config_configuration_recorder.main
  ]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-cloudtrail-enabled"
      Environment = var.environment
      Compliance  = "Logging"
    }
  )
}

resource "aws_config_config_rule" "cloudwatch_alarm_action" {
  count = var.enable_logging_rules ? 1 : 0

  name = "${var.project_name}-${var.environment}-cloudwatch-alarm-action"

  source {
    owner             = "AWS"
    source_identifier = "CLOUDWATCH_ALARM_ACTION_CHECK"
  }

  input_parameters = jsonencode({
    alarmActionRequired      = "true"
    insufficientDataActionRequired = "false"
    okActionRequired         = "false"
  })

  depends_on = [
    aws_config_configuration_recorder.main
  ]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-cloudwatch-alarm-action"
      Environment = var.environment
      Compliance  = "Logging"
    }
  )
}

# ==============================================================================
# AWS Config Conformance Packs
# ==============================================================================

resource "aws_config_conformance_pack" "cis_aws_foundations" {
  count = var.enable_cis_conformance_pack ? 1 : 0

  name = "${var.project_name}-${var.environment}-cis-foundations"

  template_body = file("${path.module}/conformance-packs/cis-aws-foundations.yaml")

  depends_on = [
    aws_config_configuration_recorder.main
  ]
}

resource "aws_config_conformance_pack" "operational_best_practices" {
  count = var.enable_operational_conformance_pack ? 1 : 0

  name = "${var.project_name}-${var.environment}-operational-best-practices"

  template_body = file("${path.module}/conformance-packs/operational-best-practices.yaml")

  depends_on = [
    aws_config_configuration_recorder.main
  ]
}

# ==============================================================================
# AWS Config Aggregator (Optional for Multi-Account)
# ==============================================================================

resource "aws_config_configuration_aggregator" "organization" {
  count = var.enable_config_aggregator && var.aggregator_type == "organization" ? 1 : 0

  name = "${var.project_name}-${var.environment}-org-aggregator"

  organization_aggregation_source {
    all_regions = true
    role_arn    = var.aggregator_role_arn
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-org-aggregator"
      Environment = var.environment
    }
  )
}

resource "aws_config_configuration_aggregator" "account" {
  count = var.enable_config_aggregator && var.aggregator_type == "account" ? 1 : 0

  name = "${var.project_name}-${var.environment}-account-aggregator"

  account_aggregation_source {
    account_ids = var.aggregator_account_ids
    all_regions = true
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-account-aggregator"
      Environment = var.environment
    }
  )
}

# ==============================================================================
# CloudWatch Alarms for Compliance
# ==============================================================================

resource "aws_cloudwatch_metric_alarm" "config_compliance" {
  count = var.enable_compliance_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-config-non-compliant"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "NonCompliantRules"
  namespace           = "AWS/Config"
  period              = 300
  statistic           = "Maximum"
  threshold           = var.compliance_alarm_threshold
  alarm_description   = "Alert when non-compliant resources exceed threshold"
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-config-compliance-alarm"
      Environment = var.environment
      Severity    = "warning"
    }
  )
}
