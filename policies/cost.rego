# Cost Control Policies
# OPA rules for FinOps and cost optimization

package terraform.cost

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# ============================================
# INSTANCE TYPE COST LIMITS
# ============================================

# Define cost tiers for instance types
instance_cost_tier := {
    "nano": ["t3.nano", "t3a.nano"],
    "micro": ["t3.micro", "t3a.micro", "t2.micro"],
    "small": ["t3.small", "t3a.small", "t2.small"],
    "medium": ["t3.medium", "t3a.medium", "t2.medium", "m5.large"],
    "large": ["m5.xlarge", "m5.2xlarge", "c5.xlarge", "c5.2xlarge"],
    "xlarge": ["m5.4xlarge", "m5.8xlarge", "c5.4xlarge", "c5.9xlarge"],
    "expensive": ["m5.12xlarge", "m5.16xlarge", "m5.24xlarge", "c5.18xlarge", "c5.24xlarge"]
}

# Environment-specific instance type allowlist
allowed_instance_types := {
    "dev": ["nano", "micro", "small"],
    "staging": ["micro", "small", "medium"],
    "prod": ["small", "medium", "large", "xlarge"],
    "dr": ["small", "medium", "large", "xlarge"]
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    instance := resource.change.after
    
    env := instance.tags.Environment
    instance_type := instance.instance_type
    
    not is_instance_type_allowed(instance_type, env)
    
    msg := sprintf("COST VIOLATION: Instance type '%s' not allowed in %s environment (resource: %s). Allowed tiers: %v", 
                   [instance_type, env, resource.address, allowed_instance_types[env]])
}

is_instance_type_allowed(instance_type, env) {
    tier := instance_cost_tier[allowed_tier]
    allowed_tier := allowed_instance_types[env][_]
    instance_type == tier[_]
}

# ============================================
# STORAGE COST LIMITS
# ============================================

# Maximum EBS volume sizes by environment (GB)
max_ebs_size := {
    "dev": 100,
    "staging": 500,
    "prod": 2000,
    "dr": 2000
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_ebs_volume"
    volume := resource.change.after
    
    env := volume.tags.Environment
    size := volume.size
    max_size := max_ebs_size[env]
    
    size > max_size
    
    msg := sprintf("COST VIOLATION: EBS volume '%s' size (%d GB) exceeds %s limit (%d GB)", 
                   [resource.address, size, env, max_size])
}

# Enforce cost-effective EBS volume types
cost_effective_volume_types := ["gp3", "gp2"]
expensive_volume_types := ["io1", "io2"]

warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_ebs_volume"
    volume := resource.change.after
    
    env := volume.tags.Environment
    env in ["dev", "staging"]
    
    volume.type == expensive_volume_types[_]
    
    msg := sprintf("COST WARNING: EBS volume '%s' uses expensive type '%s' in %s. Consider gp3 for cost savings", 
                   [resource.address, volume.type, env])
}

# ============================================
# RDS COST OPTIMIZATION
# ============================================

# Block unnecessary RDS features in dev/staging
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    db := resource.change.after
    
    env := db.tags.Environment
    env in ["dev", "staging"]
    
    db.multi_az == true
    
    msg := sprintf("COST VIOLATION: RDS instance '%s' uses multi-AZ in %s (additional 100%% cost)", 
                   [resource.address, env])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    db := resource.change.after
    
    env := db.tags.Environment
    env == "dev"
    
    db.backup_retention_period > 7
    
    msg := sprintf("COST VIOLATION: Dev RDS instance '%s' has excessive backup retention (%d days). Max 7 days for dev", 
                   [resource.address, db.backup_retention_period])
}

# Enforce cost-effective RDS instance classes
dev_rds_classes := ["db.t3.micro", "db.t3.small", "db.t4g.micro", "db.t4g.small"]

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    db := resource.change.after
    
    env := db.tags.Environment
    env == "dev"
    
    not db.instance_class == dev_rds_classes[_]
    
    msg := sprintf("COST VIOLATION: Dev RDS instance '%s' must use cost-effective instance class. Allowed: %v (current: %s)", 
                   [resource.address, dev_rds_classes, db.instance_class])
}

# ============================================
# NAT GATEWAY COST OPTIMIZATION
# ============================================

# Limit number of NAT gateways
max_nat_gateways := {
    "dev": 1,
    "staging": 1,
    "prod": 3,
    "dr": 2
}

warn[msg] {
    nat_count := count([r | 
        r := input.resource_changes[_]
        r.type == "aws_nat_gateway"
        r.change.actions[_] == "create"
    ])
    
    # Get environment from first NAT gateway
    resource := input.resource_changes[_]
    resource.type == "aws_nat_gateway"
    env := resource.change.after.tags.Environment
    
    max := max_nat_gateways[env]
    nat_count > max
    
    msg := sprintf("COST WARNING: Creating %d NAT gateways in %s environment. Recommended max: %d (cost: $32.40/month each)", 
                   [nat_count, env, max])
}

# ============================================
# LOAD BALANCER COST OPTIMIZATION
# ============================================

# Recommend ALB over NLB for HTTP traffic
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_lb"
    lb := resource.change.after
    
    lb.load_balancer_type == "network"
    
    listener_uses_http(lb, input.resource_changes)
    
    msg := sprintf("COST WARNING: Load balancer '%s' uses NLB for HTTP traffic. ALB is more cost-effective for HTTP/HTTPS", 
                   [resource.address])
}

listener_uses_http(lb, resources) {
    resource := resources[_]
    resource.type == "aws_lb_listener"
    listener := resource.change.after
    listener.protocol in ["HTTP", "HTTPS"]
}

# ============================================
# S3 STORAGE CLASS OPTIMIZATION
# ============================================

warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    bucket := resource.change.after
    
    env := bucket.tags.Environment
    env in ["dev", "staging"]
    
    not has_lifecycle_policy(bucket, input.resource_changes)
    
    msg := sprintf("COST WARNING: S3 bucket '%s' should have lifecycle policy to transition to cheaper storage classes", 
                   [resource.address])
}

has_lifecycle_policy(bucket, resources) {
    resource := resources[_]
    resource.type == "aws_s3_bucket_lifecycle_configuration"
    # Simplified check
    resource.change.after.rule
}

# ============================================
# ELASTIC IP COST WARNING
# ============================================

warn[msg] {
    eip_count := count([r | 
        r := input.resource_changes[_]
        r.type == "aws_eip"
        r.change.actions[_] == "create"
    ])
    
    eip_count > 0
    
    msg := sprintf("COST WARNING: Creating %d Elastic IP(s). Unused EIPs cost $0.005/hour ($3.60/month)", [eip_count])
}

# ============================================
# AUTO-SHUTDOWN ENFORCEMENT
# ============================================

warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    instance := resource.change.after
    
    env := instance.tags.Environment
    env in ["dev", "staging"]
    
    not instance.tags.AutoShutdown
    
    msg := sprintf("COST WARNING: Instance '%s' in %s should have AutoShutdown tag. Potential savings: 70%% ($150/month)", 
                   [resource.address, env])
}

# ============================================
# COST ESTIMATION SUMMARY
# ============================================

# Estimate monthly cost for EC2 instances (simplified)
ec2_monthly_cost := cost {
    instance_costs := [c | 
        resource := input.resource_changes[_]
        resource.type == "aws_instance"
        resource.change.actions[_] == "create"
        c := estimate_instance_cost(resource.change.after.instance_type)
    ]
    cost := sum(instance_costs)
}

estimate_instance_cost(instance_type) = cost {
    # Simplified cost estimates (USD/month)
    costs := {
        "t3.nano": 3.80,
        "t3.micro": 7.60,
        "t3.small": 15.20,
        "t3.medium": 30.40,
        "t3.large": 60.80,
        "m5.large": 70.08,
        "m5.xlarge": 140.16,
        "m5.2xlarge": 280.32,
        "m5.4xlarge": 560.64
    }
    cost := costs[instance_type]
}

# Estimate monthly cost for RDS instances
rds_monthly_cost := cost {
    rds_costs := [c | 
        resource := input.resource_changes[_]
        resource.type == "aws_db_instance"
        resource.change.actions[_] == "create"
        c := estimate_rds_cost(resource.change.after)
    ]
    cost := sum(rds_costs)
}

estimate_rds_cost(db) = cost {
    base_costs := {
        "db.t3.micro": 12.41,
        "db.t3.small": 24.82,
        "db.t3.medium": 49.64,
        "db.m5.large": 124.10
    }
    base := base_costs[db.instance_class]
    
    # Double cost for multi-AZ
    multiplier := db.multi_az == true ? 2 : 1
    
    cost := base * multiplier
}

# Total estimated monthly cost
total_estimated_cost := ec2_monthly_cost + rds_monthly_cost

# Cost approval required for expensive changes
deny[msg] {
    total_estimated_cost > 500
    
    msg := sprintf("COST VIOLATION: Estimated monthly cost ($%.2f) exceeds approval threshold ($500). Manager approval required", 
                   [total_estimated_cost])
}

warn[msg] {
    total_estimated_cost > 200
    total_estimated_cost <= 500
    
    msg := sprintf("COST WARNING: Estimated monthly cost: $%.2f. Consider cost optimization", [total_estimated_cost])
}
