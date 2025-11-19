# Environment-specific variables for Disaster Recovery (DR)

# Environment
environment      = "dr"
lifecycle_stage  = "active"

# FinOps Tags (MANDATORY)
cost_center      = "CC-DR-001"
business_unit    = "Operations"
owner_email      = "dr@univaicloud.com"
project_name     = "cloud-infra"

# Compliance
data_classification = "confidential"
compliance_framework = "SOC2,ISO27001,GDPR,HIPAA"

# Cost Optimization (keep running for DR readiness)
auto_shutdown_enabled = false
shutdown_schedule     = "disabled"

# AWS Configuration (Different region from prod)
aws_region    = "us-west-2"
aws_dr_region = "eu-west-1"  # Tertiary region
vpc_cidr      = "10.3.0.0/16"
instance_type = "t3.medium"

# GCP Configuration (if used)
gcp_project_id = ""
gcp_region     = "us-west1"

# Azure Configuration (if used)
azure_subscription_id = ""

# Service Level (DR = PLATINUM)
service_level = "platinum"
backup_policy = "continuous"
dr_rpo        = "15min"  # Near real-time
dr_rto        = "30min"  # Fast recovery

# Deployment tracking
deployed_by = "terraform-dr"

# Additional tags
additional_tags = {
  Purpose          = "Disaster Recovery"
  Team             = "Operations"
  Department       = "IT"
  CriticalityLevel = "critical"
  SLA              = "99.99"
  MaintenanceWindow = "Coordinated-with-Production"
  ReplicationMode  = "Active-Passive"
  FailoverType     = "Automatic"
}
