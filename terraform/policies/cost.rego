# =============================================================================
# OPA Cost Management Policy - STEP 3 & 6 Enhancement
# =============================================================================
# Enforces cost optimization and FinOps best practices
# Validates: Instance types, scaling limits, resource tagging, budgets

package terraform.cost

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# =============================================================================
# INSTANCE TYPE POLICIES
# =============================================================================

# Allowed instance types per environment
allowed_instance_types := {
    "dev": [
        "t3.micro", "t3.small", "t3.medium",
        "t4g.micro", "t4g.small", "t4g.medium"
    ],
    "staging": [
        "t3.small", "t3.medium", "t3.large",
        "t4g.small", "t4g.medium", "t4g.large",
        "m5.large", "m5.xlarge"
    ],
    "prod": [
        "t3.medium", "t3.large", "t3.xlarge",
        "m5.large", "m5.xlarge", "m5.2xlarge",
        "c5.large", "c5.xlarge", "r5.large", "r5.xlarge"
    ]
}

# Deny expensive instances in dev/staging
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    instance_type := resource.change.after.instance_type
    env := get_environment(resource)
    env in ["dev", "staging"]
    
    not instance_type in allowed_instance_types[env]
    
    msg := sprintf(
        "❌ COST: Instance '%s' uses '%s' which is not allowed in '%s' environment. Allowed: %v",
        [resource.name, instance_type, env, allowed_instance_types[env]]
    )
}

# Warn about expensive instances in production
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    instance_type := resource.change.after.instance_type
    env := get_environment(resource)
    env == "prod"
    
    is_expensive_instance(instance_type)
    
    msg := sprintf(
        "⚠️  COST: Instance '%s' uses expensive type '%s' in production. Consider cost optimization.",
        [resource.name, instance_type]
    )
}

is_expensive_instance(instance_type) {
    # Instances larger than 2xlarge
    contains(instance_type, "4xlarge")
}

is_expensive_instance(instance_type) {
    contains(instance_type, "8xlarge")
}

is_expensive_instance(instance_type) {
    contains(instance_type, "12xlarge")
}

# =============================================================================
# RDS COST POLICIES
# =============================================================================

# Deny expensive RDS instances in non-prod
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    instance_class := resource.change.after.instance_class
    env := get_environment(resource)
    env != "prod"
    
    not is_allowed_rds_class(instance_class, env)
    
    msg := sprintf(
        "❌ COST: RDS instance '%s' uses '%s' in '%s' - use smaller instance for non-production",
        [resource.name, instance_class, env]
    )
}

is_allowed_rds_class(class, "dev") {
    class in ["db.t3.micro", "db.t3.small", "db.t4g.micro", "db.t4g.small"]
}

is_allowed_rds_class(class, "staging") {
    class in ["db.t3.small", "db.t3.medium", "db.t4g.small", "db.t4g.medium", "db.r5.large"]
}

# Require gp3 storage type (cheaper than io1/io2)
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    storage_type := resource.change.after.storage_type
    storage_type in ["io1", "io2"]
    
    msg := sprintf(
        "⚠️  COST: RDS '%s' uses expensive storage type '%s' - consider gp3 for cost savings",
        [resource.name, storage_type]
    )
}

# =============================================================================
# AUTO SCALING POLICIES
# =============================================================================

# Limit max size for Auto Scaling Groups
max_asg_size := {
    "dev": 2,
    "staging": 5,
    "prod": 20
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_autoscaling_group"
    max_size := resource.change.after.max_size
    env := get_environment(resource)
    
    max_size > max_asg_size[env]
    
    msg := sprintf(
        "❌ COST: Auto Scaling Group '%s' max_size %d exceeds limit %d for '%s' environment",
        [resource.name, max_size, max_asg_size[env], env]
    )
}

# Warn about min_size being too high
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_autoscaling_group"
    min_size := resource.change.after.min_size
    max_size := resource.change.after.max_size
    env := get_environment(resource)
    env != "prod"
    
    min_size > (max_size * 0.5)
    
    msg := sprintf(
        "⚠️  COST: ASG '%s' min_size (%d) is >50%% of max_size (%d) in non-prod - consider lowering",
        [resource.name, min_size, max_size]
    )
}

# =============================================================================
# STORAGE COST POLICIES
# =============================================================================

# Deny large EBS volumes in dev
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_ebs_volume"
    size := resource.change.after.size
    env := get_environment(resource)
    env == "dev"
    
    size > 100
    
    msg := sprintf(
        "❌ COST: EBS volume '%s' size %dGB exceeds 100GB limit for dev environment",
        [resource.name, size]
    )
}

# Recommend gp3 over gp2 for cost savings
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_ebs_volume"
    volume_type := resource.change.after.type
    volume_type == "gp2"
    
    msg := sprintf(
        "⚠️  COST: EBS volume '%s' uses gp2 - migrate to gp3 for ~20%% cost savings",
        [resource.name]
    )
}

# Deny expensive io2 volumes in non-prod
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_ebs_volume"
    volume_type := resource.change.after.type
    env := get_environment(resource)
    env != "prod"
    
    volume_type in ["io1", "io2"]
    
    msg := sprintf(
        "❌ COST: EBS volume '%s' uses expensive type '%s' in non-production",
        [resource.name, volume_type]
    )
}

# =============================================================================
# TAGGING POLICIES FOR COST ALLOCATION
# =============================================================================

required_cost_tags := ["CostCenter", "Project", "Owner", "Environment"]

deny[msg] {
    resource := input.resource_changes[_]
    resource.type in [
        "aws_instance", "aws_db_instance", "aws_ebs_volume",
        "aws_s3_bucket", "aws_elasticache_cluster", "aws_lb"
    ]
    
    missing_tags := [tag | tag := required_cost_tags[_]; not resource.change.after.tags[tag]]
    count(missing_tags) > 0
    
    msg := sprintf(
        "❌ COST: Resource '%s' missing cost allocation tags: %v (required for FinOps tracking)",
        [resource.name, missing_tags]
    )
}

# Require budget tags for chargeback
warn[msg] {
    resource := input.resource_changes[_]
    resource.type in ["aws_instance", "aws_db_instance", "aws_s3_bucket"]
    not resource.change.after.tags["Budget"]
    
    msg := sprintf(
        "⚠️  COST: Resource '%s' should have 'Budget' tag for cost allocation",
        [resource.name]
    )
}

# =============================================================================
# ELASTICACHE COST POLICIES
# =============================================================================

# Deny expensive ElastiCache instances in non-prod
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_elasticache_cluster"
    node_type := resource.change.after.node_type
    env := get_environment(resource)
    env != "prod"
    
    not is_allowed_cache_type(node_type, env)
    
    msg := sprintf(
        "❌ COST: ElastiCache '%s' uses '%s' in '%s' - use smaller instance",
        [resource.name, node_type, env]
    )
}

is_allowed_cache_type(node_type, "dev") {
    node_type in ["cache.t3.micro", "cache.t3.small", "cache.t4g.micro"]
}

is_allowed_cache_type(node_type, "staging") {
    node_type in ["cache.t3.small", "cache.t3.medium", "cache.r5.large"]
}

# =============================================================================
# NAT GATEWAY COST POLICIES
# =============================================================================

# Warn about multiple NAT Gateways in non-prod
warn[msg] {
    nat_gateways := [r | r := input.resource_changes[_]; r.type == "aws_nat_gateway"]
    count(nat_gateways) > 1
    env := get_environment_from_list(nat_gateways)
    env != "prod"
    
    msg := sprintf(
        "⚠️  COST: Multiple NAT Gateways detected in '%s' ($0.045/hour each) - consider single NAT for non-prod",
        [env]
    )
}

# =============================================================================
# LOAD BALANCER COST POLICIES
# =============================================================================

# Warn about unused Application Load Balancers
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_lb"
    load_balancer_type := resource.change.after.load_balancer_type
    load_balancer_type == "application"
    env := get_environment(resource)
    env == "dev"
    
    msg := sprintf(
        "⚠️  COST: ALB '%s' in dev ($0.0225/hour + $0.008/LCU-hour) - consider using NLB or removing",
        [resource.name]
    )
}

# =============================================================================
# SNAPSHOT & BACKUP COST POLICIES
# =============================================================================

# Warn about indefinite snapshot retention
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    retention := resource.change.after.backup_retention_period
    retention > 30
    env := get_environment(resource)
    env != "prod"
    
    msg := sprintf(
        "⚠️  COST: RDS '%s' backup retention %d days in non-prod - consider reducing to 7-14 days",
        [resource.name, retention]
    )
}

# =============================================================================
# S3 STORAGE CLASS POLICIES
# =============================================================================

# Recommend lifecycle policies for S3 buckets
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    not has_lifecycle_rule(resource)
    
    msg := sprintf(
        "⚠️  COST: S3 bucket '%s' should have lifecycle rules to transition to cheaper storage classes",
        [resource.name]
    )
}

has_lifecycle_rule(resource) {
    resource.change.after.lifecycle_rule
}

# =============================================================================
# RESERVED INSTANCE POLICIES
# =============================================================================

# Recommend Reserved Instances for prod
warn[msg] {
    instances := [r | r := input.resource_changes[_]; r.type == "aws_instance"]
    count(instances) > 3
    env := get_environment_from_list(instances)
    env == "prod"
    
    msg := "⚠️  COST: Consider Reserved Instances for prod workloads (up to 75% savings)"
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

get_environment(resource) := env {
    env := resource.change.after.tags["Environment"]
} else := env {
    contains(resource.name, "prod")
    env := "prod"
} else := env {
    contains(resource.name, "staging")
    env := "staging"
} else := "dev"

get_environment_from_list(resources) := env {
    resource := resources[0]
    env := get_environment(resource)
}

# =============================================================================
# COST SUMMARY
# =============================================================================

violation_count := count(deny)
warning_count := count(warn)

estimated_monthly_cost := {
    "ec2_instances": count([r | r := input.resource_changes[_]; r.type == "aws_instance"]),
    "rds_instances": count([r | r := input.resource_changes[_]; r.type == "aws_db_instance"]),
    "nat_gateways": count([r | r := input.resource_changes[_]; r.type == "aws_nat_gateway"]),
    "load_balancers": count([r | r := input.resource_changes[_]; r.type == "aws_lb"])
}

summary := {
    "cost_violations": violation_count,
    "cost_warnings": warning_count,
    "resources_checked": estimated_monthly_cost,
    "policies_enforced": [
        "Instance type restrictions",
        "RDS instance sizing",
        "Auto Scaling limits",
        "Storage optimization",
        "Cost allocation tagging",
        "Reserved Instance recommendations"
    ]
}
