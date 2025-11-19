# Environment-specific variables for Production

# Environment
environment      = "prod"
lifecycle_stage  = "active"

# FinOps Tags (MANDATORY)
cost_center      = "CC-PROD-001"
business_unit    = "Operations"
owner_email      = "ops@univaicloud.com"
project_name     = "cloud-infra"

# Compliance
data_classification = "confidential"
compliance_framework = "SOC2,ISO27001,GDPR,HIPAA"

# Cost Optimization (disabled for production)
auto_shutdown_enabled = false
shutdown_schedule     = "disabled"

# AWS Configuration
aws_region    = "ap-southeast-1"
aws_dr_region = "us-west-2"
vpc_cidr      = "10.2.0.0/16"
instance_type = "t3.medium"

# GCP Configuration (if used)
gcp_project_id = ""
gcp_region     = "asia-southeast1"

# Azure Configuration (if used)
azure_subscription_id = ""

# Service Level (PRODUCTION = PLATINUM)
service_level = "platinum"
backup_policy = "daily"
dr_rpo        = "1h"
dr_rto        = "1h"

# Deployment tracking
deployed_by = "terraform-prod"

# Additional tags
additional_tags = {
  Purpose          = "Production Workload"
  Team             = "Operations"
  Department       = "IT"
  CriticalityLevel = "critical"
  SLA              = "99.99"
  MaintenanceWindow = "Sunday-02:00-04:00-UTC"
}
