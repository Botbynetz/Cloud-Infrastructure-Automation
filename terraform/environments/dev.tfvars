# Environment-specific variables for Development

# Environment
environment      = "dev"
lifecycle_stage  = "testing"

# FinOps Tags (MANDATORY)
cost_center      = "CC-DEV-001"
business_unit    = "Engineering"
owner_email      = "devops@univaicloud.com"
project_name     = "cloud-infra"

# Compliance
data_classification = "internal"
compliance_framework = "SOC2"

# Cost Optimization
auto_shutdown_enabled = true
shutdown_schedule     = "weekdays-after-hours"

# AWS Configuration
aws_region    = "ap-southeast-1"
aws_dr_region = "us-west-2"
vpc_cidr      = "10.0.0.0/16"
instance_type = "t3.micro"

# GCP Configuration (if used)
gcp_project_id = ""
gcp_region     = "asia-southeast1"

# Azure Configuration (if used)
azure_subscription_id = ""

# Service Level
service_level = "bronze"
backup_policy = "daily"
dr_rpo        = "24h"
dr_rto        = "24h"

# Deployment tracking
deployed_by = "terraform-dev"

# Additional tags
additional_tags = {
  Purpose      = "Development"
  Team         = "DevOps"
  Department   = "Engineering"
}
