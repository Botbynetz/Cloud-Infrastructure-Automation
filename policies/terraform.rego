# Main Terraform Policy as Code
# Open Policy Agent (OPA) rules for infrastructure security and compliance

package terraform

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# ============================================
# 1. SECURITY POLICIES
# ============================================

# Deny public S3 buckets
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    resource.change.after.acl == "public-read"
    
    msg := sprintf("SECURITY VIOLATION: S3 bucket '%s' has public-read ACL. Use private ACL only.", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_public_access_block"
    block_config := resource.change.after
    
    not block_config.block_public_acls
    
    msg := sprintf("SECURITY VIOLATION: S3 bucket '%s' does not block public ACLs", [resource.address])
}

# Enforce encryption at rest for S3
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    not has_encryption(resource)
    
    msg := sprintf("SECURITY VIOLATION: S3 bucket '%s' must have encryption enabled", [resource.address])
}

has_encryption(resource) {
    resource.change.after.server_side_encryption_configuration
}

# Enforce encryption for EBS volumes
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_ebs_volume"
    resource.change.after.encrypted == false
    
    msg := sprintf("SECURITY VIOLATION: EBS volume '%s' must be encrypted", [resource.address])
}

# Enforce encryption for RDS instances
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    resource.change.after.storage_encrypted == false
    
    msg := sprintf("SECURITY VIOLATION: RDS instance '%s' must have storage encryption enabled", [resource.address])
}

# Block dangerous security group rules
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group_rule"
    rule := resource.change.after
    
    rule.type == "ingress"
    rule.from_port <= 22
    rule.to_port >= 22
    has_open_cidr(rule.cidr_blocks)
    
    msg := sprintf("SECURITY VIOLATION: Security group rule '%s' allows SSH (port 22) from 0.0.0.0/0", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group_rule"
    rule := resource.change.after
    
    rule.type == "ingress"
    rule.from_port <= 3389
    rule.to_port >= 3389
    has_open_cidr(rule.cidr_blocks)
    
    msg := sprintf("SECURITY VIOLATION: Security group rule '%s' allows RDP (port 3389) from 0.0.0.0/0", [resource.address])
}

has_open_cidr(cidr_blocks) {
    cidr_blocks[_] == "0.0.0.0/0"
}

# Enforce HTTPS for ALB listeners
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_lb_listener"
    listener := resource.change.after
    
    listener.protocol == "HTTP"
    listener.port != 80  # Allow HTTP only on port 80 for redirect
    
    msg := sprintf("SECURITY VIOLATION: ALB listener '%s' must use HTTPS protocol", [resource.address])
}

# Enforce IMDSv2 for EC2 instances
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    instance := resource.change.after
    
    not instance.metadata_options
    
    msg := sprintf("SECURITY VIOLATION: EC2 instance '%s' must configure metadata_options with IMDSv2", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    instance := resource.change.after
    
    instance.metadata_options.http_tokens != "required"
    
    msg := sprintf("SECURITY VIOLATION: EC2 instance '%s' must require IMDSv2 (http_tokens = required)", [resource.address])
}

# ============================================
# 2. COMPLIANCE POLICIES
# ============================================

# Enforce mandatory tags
mandatory_tags := ["Environment", "Project", "Owner", "CostCenter", "ManagedBy"]

deny[msg] {
    resource := input.resource_changes[_]
    is_taggable_resource(resource.type)
    missing := missing_tags(resource)
    count(missing) > 0
    
    msg := sprintf("COMPLIANCE VIOLATION: Resource '%s' missing mandatory tags: %v", [resource.address, missing])
}

is_taggable_resource(type) {
    taggable_types := [
        "aws_instance",
        "aws_ebs_volume",
        "aws_s3_bucket",
        "aws_db_instance",
        "aws_lb",
        "aws_vpc",
        "aws_subnet"
    ]
    type == taggable_types[_]
}

missing_tags(resource) = tags {
    existing := {tag | resource.change.after.tags[tag]}
    required := {tag | mandatory_tags[tag]}
    tags := required - existing
}

# Enforce allowed AWS regions
allowed_regions := ["ap-southeast-1", "us-west-2"]

warn[msg] {
    resource := input.resource_changes[_]
    resource.provider_name == "registry.terraform.io/hashicorp/aws"
    not is_allowed_region(resource)
    
    msg := sprintf("COMPLIANCE WARNING: Resource '%s' may not be in allowed regions: %v", [resource.address, allowed_regions])
}

is_allowed_region(resource) {
    # Check if resource is in allowed region (simplified check)
    resource.change.after.availability_zone
    startswith(resource.change.after.availability_zone, allowed_regions[_])
}

# Enforce data classification based on environment
deny[msg] {
    resource := input.resource_changes[_]
    is_taggable_resource(resource.type)
    
    env := resource.change.after.tags.Environment
    env == "prod"
    
    not resource.change.after.tags.DataClassification
    
    msg := sprintf("COMPLIANCE VIOLATION: Production resource '%s' must have DataClassification tag", [resource.address])
}

# Enforce backup tags for critical resources
deny[msg] {
    resource := input.resource_changes[_]
    resource.type in ["aws_db_instance", "aws_ebs_volume"]
    
    env := resource.change.after.tags.Environment
    env == "prod"
    
    not resource.change.after.tags.BackupPolicy
    
    msg := sprintf("COMPLIANCE VIOLATION: Production resource '%s' must have BackupPolicy tag", [resource.address])
}

# ============================================
# 3. COST CONTROL POLICIES
# ============================================

# Block expensive EC2 instance types in dev/staging
expensive_instance_types := [
    "m5.8xlarge", "m5.12xlarge", "m5.16xlarge", "m5.24xlarge",
    "c5.9xlarge", "c5.12xlarge", "c5.18xlarge", "c5.24xlarge",
    "r5.8xlarge", "r5.12xlarge", "r5.16xlarge", "r5.24xlarge"
]

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    instance := resource.change.after
    
    env := instance.tags.Environment
    env in ["dev", "staging"]
    
    instance.instance_type == expensive_instance_types[_]
    
    msg := sprintf("COST VIOLATION: EC2 instance '%s' uses expensive instance type '%s' in %s environment", 
                   [resource.address, instance.instance_type, env])
}

# Enforce auto-shutdown for dev resources
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    instance := resource.change.after
    
    env := instance.tags.Environment
    env == "dev"
    
    not instance.tags.AutoShutdown
    
    msg := sprintf("COST WARNING: Dev EC2 instance '%s' should have AutoShutdown tag for cost savings", [resource.address])
}

# Block RDS multi-AZ in dev environment
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    db := resource.change.after
    
    env := db.tags.Environment
    env == "dev"
    
    db.multi_az == true
    
    msg := sprintf("COST VIOLATION: RDS instance '%s' should not use multi-AZ in dev environment", [resource.address])
}

# Limit EBS volume sizes in non-production
max_dev_volume_size := 100  # GB

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_ebs_volume"
    volume := resource.change.after
    
    env := volume.tags.Environment
    env in ["dev", "staging"]
    
    volume.size > max_dev_volume_size
    
    msg := sprintf("COST VIOLATION: EBS volume '%s' size (%d GB) exceeds dev/staging limit (%d GB)", 
                   [resource.address, volume.size, max_dev_volume_size])
}

# ============================================
# 4. DISASTER RECOVERY POLICIES
# ============================================

# Enforce backup for production databases
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    db := resource.change.after
    
    env := db.tags.Environment
    env == "prod"
    
    db.backup_retention_period < 7
    
    msg := sprintf("DR VIOLATION: Production RDS instance '%s' must have backup retention >= 7 days (current: %d)", 
                   [resource.address, db.backup_retention_period])
}

# Enforce automated backups
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    db := resource.change.after
    
    env := db.tags.Environment
    env == "prod"
    
    db.backup_retention_period == 0
    
    msg := sprintf("DR VIOLATION: Production RDS instance '%s' must have automated backups enabled", [resource.address])
}

# Enforce snapshot copy for DR
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    db := resource.change.after
    
    env := db.tags.Environment
    env == "prod"
    
    not db.tags.DisasterRecoveryRPO
    
    msg := sprintf("DR WARNING: Production RDS instance '%s' should have DisasterRecoveryRPO tag defined", [resource.address])
}

# ============================================
# 5. NETWORK SECURITY POLICIES
# ============================================

# Enforce VPC flow logs
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_vpc"
    vpc := resource.change.after
    
    env := vpc.tags.Environment
    env == "prod"
    
    # Check if corresponding flow log exists (simplified)
    not has_flow_log(vpc, input.resource_changes)
    
    msg := sprintf("SECURITY VIOLATION: Production VPC '%s' must have VPC flow logs enabled", [resource.address])
}

has_flow_log(vpc, resources) {
    resource := resources[_]
    resource.type == "aws_flow_log"
    # Simplified check - in reality would need to match VPC ID
    resource.change.after.vpc_id
}

# Enforce private subnets for databases
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    db := resource.change.after
    
    db.publicly_accessible == true
    
    msg := sprintf("SECURITY VIOLATION: RDS instance '%s' must not be publicly accessible", [resource.address])
}

# ============================================
# 6. SUMMARY FUNCTIONS
# ============================================

# Count violations by severity
violation_summary := {
    "critical": count([msg | deny[msg]; contains(msg, "SECURITY VIOLATION")]),
    "high": count([msg | deny[msg]; contains(msg, "COMPLIANCE VIOLATION")]),
    "medium": count([msg | deny[msg]; contains(msg, "COST VIOLATION")]),
    "low": count([msg | warn[msg]])
}

# Check if deployment is allowed
allow_deployment {
    count(deny) == 0
}
