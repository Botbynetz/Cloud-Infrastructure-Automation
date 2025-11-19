# Compliance Policies
# GDPR, HIPAA, SOC2, ISO27001 compliance checks

package terraform.compliance

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# ============================================
# GDPR COMPLIANCE
# ============================================

# Enforce encryption for personal data
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    bucket := resource.change.after
    
    is_gdpr_applicable(bucket)
    not has_encryption(bucket)
    
    msg := sprintf("GDPR VIOLATION: S3 bucket '%s' with personal data must have encryption enabled", [resource.address])
}

is_gdpr_applicable(resource) {
    resource.tags.DataClassification in ["confidential", "restricted"]
    resource.tags.Compliance
    contains(resource.tags.Compliance, "GDPR")
}

has_encryption(bucket) {
    bucket.server_side_encryption_configuration
}

# Enforce data residency (EU regions for GDPR)
gdpr_allowed_regions := ["eu-west-1", "eu-central-1", "eu-west-2", "eu-west-3", "eu-north-1"]

deny[msg] {
    resource := input.resource_changes[_]
    is_data_resource(resource.type)
    
    is_gdpr_applicable(resource.change.after)
    not is_in_gdpr_region(resource)
    
    msg := sprintf("GDPR VIOLATION: Resource '%s' with personal data must be in EU region. Allowed: %v", 
                   [resource.address, gdpr_allowed_regions])
}

is_data_resource(type) {
    type in ["aws_s3_bucket", "aws_db_instance", "aws_dynamodb_table", "aws_ebs_volume"]
}

is_in_gdpr_region(resource) {
    # Simplified check - would need actual region detection
    resource.change.after.tags.Region
    resource.change.after.tags.Region == gdpr_allowed_regions[_]
}

# Enforce backup retention for data recovery (GDPR Article 32)
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    db := resource.change.after
    
    is_gdpr_applicable(db)
    db.backup_retention_period < 30
    
    msg := sprintf("GDPR VIOLATION: Database '%s' with personal data must have backup retention >= 30 days (current: %d)", 
                   [resource.address, db.backup_retention_period])
}

# ============================================
# HIPAA COMPLIANCE
# ============================================

# Enforce encryption in transit and at rest for PHI
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    db := resource.change.after
    
    is_hipaa_applicable(db)
    db.storage_encrypted == false
    
    msg := sprintf("HIPAA VIOLATION: Database '%s' with PHI must have storage encryption enabled", [resource.address])
}

is_hipaa_applicable(resource) {
    resource.tags.DataClassification == "restricted"
    resource.tags.Compliance
    contains(resource.tags.Compliance, "HIPAA")
}

# Enforce audit logging for HIPAA
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    db := resource.change.after
    
    is_hipaa_applicable(db)
    not has_audit_logging(db)
    
    msg := sprintf("HIPAA VIOLATION: Database '%s' with PHI must have audit logging enabled", [resource.address])
}

has_audit_logging(db) {
    db.enabled_cloudwatch_logs_exports
    count(db.enabled_cloudwatch_logs_exports) > 0
}

# Block public access to PHI data
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    db := resource.change.after
    
    is_hipaa_applicable(db)
    db.publicly_accessible == true
    
    msg := sprintf("HIPAA VIOLATION: Database '%s' with PHI must not be publicly accessible", [resource.address])
}

# Enforce multi-factor delete for S3 with PHI
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    bucket := resource.change.after
    
    is_hipaa_applicable(bucket)
    not bucket.tags.MFADelete
    
    msg := sprintf("HIPAA WARNING: S3 bucket '%s' with PHI should enable MFA delete protection", [resource.address])
}

# ============================================
# SOC2 COMPLIANCE
# ============================================

# Enforce change tracking (Common Criteria CC6.1)
deny[msg] {
    resource := input.resource_changes[_]
    is_critical_resource(resource.type)
    
    is_soc2_applicable(resource.change.after)
    not has_change_tracking(resource.change.after)
    
    msg := sprintf("SOC2 VIOLATION: Critical resource '%s' must have change tracking tags", [resource.address])
}

is_critical_resource(type) {
    type in ["aws_db_instance", "aws_instance", "aws_lb", "aws_s3_bucket"]
}

is_soc2_applicable(resource) {
    resource.tags.Compliance
    contains(resource.tags.Compliance, "SOC2")
}

has_change_tracking(resource) {
    resource.tags.LastModified
    resource.tags.ModifiedBy
}

# Enforce backup policies (Availability CC7.2)
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    db := resource.change.after
    
    is_soc2_applicable(db)
    not db.tags.BackupPolicy
    
    msg := sprintf("SOC2 VIOLATION: Database '%s' must have BackupPolicy tag defined", [resource.address])
}

# Enforce monitoring (Monitoring CC7.3)
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    instance := resource.change.after
    
    is_soc2_applicable(instance)
    not instance.monitoring
    
    msg := sprintf("SOC2 WARNING: Instance '%s' should have detailed monitoring enabled", [resource.address])
}

# ============================================
# ISO27001 COMPLIANCE
# ============================================

# Enforce access control (ISO27001 A.9.4.1)
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group_rule"
    rule := resource.change.after
    
    is_iso27001_applicable(rule)
    rule.type == "ingress"
    has_overly_permissive_access(rule)
    
    msg := sprintf("ISO27001 VIOLATION: Security group rule '%s' has overly permissive access", [resource.address])
}

is_iso27001_applicable(resource) {
    resource.tags.Compliance
    contains(resource.tags.Compliance, "ISO27001")
}

has_overly_permissive_access(rule) {
    rule.cidr_blocks[_] == "0.0.0.0/0"
    rule.from_port != 443  # Allow HTTPS from anywhere
}

# Enforce network segregation (ISO27001 A.13.1.3)
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    db := resource.change.after
    
    is_iso27001_applicable(db)
    not db.db_subnet_group_name
    
    msg := sprintf("ISO27001 VIOLATION: Database '%s' must be in a subnet group for network segregation", [resource.address])
}

# Enforce secure configuration (ISO27001 A.12.6.1)
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    instance := resource.change.after
    
    is_iso27001_applicable(instance)
    not has_secure_ami(instance)
    
    msg := sprintf("ISO27001 VIOLATION: Instance '%s' must use approved/hardened AMI", [resource.address])
}

has_secure_ami(instance) {
    # Check if AMI has security approval tag (simplified)
    instance.tags.AMIApproved == "true"
}

# Enforce log retention (ISO27001 A.12.4.1)
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_cloudwatch_log_group"
    log_group := resource.change.after
    
    is_iso27001_applicable(log_group)
    log_group.retention_in_days < 90
    
    msg := sprintf("ISO27001 VIOLATION: Log group '%s' must retain logs for at least 90 days (current: %d)", 
                   [resource.address, log_group.retention_in_days])
}

# ============================================
# PCI-DSS COMPLIANCE
# ============================================

# Enforce encryption for cardholder data
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    db := resource.change.after
    
    is_pci_applicable(db)
    db.storage_encrypted == false
    
    msg := sprintf("PCI-DSS VIOLATION: Database '%s' with payment data must have storage encryption enabled", [resource.address])
}

is_pci_applicable(resource) {
    resource.tags.DataClassification == "restricted"
    resource.tags.Compliance
    contains(resource.tags.Compliance, "PCI-DSS")
}

# Enforce network segmentation (PCI-DSS Requirement 1)
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    instance := resource.change.after
    
    is_pci_applicable(instance)
    not instance.vpc_security_group_ids
    
    msg := sprintf("PCI-DSS VIOLATION: Instance '%s' with payment data must have security groups defined", [resource.address])
}

# Enforce logging and monitoring (PCI-DSS Requirement 10)
deny[msg] {
    resource := input.resource_changes[_]
    resource.type in ["aws_db_instance", "aws_instance"]
    res := resource.change.after
    
    is_pci_applicable(res)
    not res.tags.AuditLogging
    
    msg := sprintf("PCI-DSS VIOLATION: Resource '%s' with payment data must have audit logging enabled", [resource.address])
}

# ============================================
# COMPLIANCE SUMMARY
# ============================================

# Identify resources by compliance framework
resources_by_compliance := {framework: resources |
    framework := ["GDPR", "HIPAA", "SOC2", "ISO27001", "PCI-DSS"][_]
    resources := [r |
        r := input.resource_changes[_]
        r.change.after.tags.Compliance
        contains(r.change.after.tags.Compliance, framework)
    ]
}

# Count compliance violations by framework
compliance_violations := {
    "GDPR": count([m | deny[m]; contains(m, "GDPR VIOLATION")]),
    "HIPAA": count([m | deny[m]; contains(m, "HIPAA VIOLATION")]),
    "SOC2": count([m | deny[m]; contains(m, "SOC2 VIOLATION")]),
    "ISO27001": count([m | deny[m]; contains(m, "ISO27001 VIOLATION")]),
    "PCI-DSS": count([m | deny[m]; contains(m, "PCI-DSS VIOLATION")])
}

# Overall compliance status
is_compliant {
    count(deny) == 0
}
