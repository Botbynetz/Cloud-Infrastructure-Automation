# ==============================================================================
# AWS GuardDuty Threat Detection Module
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
# GuardDuty Detector
# ==============================================================================

resource "aws_guardduty_detector" "main" {
  enable = var.enable_guardduty

  finding_publishing_frequency = var.finding_publishing_frequency

  datasources {
    s3_logs {
      enable = var.enable_s3_logs_protection
    }

    kubernetes {
      audit_logs {
        enable = var.enable_kubernetes_audit_logs
      }
    }

    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = var.enable_malware_protection
        }
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-guardduty"
      Environment = var.environment
    }
  )
}

# ==============================================================================
# S3 Bucket for GuardDuty Findings
# ==============================================================================

resource "aws_s3_bucket" "guardduty_findings" {
  count = var.enable_findings_export ? 1 : 0

  bucket = "${var.project_name}-${var.environment}-guardduty-findings-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-guardduty-findings"
      Environment = var.environment
      Purpose     = "GuardDuty findings export"
    }
  )
}

resource "aws_s3_bucket_versioning" "guardduty_findings" {
  count = var.enable_findings_export ? 1 : 0

  bucket = aws_s3_bucket.guardduty_findings[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "guardduty_findings" {
  count = var.enable_findings_export ? 1 : 0

  bucket = aws_s3_bucket.guardduty_findings[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.enable_findings_encryption ? "aws:kms" : "AES256"
      kms_master_key_id = var.enable_findings_encryption ? var.kms_key_id : null
    }
  }
}

resource "aws_s3_bucket_public_access_block" "guardduty_findings" {
  count = var.enable_findings_export ? 1 : 0

  bucket = aws_s3_bucket.guardduty_findings[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "guardduty_findings" {
  count = var.enable_findings_export ? 1 : 0

  bucket = aws_s3_bucket.guardduty_findings[0].id

  rule {
    id     = "findings-retention"
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
      days = var.findings_retention_days
    }
  }
}

resource "aws_s3_bucket_policy" "guardduty_findings" {
  count = var.enable_findings_export ? 1 : 0

  bucket = aws_s3_bucket.guardduty_findings[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowGuardDutyGetBucketLocation"
        Effect = "Allow"
        Principal = {
          Service = "guardduty.amazonaws.com"
        }
        Action   = "s3:GetBucketLocation"
        Resource = aws_s3_bucket.guardduty_findings[0].arn
      },
      {
        Sid    = "AllowGuardDutyPutObject"
        Effect = "Allow"
        Principal = {
          Service = "guardduty.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.guardduty_findings[0].arn}/*"
      },
      {
        Sid    = "DenyUnencryptedObjectUploads"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.guardduty_findings[0].arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = var.enable_findings_encryption ? "aws:kms" : "AES256"
          }
        }
      },
      {
        Sid    = "DenyInsecureTransport"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.guardduty_findings[0].arn,
          "${aws_s3_bucket.guardduty_findings[0].arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# ==============================================================================
# GuardDuty Publishing Destination
# ==============================================================================

resource "aws_guardduty_publishing_destination" "main" {
  count = var.enable_findings_export ? 1 : 0

  detector_id     = aws_guardduty_detector.main.id
  destination_arn = aws_s3_bucket.guardduty_findings[0].arn
  kms_key_arn     = var.enable_findings_encryption ? var.kms_key_id : null

  depends_on = [
    aws_s3_bucket_policy.guardduty_findings
  ]
}

# ==============================================================================
# GuardDuty Filter - Critical Findings
# ==============================================================================

resource "aws_guardduty_filter" "critical_findings" {
  count = var.enable_critical_filter ? 1 : 0

  name        = "${var.project_name}-${var.environment}-critical-findings"
  detector_id = aws_guardduty_detector.main.id
  action      = "ARCHIVE"  # Archive low-priority findings
  rank        = 1

  finding_criteria {
    criterion {
      field  = "severity"
      less_than = "4.0"  # Archive findings with severity < 4.0 (Low)
    }
  }

  description = "Filter to focus on critical findings only"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-critical-filter"
      Environment = var.environment
    }
  )
}

# ==============================================================================
# GuardDuty IPSet - Trusted IPs (Optional)
# ==============================================================================

resource "aws_s3_bucket_object" "trusted_ips" {
  count = var.enable_trusted_ips && length(var.trusted_ip_list) > 0 ? 1 : 0

  bucket  = aws_s3_bucket.guardduty_findings[0].id
  key     = "trusted-ips.txt"
  content = join("\n", var.trusted_ip_list)

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-trusted-ips"
      Environment = var.environment
    }
  )
}

resource "aws_guardduty_ipset" "trusted" {
  count = var.enable_trusted_ips && length(var.trusted_ip_list) > 0 ? 1 : 0

  name        = "${var.project_name}-${var.environment}-trusted-ips"
  detector_id = aws_guardduty_detector.main.id
  format      = "TXT"
  location    = "https://s3.amazonaws.com/${aws_s3_bucket.guardduty_findings[0].id}/trusted-ips.txt"
  activate    = true

  depends_on = [
    aws_s3_bucket_object.trusted_ips
  ]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-trusted-ips"
      Environment = var.environment
    }
  )
}

# ==============================================================================
# GuardDuty ThreatIntelSet - Known Threats (Optional)
# ==============================================================================

resource "aws_s3_bucket_object" "threat_intel" {
  count = var.enable_threat_intel && length(var.threat_ip_list) > 0 ? 1 : 0

  bucket  = aws_s3_bucket.guardduty_findings[0].id
  key     = "threat-intel.txt"
  content = join("\n", var.threat_ip_list)

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-threat-intel"
      Environment = var.environment
    }
  )
}

resource "aws_guardduty_threatintelset" "known_threats" {
  count = var.enable_threat_intel && length(var.threat_ip_list) > 0 ? 1 : 0

  name        = "${var.project_name}-${var.environment}-threat-intel"
  detector_id = aws_guardduty_detector.main.id
  format      = "TXT"
  location    = "https://s3.amazonaws.com/${aws_s3_bucket.guardduty_findings[0].id}/threat-intel.txt"
  activate    = true

  depends_on = [
    aws_s3_bucket_object.threat_intel
  ]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-threat-intel"
      Environment = var.environment
    }
  )
}

# ==============================================================================
# SNS Topic for GuardDuty Alerts
# ==============================================================================

resource "aws_sns_topic" "guardduty_alerts" {
  count = var.guardduty_sns_topic_arn == "" ? 1 : 0

  name              = "${var.project_name}-${var.environment}-guardduty-alerts"
  kms_master_key_id = var.enable_findings_encryption ? var.kms_key_id : null

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-guardduty-alerts"
      Environment = var.environment
    }
  )
}

# ==============================================================================
# EventBridge Rule for GuardDuty Findings
# ==============================================================================

resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "${var.project_name}-${var.environment}-guardduty-findings"
  description = "Capture GuardDuty findings"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = var.alert_severity_levels
    }
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-guardduty-findings-rule"
      Environment = var.environment
    }
  )
}

resource "aws_cloudwatch_event_target" "guardduty_sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "SendToSNS"
  arn       = var.guardduty_sns_topic_arn != "" ? var.guardduty_sns_topic_arn : aws_sns_topic.guardduty_alerts[0].arn

  input_transformer {
    input_paths = {
      severity    = "$.detail.severity"
      type        = "$.detail.type"
      description = "$.detail.description"
      account     = "$.detail.accountId"
      region      = "$.detail.region"
      resource    = "$.detail.resource"
      time        = "$.time"
    }

    input_template = <<-EOT
      {
        "alert": "GuardDuty Finding Detected",
        "severity": <severity>,
        "type": "<type>",
        "description": "<description>",
        "account": "<account>",
        "region": "<region>",
        "resource": <resource>,
        "time": "<time>",
        "console_url": "https://console.aws.amazon.com/guardduty/home?region=<region>#/findings?search=id%3D<id>"
      }
    EOT
  }
}

resource "aws_sns_topic_policy" "guardduty_alerts" {
  count = var.guardduty_sns_topic_arn == "" ? 1 : 0

  arn = aws_sns_topic.guardduty_alerts[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgePublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.guardduty_alerts[0].arn
      }
    ]
  })
}

# ==============================================================================
# CloudWatch Log Group for GuardDuty
# ==============================================================================

resource "aws_cloudwatch_log_group" "guardduty" {
  name              = "/aws/guardduty/${var.project_name}-${var.environment}"
  retention_in_days = var.findings_log_retention_days
  kms_key_id        = var.enable_findings_encryption ? var.kms_key_id : null

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-guardduty-logs"
      Environment = var.environment
    }
  )
}

# ==============================================================================
# CloudWatch Alarms for GuardDuty
# ==============================================================================

resource "aws_cloudwatch_metric_alarm" "high_severity_findings" {
  count = var.enable_guardduty_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-guardduty-high-severity"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Count"
  namespace           = "AWS/GuardDuty"
  period              = 300
  statistic           = "Sum"
  threshold           = var.high_severity_threshold
  alarm_description   = "Alert on high severity GuardDuty findings"
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    DetectorId = aws_guardduty_detector.main.id
    Severity   = "High"
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-guardduty-high-severity-alarm"
      Environment = var.environment
      Severity    = "critical"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "malware_detected" {
  count = var.enable_guardduty_alarms && var.enable_malware_protection ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-guardduty-malware"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "MalwareDetected"
  namespace           = "AWS/GuardDuty"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alert when malware is detected"
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    DetectorId = aws_guardduty_detector.main.id
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-guardduty-malware-alarm"
      Environment = var.environment
      Severity    = "critical"
    }
  )
}

# ==============================================================================
# GuardDuty Member Accounts (Optional for Multi-Account)
# ==============================================================================

resource "aws_guardduty_member" "members" {
  for_each = var.enable_member_accounts ? { for m in var.member_accounts : m.account_id => m } : {}

  account_id  = each.value.account_id
  detector_id = aws_guardduty_detector.main.id
  email       = each.value.email
  invite      = true

  lifecycle {
    ignore_changes = [
      invite
    ]
  }
}

# ==============================================================================
# GuardDuty Dashboard (CloudWatch)
# ==============================================================================

resource "aws_cloudwatch_dashboard" "guardduty" {
  count = var.enable_guardduty_dashboard ? 1 : 0

  dashboard_name = "${var.project_name}-${var.environment}-guardduty"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/GuardDuty", "Count", { stat: "Sum", label: "High Severity Findings", color: "#d13212" }],
            ["...", { stat: "Sum", label: "Medium Severity Findings", color: "#ff9900" }],
            ["...", { stat: "Sum", label: "Low Severity Findings", color: "#1f77b4" }]
          ]
          region = data.aws_region.current.name
          title  = "GuardDuty Findings by Severity"
          period = 300
          yAxis = {
            left = {
              label = "Count"
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = var.enable_malware_protection ? [
            ["AWS/GuardDuty", "MalwareDetected", { stat: "Sum", color: "#d13212" }]
          ] : []
          region = data.aws_region.current.name
          title  = "Malware Detections"
          period = 300
        }
      },
      {
        type = "log"
        properties = {
          query = <<-EOQ
            SOURCE '/aws/guardduty/${var.project_name}-${var.environment}'
            | fields @timestamp, severity, type, description
            | filter severity >= 7.0
            | sort @timestamp desc
            | limit 20
          EOQ
          region = data.aws_region.current.name
          title  = "Recent High Severity Findings"
        }
      },
      {
        type = "log"
        properties = {
          query = <<-EOQ
            SOURCE '/aws/guardduty/${var.project_name}-${var.environment}'
            | stats count() by type
            | sort count desc
            | limit 10
          EOQ
          region = data.aws_region.current.name
          title  = "Top Finding Types"
        }
      }
    ]
  })
}
