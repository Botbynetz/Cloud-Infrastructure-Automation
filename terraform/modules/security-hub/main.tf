# ============================================================================
# Security Hub Module - Centralized Security Dashboard
# ============================================================================
# This module creates and configures AWS Security Hub with multiple security
# standards, product integrations, custom insights, action targets, and 
# automated finding routing via EventBridge.
#
# Features:
# - 5 Security Standards (CIS 1.2.0, CIS 1.4.0, PCI-DSS, AWS Foundational, NIST 800-53)
# - 8 Product Integrations (GuardDuty, Config, Inspector, Macie, etc.)
# - 5 Custom Insights for security analysis
# - 3 Action Targets for custom workflows
# - EventBridge integration for automated response
# - CloudWatch alarms for critical findings
# - Finding aggregator for multi-region monitoring
# - Member account management
# ============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# ============================================================================
# Local Variables
# ============================================================================

locals {
  # Common tags
  common_tags = merge(
    var.tags,
    {
      Module      = "security-hub"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  )

  # Standards ARN mapping
  standards_arns = {
    cis_1_2_0         = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
    cis_1_4_0         = "arn:aws:securityhub:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:standards/cis-aws-foundations-benchmark/v/1.4.0"
    pci_dss           = "arn:aws:securityhub:${data.aws_region.current.name}::standards/pci-dss/v/3.2.1"
    aws_foundational  = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
    nist_800_53       = "arn:aws:securityhub:${data.aws_region.current.name}::standards/nist-800-53/v/5.0.0"
  }

  # Product ARN mapping
  product_arns = {
    guardduty         = "arn:aws:securityhub:${data.aws_region.current.name}::product/aws/guardduty"
    config            = "arn:aws:securityhub:${data.aws_region.current.name}::product/aws/config"
    inspector         = "arn:aws:securityhub:${data.aws_region.current.name}::product/aws/inspector"
    macie             = "arn:aws:securityhub:${data.aws_region.current.name}::product/aws/macie"
    access_analyzer   = "arn:aws:securityhub:${data.aws_region.current.name}::product/aws/access-analyzer"
    firewall_manager  = "arn:aws:securityhub:${data.aws_region.current.name}::product/aws/firewall-manager"
    health            = "arn:aws:securityhub:${data.aws_region.current.name}::product/aws/health"
    systems_manager   = "arn:aws:securityhub:${data.aws_region.current.name}::product/aws/systems-manager"
  }
}

# ============================================================================
# Data Sources
# ============================================================================

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ============================================================================
# Security Hub Account
# ============================================================================

resource "aws_securityhub_account" "main" {
  count = var.enable_security_hub ? 1 : 0

  enable_default_standards    = var.enable_default_standards
  control_finding_generator   = var.control_finding_generator

  tags = local.common_tags
}

# ============================================================================
# Security Standards Subscriptions
# ============================================================================

resource "aws_securityhub_standards_subscription" "standards" {
  for_each = var.enable_security_hub ? toset(var.enabled_standards) : []

  depends_on    = [aws_securityhub_account.main]
  standards_arn = local.standards_arns[each.value]
}

# ============================================================================
# Product Integrations
# ============================================================================

resource "aws_securityhub_product_subscription" "products" {
  for_each = var.enable_security_hub ? toset(var.enabled_products) : []

  depends_on  = [aws_securityhub_account.main]
  product_arn = local.product_arns[each.value]
}

# ============================================================================
# Custom Insights
# ============================================================================

# Insight 1: Critical and High Severity Findings
resource "aws_securityhub_insight" "critical_high_findings" {
  count = var.enable_security_hub && var.enable_custom_insights ? 1 : 0

  depends_on = [aws_securityhub_account.main]

  filters {
    severity_label {
      comparison = "EQUALS"
      value      = "CRITICAL"
    }
    severity_label {
      comparison = "EQUALS"
      value      = "HIGH"
    }
    workflow_status {
      comparison = "EQUALS"
      value      = "NEW"
    }
    workflow_status {
      comparison = "EQUALS"
      value      = "NOTIFIED"
    }
    record_state {
      comparison = "EQUALS"
      value      = "ACTIVE"
    }
  }

  group_by_attribute = "ResourceType"

  name = "${var.project_name}-critical-high-findings"
}

# Insight 2: Failed Security Controls
resource "aws_securityhub_insight" "failed_controls" {
  count = var.enable_security_hub && var.enable_custom_insights ? 1 : 0

  depends_on = [aws_securityhub_account.main]

  filters {
    compliance_status {
      comparison = "EQUALS"
      value      = "FAILED"
    }
    record_state {
      comparison = "EQUALS"
      value      = "ACTIVE"
    }
  }

  group_by_attribute = "ComplianceStatus"

  name = "${var.project_name}-failed-controls"
}

# Insight 3: Public Resources
resource "aws_securityhub_insight" "public_resources" {
  count = var.enable_security_hub && var.enable_custom_insights ? 1 : 0

  depends_on = [aws_securityhub_account.main]

  filters {
    resource_details_other {
      comparison = "EQUALS"
      key        = "PubliclyAccessible"
      value      = "true"
    }
    severity_label {
      comparison = "EQUALS"
      value      = "CRITICAL"
    }
    severity_label {
      comparison = "EQUALS"
      value      = "HIGH"
    }
    severity_label {
      comparison = "EQUALS"
      value      = "MEDIUM"
    }
    record_state {
      comparison = "EQUALS"
      value      = "ACTIVE"
    }
  }

  group_by_attribute = "ResourceType"

  name = "${var.project_name}-public-resources"
}

# Insight 4: IAM Findings
resource "aws_securityhub_insight" "iam_findings" {
  count = var.enable_security_hub && var.enable_custom_insights ? 1 : 0

  depends_on = [aws_securityhub_account.main]

  filters {
    resource_type {
      comparison = "EQUALS"
      value      = "AwsIamUser"
    }
    resource_type {
      comparison = "EQUALS"
      value      = "AwsIamRole"
    }
    resource_type {
      comparison = "EQUALS"
      value      = "AwsIamPolicy"
    }
    compliance_status {
      comparison = "EQUALS"
      value      = "FAILED"
    }
    record_state {
      comparison = "EQUALS"
      value      = "ACTIVE"
    }
  }

  group_by_attribute = "ResourceId"

  name = "${var.project_name}-iam-findings"
}

# Insight 5: Unpatched Resources
resource "aws_securityhub_insight" "unpatched_resources" {
  count = var.enable_security_hub && var.enable_custom_insights ? 1 : 0

  depends_on = [aws_securityhub_account.main]

  filters {
    type {
      comparison = "PREFIX"
      value      = "Software and Configuration Checks"
    }
    compliance_status {
      comparison = "EQUALS"
      value      = "FAILED"
    }
    record_state {
      comparison = "EQUALS"
      value      = "ACTIVE"
    }
  }

  group_by_attribute = "ResourceType"

  name = "${var.project_name}-unpatched-resources"
}

# ============================================================================
# Action Targets (Custom Actions)
# ============================================================================

# Action 1: Auto-Remediate Finding
resource "aws_securityhub_action_target" "auto_remediate" {
  count = var.enable_security_hub && var.enable_action_targets ? 1 : 0

  depends_on  = [aws_securityhub_account.main]
  name        = "AutoRemediate"
  identifier  = "AutoRemediate"
  description = "Trigger automatic remediation workflow for this finding"
}

# Action 2: Create Ticket
resource "aws_securityhub_action_target" "create_ticket" {
  count = var.enable_security_hub && var.enable_action_targets ? 1 : 0

  depends_on  = [aws_securityhub_account.main]
  name        = "CreateTicket"
  identifier  = "CreateTicket"
  description = "Create a support ticket for this security finding"
}

# Action 3: Suppress Finding
resource "aws_securityhub_action_target" "suppress_finding" {
  count = var.enable_security_hub && var.enable_action_targets ? 1 : 0

  depends_on  = [aws_securityhub_account.main]
  name        = "SuppressFinding"
  identifier  = "SuppressFinding"
  description = "Mark this finding as false positive or accepted risk"
}

# ============================================================================
# EventBridge Rules for Finding Routing
# ============================================================================

# Rule 1: Critical Findings
resource "aws_cloudwatch_event_rule" "critical_findings" {
  count = var.enable_security_hub && var.enable_eventbridge ? 1 : 0

  name        = "${var.project_name}-security-hub-critical-findings"
  description = "Route Security Hub critical findings to SNS"

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Severity = {
          Label = ["CRITICAL"]
        }
        Workflow = {
          Status = ["NEW", "NOTIFIED"]
        }
        RecordState = ["ACTIVE"]
      }
    }
  })

  tags = local.common_tags
}

# Rule 2: High Severity Findings
resource "aws_cloudwatch_event_rule" "high_findings" {
  count = var.enable_security_hub && var.enable_eventbridge ? 1 : 0

  name        = "${var.project_name}-security-hub-high-findings"
  description = "Route Security Hub high severity findings to SNS"

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Severity = {
          Label = ["HIGH"]
        }
        Workflow = {
          Status = ["NEW", "NOTIFIED"]
        }
        RecordState = ["ACTIVE"]
      }
    }
  })

  tags = local.common_tags
}

# Rule 3: Failed Compliance Checks
resource "aws_cloudwatch_event_rule" "failed_compliance" {
  count = var.enable_security_hub && var.enable_eventbridge ? 1 : 0

  name        = "${var.project_name}-security-hub-failed-compliance"
  description = "Route Security Hub failed compliance checks to SNS"

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Compliance = {
          Status = ["FAILED"]
        }
        Workflow = {
          Status = ["NEW", "NOTIFIED"]
        }
        RecordState = ["ACTIVE"]
      }
    }
  })

  tags = local.common_tags
}

# Rule 4: Custom Action Trigger
resource "aws_cloudwatch_event_rule" "custom_action" {
  count = var.enable_security_hub && var.enable_eventbridge && var.enable_action_targets ? 1 : 0

  name        = "${var.project_name}-security-hub-custom-action"
  description = "Handle Security Hub custom action invocations"

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Custom Action"]
  })

  tags = local.common_tags
}

# ============================================================================
# SNS Topics for Alerts
# ============================================================================

# SNS Topic: Critical Findings
resource "aws_sns_topic" "critical_findings" {
  count = var.enable_security_hub && var.enable_sns ? 1 : 0

  name              = "${var.project_name}-security-hub-critical-findings"
  display_name      = "Security Hub Critical Findings"
  kms_master_key_id = var.sns_kms_key_id

  tags = local.common_tags
}

resource "aws_sns_topic_policy" "critical_findings" {
  count = var.enable_security_hub && var.enable_sns ? 1 : 0

  arn = aws_sns_topic.critical_findings[0].arn

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
        Resource = aws_sns_topic.critical_findings[0].arn
      }
    ]
  })
}

# SNS Topic: High Severity Findings
resource "aws_sns_topic" "high_findings" {
  count = var.enable_security_hub && var.enable_sns ? 1 : 0

  name              = "${var.project_name}-security-hub-high-findings"
  display_name      = "Security Hub High Severity Findings"
  kms_master_key_id = var.sns_kms_key_id

  tags = local.common_tags
}

resource "aws_sns_topic_policy" "high_findings" {
  count = var.enable_security_hub && var.enable_sns ? 1 : 0

  arn = aws_sns_topic.high_findings[0].arn

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
        Resource = aws_sns_topic.high_findings[0].arn
      }
    ]
  })
}

# SNS Topic: Compliance Findings
resource "aws_sns_topic" "compliance_findings" {
  count = var.enable_security_hub && var.enable_sns ? 1 : 0

  name              = "${var.project_name}-security-hub-compliance-findings"
  display_name      = "Security Hub Compliance Findings"
  kms_master_key_id = var.sns_kms_key_id

  tags = local.common_tags
}

resource "aws_sns_topic_policy" "compliance_findings" {
  count = var.enable_security_hub && var.enable_sns ? 1 : 0

  arn = aws_sns_topic.compliance_findings[0].arn

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
        Resource = aws_sns_topic.compliance_findings[0].arn
      }
    ]
  })
}

# ============================================================================
# EventBridge Targets
# ============================================================================

resource "aws_cloudwatch_event_target" "critical_findings_sns" {
  count = var.enable_security_hub && var.enable_eventbridge && var.enable_sns ? 1 : 0

  rule      = aws_cloudwatch_event_rule.critical_findings[0].name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.critical_findings[0].arn
}

resource "aws_cloudwatch_event_target" "high_findings_sns" {
  count = var.enable_security_hub && var.enable_eventbridge && var.enable_sns ? 1 : 0

  rule      = aws_cloudwatch_event_rule.high_findings[0].name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.high_findings[0].arn
}

resource "aws_cloudwatch_event_target" "compliance_findings_sns" {
  count = var.enable_security_hub && var.enable_eventbridge && var.enable_sns ? 1 : 0

  rule      = aws_cloudwatch_event_rule.failed_compliance[0].name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.compliance_findings[0].arn
}

# ============================================================================
# CloudWatch Alarms
# ============================================================================

# Alarm 1: Critical Findings Count
resource "aws_cloudwatch_metric_alarm" "critical_findings" {
  count = var.enable_security_hub && var.enable_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-security-hub-critical-findings"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CriticalFindings"
  namespace           = "SecurityHub"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.alarm_critical_findings_threshold
  alarm_description   = "Alert when Security Hub has critical findings"
  alarm_actions       = var.alarm_sns_topic_arns
  treat_missing_data  = "notBreaching"

  tags = local.common_tags
}

# Alarm 2: High Severity Findings Count
resource "aws_cloudwatch_metric_alarm" "high_findings" {
  count = var.enable_security_hub && var.enable_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-security-hub-high-findings"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HighFindings"
  namespace           = "SecurityHub"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.alarm_high_findings_threshold
  alarm_description   = "Alert when Security Hub has high severity findings"
  alarm_actions       = var.alarm_sns_topic_arns
  treat_missing_data  = "notBreaching"

  tags = local.common_tags
}

# Alarm 3: Compliance Score Drop
resource "aws_cloudwatch_metric_alarm" "compliance_score" {
  count = var.enable_security_hub && var.enable_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-security-hub-compliance-score"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ComplianceScore"
  namespace           = "SecurityHub"
  period              = "3600"
  statistic           = "Average"
  threshold           = var.alarm_compliance_score_threshold
  alarm_description   = "Alert when Security Hub compliance score drops below threshold"
  alarm_actions       = var.alarm_sns_topic_arns
  treat_missing_data  = "breaching"

  tags = local.common_tags
}

# Alarm 4: Failed Security Checks
resource "aws_cloudwatch_metric_alarm" "failed_checks" {
  count = var.enable_security_hub && var.enable_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-security-hub-failed-checks"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FailedChecks"
  namespace           = "SecurityHub"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.alarm_failed_checks_threshold
  alarm_description   = "Alert when Security Hub has failed security checks"
  alarm_actions       = var.alarm_sns_topic_arns
  treat_missing_data  = "notBreaching"

  tags = local.common_tags
}

# ============================================================================
# Finding Aggregator (Multi-Region)
# ============================================================================

resource "aws_securityhub_finding_aggregator" "main" {
  count = var.enable_security_hub && var.enable_finding_aggregator ? 1 : 0

  depends_on   = [aws_securityhub_account.main]
  linking_mode = var.finding_aggregator_linking_mode

  dynamic "linked_regions" {
    for_each = var.finding_aggregator_linking_mode == "SPECIFIED_REGIONS" ? var.finding_aggregator_regions : []
    content {
      region = linked_regions.value
    }
  }
}

# ============================================================================
# Member Account Management
# ============================================================================

resource "aws_securityhub_member" "members" {
  for_each = var.enable_security_hub && var.enable_member_accounts ? { for m in var.member_accounts : m.account_id => m } : {}

  depends_on = [aws_securityhub_account.main]
  account_id = each.value.account_id
  email      = each.value.email
  invite     = lookup(each.value, "invite", true)
}

resource "aws_securityhub_invitation_accepter" "member_acceptance" {
  for_each = var.enable_security_hub && var.enable_member_accounts ? { for m in var.member_accounts : m.account_id => m if lookup(m, "accept_invitation", false) } : {}

  depends_on    = [aws_securityhub_member.members]
  master_id     = data.aws_caller_identity.current.account_id
}
