# =============================================================================
# OPA Compliance Policy - STEP 3 Enhancement
# =============================================================================
# Enforces regulatory compliance: SOC2, HIPAA, PCI-DSS, GDPR
# Validates: Data protection, audit logging, access controls, encryption

package terraform.compliance

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# =============================================================================
# SOC2 COMPLIANCE POLICIES
# =============================================================================

# SOC2: Require encryption for data at rest
deny[msg] {
    resource := input.resource_changes[_]
    resource.type in ["aws_s3_bucket", "aws_db_instance", "aws_ebs_volume"]
    not is_encrypted(resource)
    
    msg := sprintf(
        "❌ SOC2: Resource '%s' must have encryption at rest (CC6.1 - Logical Access Security)",
        [resource.name]
    )
}

is_encrypted(resource) {
    resource.type == "aws_s3_bucket"
    resource.change.after.server_side_encryption_configuration
}

is_encrypted(resource) {
    resource.type == "aws_db_instance"
    resource.change.after.storage_encrypted == true
}

is_encrypted(resource) {
    resource.type == "aws_ebs_volume"
    resource.change.after.encrypted == true
}

# SOC2: Require audit logging (CloudTrail)
warn[msg] {
    cloudtrail_count := count([r | r := input.resource_changes[_]; r.type == "aws_cloudtrail"])
    cloudtrail_count == 0
    
    msg := "⚠️  SOC2: CloudTrail should be enabled for audit logging (CC7.2 - System Monitoring)"
}

# SOC2: Require access logging for sensitive resources
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    has_sensitive_data(resource)
    not has_logging_enabled(resource)
    
    msg := sprintf(
        "❌ SOC2: S3 bucket '%s' with sensitive data must have access logging (CC7.2)",
        [resource.name]
    )
}

has_sensitive_data(resource) {
    tags := resource.change.after.tags
    tags["DataClassification"] in ["Confidential", "Sensitive", "PII"]
}

has_logging_enabled(resource) {
    resource.change.after.logging
}

# SOC2: Require MFA delete for critical S3 buckets
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    contains(resource.name, "prod")
    not resource.change.after.versioning[_].mfa_delete
    
    msg := sprintf(
        "⚠️  SOC2: Production S3 bucket '%s' should have MFA delete enabled (CC6.1)",
        [resource.name]
    )
}

# =============================================================================
# HIPAA COMPLIANCE POLICIES
# =============================================================================

# HIPAA: Require KMS encryption for PHI data
deny[msg] {
    resource := input.resource_changes[_]
    resource.type in ["aws_s3_bucket", "aws_db_instance", "aws_ebs_volume"]
    is_phi_resource(resource)
    not uses_kms_encryption(resource)
    
    msg := sprintf(
        "❌ HIPAA: PHI resource '%s' must use KMS encryption (§164.312(a)(2)(iv))",
        [resource.name]
    )
}

is_phi_resource(resource) {
    tags := resource.change.after.tags
    tags["DataType"] == "PHI"
}

is_phi_resource(resource) {
    contains(resource.name, "phi")
}

is_phi_resource(resource) {
    contains(resource.name, "health")
}

uses_kms_encryption(resource) {
    resource.change.after.kms_key_id != null
}

# HIPAA: Require backup for PHI data (minimum 6 years retention)
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    is_phi_resource(resource)
    retention := resource.change.after.backup_retention_period
    retention < 2190  # 6 years in days
    
    msg := sprintf(
        "❌ HIPAA: PHI database '%s' requires minimum 6-year backup retention (current: %d days)",
        [resource.name, retention]
    )
}

# HIPAA: Prohibit public access to PHI data
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    is_phi_resource(resource)
    resource.change.after.publicly_accessible == true
    
    msg := sprintf(
        "❌ HIPAA: PHI database '%s' cannot be publicly accessible (§164.312(e)(1))",
        [resource.name]
    )
}

# HIPAA: Require VPC for PHI resources
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    is_phi_resource(resource)
    not resource.change.after.vpc_security_group_ids
    
    msg := sprintf(
        "❌ HIPAA: PHI compute resource '%s' must be in VPC (§164.312(e)(1))",
        [resource.name]
    )
}

# HIPAA: Require audit logging for PHI access
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    is_phi_resource(resource)
    not has_access_logging(resource)
    
    msg := sprintf(
        "❌ HIPAA: PHI bucket '%s' must have access logging enabled (§164.312(b))",
        [resource.name]
    )
}

has_access_logging(resource) {
    resource.change.after.logging
}

# =============================================================================
# PCI-DSS COMPLIANCE POLICIES
# =============================================================================

# PCI-DSS: Require encryption for cardholder data
deny[msg] {
    resource := input.resource_changes[_]
    resource.type in ["aws_s3_bucket", "aws_db_instance", "aws_ebs_volume"]
    is_cardholder_data(resource)
    not is_encrypted(resource)
    
    msg := sprintf(
        "❌ PCI-DSS: Cardholder data resource '%s' must be encrypted (Req 3.4)",
        [resource.name]
    )
}

is_cardholder_data(resource) {
    tags := resource.change.after.tags
    tags["DataType"] in ["CHD", "CardholderData", "PaymentData"]
}

is_cardholder_data(resource) {
    contains(resource.name, "payment")
}

is_cardholder_data(resource) {
    contains(resource.name, "card")
}

# PCI-DSS: Prohibit internet-facing payment systems
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    is_cardholder_data(resource)
    has_public_ip(resource)
    
    msg := sprintf(
        "❌ PCI-DSS: Payment system '%s' cannot have public IP (Req 1.3)",
        [resource.name]
    )
}

has_public_ip(resource) {
    resource.change.after.associate_public_ip_address == true
}

# PCI-DSS: Require multi-factor authentication
warn[msg] {
    iam_users := count([r | r := input.resource_changes[_]; r.type == "aws_iam_user"])
    iam_users > 0
    
    msg := "⚠️  PCI-DSS: All administrative access requires MFA (Req 8.3)"
}

# PCI-DSS: Require network segmentation
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group"
    is_cardholder_data(resource)
    not properly_segmented(resource)
    
    msg := sprintf(
        "❌ PCI-DSS: Cardholder data security group '%s' must restrict access (Req 1.2)",
        [resource.name]
    )
}

properly_segmented(resource) {
    # Check if ingress is not from 0.0.0.0/0
    ingress := resource.change.after.ingress[_]
    not ingress.cidr_blocks[_] == "0.0.0.0/0"
}

# PCI-DSS: Require log retention for 1 year
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_cloudwatch_log_group"
    is_cardholder_data(resource)
    retention := resource.change.after.retention_in_days
    retention < 365
    
    msg := sprintf(
        "⚠️  PCI-DSS: Log group '%s' should retain logs for minimum 1 year (Req 10.7)",
        [resource.name]
    )
}

# =============================================================================
# GDPR COMPLIANCE POLICIES
# =============================================================================

# GDPR: Require encryption for personal data
deny[msg] {
    resource := input.resource_changes[_]
    resource.type in ["aws_s3_bucket", "aws_db_instance", "aws_ebs_volume"]
    is_personal_data(resource)
    not is_encrypted(resource)
    
    msg := sprintf(
        "❌ GDPR: Personal data resource '%s' must be encrypted (Art. 32)",
        [resource.name]
    )
}

is_personal_data(resource) {
    tags := resource.change.after.tags
    tags["DataType"] in ["PII", "PersonalData", "GDPR"]
}

is_personal_data(resource) {
    tags := resource.change.after.tags
    tags["GDPRScope"] == "true"
}

# GDPR: Enforce data residency requirements
deny[msg] {
    resource := input.resource_changes[_]
    resource.type in ["aws_s3_bucket", "aws_db_instance"]
    is_personal_data(resource)
    is_eu_data(resource)
    not is_in_eu_region(resource)
    
    msg := sprintf(
        "❌ GDPR: EU personal data resource '%s' must reside in EU region (Art. 44-49)",
        [resource.name]
    )
}

is_eu_data(resource) {
    tags := resource.change.after.tags
    tags["DataResidency"] == "EU"
}

is_in_eu_region(resource) {
    region := resource.change.after.region
    region in ["eu-west-1", "eu-west-2", "eu-west-3", "eu-central-1", "eu-north-1"]
}

# GDPR: Require data retention policies
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    is_personal_data(resource)
    not has_lifecycle_policy(resource)
    
    msg := sprintf(
        "⚠️  GDPR: Personal data bucket '%s' should have retention/deletion policy (Art. 5(1)(e))",
        [resource.name]
    )
}

has_lifecycle_policy(resource) {
    resource.change.after.lifecycle_rule
}

# GDPR: Require data breach detection
warn[msg] {
    guardduty_count := count([r | r := input.resource_changes[_]; r.type == "aws_guardduty_detector"])
    guardduty_count == 0
    
    msg := "⚠️  GDPR: GuardDuty should be enabled for breach detection (Art. 32, 33)"
}

# GDPR: Require data processing agreements
warn[msg] {
    resource := input.resource_changes[_]
    resource.type in ["aws_s3_bucket", "aws_db_instance"]
    is_personal_data(resource)
    not has_dpa_tag(resource)
    
    msg := sprintf(
        "⚠️  GDPR: Personal data resource '%s' should have DPA reference tag (Art. 28)",
        [resource.name]
    )
}

has_dpa_tag(resource) {
    tags := resource.change.after.tags
    tags["DPA"]
}

# =============================================================================
# ISO 27001 COMPLIANCE POLICIES
# =============================================================================

# ISO 27001: Require change management tags
deny[msg] {
    resource := input.resource_changes[_]
    contains(resource.name, "prod")
    not has_change_control_tags(resource)
    
    msg := sprintf(
        "❌ ISO27001: Production resource '%s' requires change control tags (A.12.1.2)",
        [resource.name]
    )
}

has_change_control_tags(resource) {
    tags := resource.change.after.tags
    tags["ChangeTicket"]
    tags["ApprovedBy"]
}

# ISO 27001: Require backup for critical systems
deny[msg] {
    resource := input.resource_changes[_]
    resource.type in ["aws_db_instance", "aws_ebs_volume"]
    is_critical_system(resource)
    not has_backup_configured(resource)
    
    msg := sprintf(
        "❌ ISO27001: Critical system '%s' must have backup configured (A.12.3.1)",
        [resource.name]
    )
}

is_critical_system(resource) {
    tags := resource.change.after.tags
    tags["Criticality"] in ["Critical", "High"]
}

has_backup_configured(resource) {
    resource.type == "aws_db_instance"
    resource.change.after.backup_retention_period > 7
}

has_backup_configured(resource) {
    resource.type == "aws_ebs_volume"
    tags := resource.change.after.tags
    tags["Backup"] == "true"
}

# =============================================================================
# COMPLIANCE SUMMARY
# =============================================================================

violation_count := count(deny)
warning_count := count(warn)

compliance_frameworks := [
    "SOC2 (System and Organization Controls)",
    "HIPAA (Health Insurance Portability)",
    "PCI-DSS (Payment Card Industry)",
    "GDPR (General Data Protection Regulation)",
    "ISO 27001 (Information Security)"
]

summary := {
    "compliant": violation_count == 0,
    "violations": violation_count,
    "warnings": warning_count,
    "frameworks_checked": compliance_frameworks,
    "critical_controls": [
        "Data encryption at rest and in transit",
        "Access logging and audit trails",
        "Data residency and sovereignty",
        "Backup and retention policies",
        "Network segmentation",
        "Multi-factor authentication"
    ]
}
