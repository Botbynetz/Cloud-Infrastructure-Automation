# Environment-specific variables for Staging

# Environment
environment      = "staging"
lifecycle_stage  = "active"

# FinOps Tags (MANDATORY)
cost_center      = "CC-STAGING-001"
business_unit    = "Engineering"
owner_email      = "devops@univaicloud.com"
project_name     = "cloud-infra"

# Compliance
data_classification = "internal"
compliance_framework = "SOC2,ISO27001"

# Cost Optimization
auto_shutdown_enabled = false
shutdown_schedule     = "disabled"

# AWS Configuration
aws_region    = "ap-southeast-1"
aws_dr_region = "us-west-2"
vpc_cidr      = "10.1.0.0/16"
instance_type = "t3.small"

# GCP Configuration (if used)
gcp_project_id = ""
gcp_region     = "asia-southeast1"

# Azure Configuration (if used)
azure_subscription_id = ""

# Service Level
service_level = "silver"
backup_policy = "daily"
dr_rpo        = "4h"
dr_rto        = "4h"

# Deployment tracking
deployed_by = "terraform-staging"

# Additional tags
additional_tags = {
  Purpose      = "Pre-Production Testing"
  Team         = "DevOps"
  Department   = "Engineering"
  CriticalityLevel = "medium"
}
