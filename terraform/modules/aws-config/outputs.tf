# ==============================================================================
# AWS Config Module Outputs
# ==============================================================================

# ==============================================================================
# S3 Bucket Outputs
# ==============================================================================

output "config_bucket_name" {
  description = "Name of the AWS Config S3 bucket"
  value       = aws_s3_bucket.config.id
}

output "config_bucket_arn" {
  description = "ARN of the AWS Config S3 bucket"
  value       = aws_s3_bucket.config.arn
}

# ==============================================================================
# IAM Role Outputs
# ==============================================================================

output "config_role_arn" {
  description = "ARN of the AWS Config IAM role"
  value       = aws_iam_role.config.arn
}

output "config_role_name" {
  description = "Name of the AWS Config IAM role"
  value       = aws_iam_role.config.name
}

# ==============================================================================
# SNS Topic Outputs
# ==============================================================================

output "config_sns_topic_arn" {
  description = "ARN of the AWS Config SNS topic"
  value       = var.config_sns_topic_arn != "" ? var.config_sns_topic_arn : (length(aws_sns_topic.config) > 0 ? aws_sns_topic.config[0].arn : null)
}

# ==============================================================================
# Config Recorder Outputs
# ==============================================================================

output "config_recorder_name" {
  description = "Name of the AWS Config recorder"
  value       = aws_config_configuration_recorder.main.name
}

output "config_recorder_id" {
  description = "ID of the AWS Config recorder"
  value       = aws_config_configuration_recorder.main.id
}

output "config_delivery_channel_id" {
  description = "ID of the AWS Config delivery channel"
  value       = aws_config_delivery_channel.main.id
}

# ==============================================================================
# Config Rules Outputs
# ==============================================================================

output "encryption_rule_ids" {
  description = "IDs of encryption compliance rules"
  value = {
    encrypted_volumes = var.enable_encryption_rules ? aws_config_config_rule.encrypted_volumes[0].id : null
    rds_encryption    = var.enable_encryption_rules ? aws_config_config_rule.rds_encryption_enabled[0].id : null
    s3_encryption     = var.enable_encryption_rules ? aws_config_config_rule.s3_bucket_encryption[0].id : null
  }
}

output "access_control_rule_ids" {
  description = "IDs of access control compliance rules"
  value = {
    root_mfa          = var.enable_access_control_rules ? aws_config_config_rule.root_account_mfa[0].id : null
    iam_user_mfa      = var.enable_access_control_rules ? aws_config_config_rule.iam_user_mfa[0].id : null
    iam_password      = var.enable_access_control_rules ? aws_config_config_rule.iam_password_policy[0].id : null
    s3_public_read    = var.enable_access_control_rules ? aws_config_config_rule.s3_bucket_public_read[0].id : null
    s3_public_write   = var.enable_access_control_rules ? aws_config_config_rule.s3_bucket_public_write[0].id : null
  }
}

output "network_rule_ids" {
  description = "IDs of network security compliance rules"
  value = {
    vpc_default_sg   = var.enable_network_rules ? aws_config_config_rule.vpc_default_security_group[0].id : null
    restricted_ssh   = var.enable_network_rules ? aws_config_config_rule.restricted_ssh[0].id : null
    restricted_ports = var.enable_network_rules ? aws_config_config_rule.restricted_common_ports[0].id : null
  }
}

output "logging_rule_ids" {
  description = "IDs of logging compliance rules"
  value = {
    cloudtrail_enabled = var.enable_logging_rules ? aws_config_config_rule.cloudtrail_enabled[0].id : null
    cloudwatch_alarm   = var.enable_logging_rules ? aws_config_config_rule.cloudwatch_alarm_action[0].id : null
  }
}

# ==============================================================================
# Conformance Pack Outputs
# ==============================================================================

output "cis_conformance_pack_arn" {
  description = "ARN of the CIS AWS Foundations conformance pack"
  value       = var.enable_cis_conformance_pack ? aws_config_conformance_pack.cis_aws_foundations[0].arn : null
}

output "operational_conformance_pack_arn" {
  description = "ARN of the Operational Best Practices conformance pack"
  value       = var.enable_operational_conformance_pack ? aws_config_conformance_pack.operational_best_practices[0].arn : null
}

# ==============================================================================
# Config Aggregator Outputs
# ==============================================================================

output "config_aggregator_arn" {
  description = "ARN of the AWS Config aggregator"
  value = var.enable_config_aggregator ? (
    var.aggregator_type == "organization" ?
    aws_config_configuration_aggregator.organization[0].arn :
    aws_config_configuration_aggregator.account[0].arn
  ) : null
}

# ==============================================================================
# Alarm Outputs
# ==============================================================================

output "compliance_alarm_arn" {
  description = "ARN of the compliance violation alarm"
  value       = var.enable_compliance_alarms ? aws_cloudwatch_metric_alarm.config_compliance[0].arn : null
}

# ==============================================================================
# Console URLs
# ==============================================================================

output "console_urls" {
  description = "AWS Console URLs for Config resources"
  value = {
    config_dashboard = "https://console.aws.amazon.com/config/home?region=${data.aws_region.current.name}#/dashboard"
    config_rules     = "https://console.aws.amazon.com/config/home?region=${data.aws_region.current.name}#/rules"
    config_resources = "https://console.aws.amazon.com/config/home?region=${data.aws_region.current.name}#/resources"
    conformance_packs = "https://console.aws.amazon.com/config/home?region=${data.aws_region.current.name}#/conformance-packs"
    aggregator       = var.enable_config_aggregator ? "https://console.aws.amazon.com/config/home?region=${data.aws_region.current.name}#/aggregators" : null
  }
}

# ==============================================================================
# Configuration Summary
# ==============================================================================

output "config_summary" {
  description = "Summary of AWS Config configuration"
  value = {
    project_name = var.project_name
    environment  = var.environment
    recorder = {
      enabled                = var.enable_config_recorder
      recording_frequency    = var.recording_frequency
      record_all_resources   = var.record_all_resources
      include_global         = var.include_global_resources
    }
    storage = {
      bucket_name       = aws_s3_bucket.config.id
      retention_days    = var.config_retention_days
      encryption_enabled = var.enable_config_encryption
    }
    rules = {
      encryption_rules      = var.enable_encryption_rules
      access_control_rules  = var.enable_access_control_rules
      network_rules         = var.enable_network_rules
      logging_rules         = var.enable_logging_rules
    }
    conformance_packs = {
      cis_enabled         = var.enable_cis_conformance_pack
      operational_enabled = var.enable_operational_conformance_pack
    }
    aggregator = {
      enabled = var.enable_config_aggregator
      type    = var.aggregator_type
    }
    alarms = {
      compliance_alarms_enabled = var.enable_compliance_alarms
      threshold                 = var.compliance_alarm_threshold
    }
  }
}

# ==============================================================================
# Compliance Status Query
# ==============================================================================

output "compliance_query_example" {
  description = "Example query to check compliance status"
  value = <<-EOT
    # Query all non-compliant resources
    aws configservice describe-compliance-by-config-rule \
      --region ${data.aws_region.current.name} \
      --compliance-types NON_COMPLIANT

    # Query specific rule compliance
    aws configservice get-compliance-details-by-config-rule \
      --config-rule-name ${var.project_name}-${var.environment}-encrypted-volumes \
      --region ${data.aws_region.current.name}
  EOT
}
