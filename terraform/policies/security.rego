# =============================================================================
# OPA Security Policy - STEP 3 Enhancement
# =============================================================================
# Enforces security best practices for Terraform configurations
# Validates: Encryption, IAM, Network Security, Compliance

package terraform.security

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# =============================================================================
# ENCRYPTION POLICIES
# =============================================================================

# Deny unencrypted S3 buckets
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    not has_encryption(resource)
    
    msg := sprintf(
        "❌ SECURITY: S3 bucket '%s' must have encryption enabled",
        [resource.name]
    )
}

has_encryption(resource) {
    resource.change.after.server_side_encryption_configuration
}

# Deny S3 buckets without versioning in production
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_versioning"
    resource.change.after.versioning_configuration[_].status != "Enabled"
    contains(resource.name, "prod")
    
    msg := sprintf(
        "❌ SECURITY: Production S3 bucket '%s' must have versioning enabled",
        [resource.name]
    )
}

# Deny RDS instances without encryption
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    not resource.change.after.storage_encrypted
    
    msg := sprintf(
        "❌ SECURITY: RDS instance '%s' must have storage encryption enabled",
        [resource.name]
    )
}

# Deny EBS volumes without encryption
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_ebs_volume"
    not resource.change.after.encrypted
    
    msg := sprintf(
        "❌ SECURITY: EBS volume '%s' must be encrypted",
        [resource.name]
    )
}

# Require KMS encryption for sensitive resources
deny[msg] {
    resource := input.resource_changes[_]
    resource.type in ["aws_db_instance", "aws_s3_bucket", "aws_ebs_volume"]
    resource.change.after.kms_key_id == null
    contains(resource.name, "prod")
    
    msg := sprintf(
        "❌ SECURITY: Production resource '%s' must use KMS encryption",
        [resource.name]
    )
}

# =============================================================================
# IAM POLICIES
# =============================================================================

# Deny IAM policies with wildcard actions
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_policy"
    policy := json.unmarshal(resource.change.after.policy)
    statement := policy.Statement[_]
    statement.Action[_] == "*"
    
    msg := sprintf(
        "❌ SECURITY: IAM policy '%s' has wildcard action '*' - use least privilege",
        [resource.name]
    )
}

# Deny IAM policies with wildcard resources
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_policy"
    policy := json.unmarshal(resource.change.after.policy)
    statement := policy.Statement[_]
    statement.Resource[_] == "*"
    statement.Effect == "Allow"
    
    msg := sprintf(
        "❌ SECURITY: IAM policy '%s' has wildcard resource '*' - specify exact resources",
        [resource.name]
    )
}

# Deny IAM users (enforce role-based access)
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_user"
    not contains(resource.name, "break-glass")
    
    msg := sprintf(
        "❌ SECURITY: IAM user '%s' detected - use IAM roles instead",
        [resource.name]
    )
}

# Require MFA for IAM users if they exist
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_user"
    not has_mfa_policy(resource)
    
    msg := sprintf(
        "⚠️  WARNING: IAM user '%s' should have MFA enforcement policy",
        [resource.name]
    )
}

has_mfa_policy(resource) {
    # Check if MFA policy is attached
    resource.change.after.force_mfa == true
}

# =============================================================================
# NETWORK SECURITY POLICIES
# =============================================================================

# Deny security groups with 0.0.0.0/0 ingress on sensitive ports
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group"
    ingress := resource.change.after.ingress[_]
    ingress.cidr_blocks[_] == "0.0.0.0/0"
    ingress.from_port in [22, 3389, 3306, 5432, 1433, 27017]
    
    msg := sprintf(
        "❌ SECURITY: Security group '%s' allows public access (0.0.0.0/0) on sensitive port %d",
        [resource.name, ingress.from_port]
    )
}

# Deny security groups allowing all protocols
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group"
    ingress := resource.change.after.ingress[_]
    ingress.protocol == "-1"
    ingress.cidr_blocks[_] == "0.0.0.0/0"
    
    msg := sprintf(
        "❌ SECURITY: Security group '%s' allows all traffic from internet (protocol -1)",
        [resource.name]
    )
}

# Deny public RDS instances
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    resource.change.after.publicly_accessible == true
    
    msg := sprintf(
        "❌ SECURITY: RDS instance '%s' must not be publicly accessible",
        [resource.name]
    )
}

# Require VPC for EC2 instances
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    not resource.change.after.vpc_security_group_ids
    
    msg := sprintf(
        "❌ SECURITY: EC2 instance '%s' must be launched in a VPC",
        [resource.name]
    )
}

# =============================================================================
# COMPLIANCE POLICIES
# =============================================================================

# Require specific tags for production resources
required_tags := ["Environment", "Project", "Owner", "CostCenter", "ManagedBy"]

deny[msg] {
    resource := input.resource_changes[_]
    resource.type in ["aws_instance", "aws_s3_bucket", "aws_db_instance", "aws_ebs_volume"]
    contains(resource.name, "prod")
    missing_tags := [tag | tag := required_tags[_]; not resource.change.after.tags[tag]]
    count(missing_tags) > 0
    
    msg := sprintf(
        "❌ COMPLIANCE: Production resource '%s' missing required tags: %v",
        [resource.name, missing_tags]
    )
}

# Deny resources without backup in production
deny[msg] {
    resource := input.resource_changes[_]
    resource.type in ["aws_db_instance", "aws_ebs_volume"]
    contains(resource.name, "prod")
    not has_backup_configured(resource)
    
    msg := sprintf(
        "❌ COMPLIANCE: Production resource '%s' must have backup configured",
        [resource.name]
    )
}

has_backup_configured(resource) {
    resource.type == "aws_db_instance"
    resource.change.after.backup_retention_period > 7
}

has_backup_configured(resource) {
    resource.type == "aws_ebs_volume"
    resource.change.after.tags["Backup"] == "true"
}

# Require multi-AZ for production databases
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    contains(resource.name, "prod")
    not resource.change.after.multi_az
    
    msg := sprintf(
        "❌ COMPLIANCE: Production RDS '%s' must be multi-AZ for high availability",
        [resource.name]
    )
}

# =============================================================================
# LOGGING & MONITORING POLICIES
# =============================================================================

# Require CloudWatch logging for Lambda functions
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_lambda_function"
    not has_cloudwatch_logs(resource)
    
    msg := sprintf(
        "❌ SECURITY: Lambda function '%s' must have CloudWatch logging enabled",
        [resource.name]
    )
}

has_cloudwatch_logs(resource) {
    resource.change.after.logging_config
}

# Require CloudTrail in production
warn[msg] {
    # Check if CloudTrail is enabled
    cloudtrail_count := count([r | r := input.resource_changes[_]; r.type == "aws_cloudtrail"])
    cloudtrail_count == 0
    
    msg := "⚠️  WARNING: CloudTrail should be enabled for audit logging"
}

# =============================================================================
# DATA PROTECTION POLICIES
# =============================================================================

# Deny S3 buckets without SSL enforcement
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_policy"
    policy := json.unmarshal(resource.change.after.policy)
    not enforces_ssl(policy)
    
    msg := sprintf(
        "❌ SECURITY: S3 bucket policy '%s' must enforce SSL/TLS",
        [resource.name]
    )
}

enforces_ssl(policy) {
    statement := policy.Statement[_]
    statement.Effect == "Deny"
    statement.Condition["Bool"]["aws:SecureTransport"] == "false"
}

# Deny public S3 buckets
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_public_access_block"
    resource.change.after.block_public_acls == false
    
    msg := sprintf(
        "❌ SECURITY: S3 bucket '%s' must block public ACLs",
        [resource.name]
    )
}

# =============================================================================
# SUMMARY FUNCTIONS
# =============================================================================

# Count violations by severity
violation_count := count(deny)
warning_count := count(warn)

# Overall policy compliance
compliant {
    violation_count == 0
}

# Generate summary
summary := {
    "compliant": compliant,
    "violations": violation_count,
    "warnings": warning_count,
    "policies_checked": [
        "Encryption at rest",
        "IAM least privilege",
        "Network security",
        "Compliance tagging",
        "Backup configuration",
        "Logging and monitoring",
        "Data protection"
    ]
}
