# =============================================================================
# VARIABLES FOR INTEGRATED TERRAFORM CONFIGURATION
# =============================================================================
# Variables file for main-integrated-example.tf
# Copy values to terraform.tfvars or use -var-file flag

# =============================================================================
# PROJECT CONFIGURATION
# =============================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "cloud-infrastructure-automation"
}

variable "environment" {
  description = "Environment name (dev, staging, prod, dr)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod", "dr"], var.environment)
    error_message = "Environment must be dev, staging, prod, or dr."
  }
}

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "dr_region" {
  description = "Disaster recovery region"
  type        = string
  default     = "us-west-2"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "Engineering"
}

variable "owner_email" {
  description = "Owner email for resource tagging"
  type        = string
  default     = "devops@example.com"
}

# =============================================================================
# NETWORKING
# =============================================================================

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# =============================================================================
# EC2 CONFIGURATION
# =============================================================================

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "ec2_ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 (update for your region)
}

variable "ec2_key_name" {
  description = "EC2 SSH key pair name"
  type        = string
  default     = ""
}

# =============================================================================
# AUTO SCALING
# =============================================================================

variable "asg_min_size" {
  description = "Minimum number of EC2 instances"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum number of EC2 instances"
  type        = number
  default     = 3
}

variable "asg_desired_capacity" {
  description = "Desired number of EC2 instances"
  type        = number
  default     = 2
}

# =============================================================================
# BASTION HOST
# =============================================================================

variable "bastion_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH to bastion"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # ⚠️ Restrict this in production!
}

# =============================================================================
# COST MANAGEMENT
# =============================================================================

variable "monthly_budget" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 1000
}

variable "budget_alert_emails" {
  description = "Email addresses for budget alerts"
  type        = list(string)
  default     = ["devops@example.com"]
}

# =============================================================================
# MONITORING & ALERTS
# =============================================================================

variable "enable_observability" {
  description = "Enable observability stack (Prometheus/Grafana)"
  type        = bool
  default     = true
}

variable "alert_emails" {
  description = "Email addresses for monitoring alerts"
  type        = list(string)
  default     = ["oncall@example.com"]
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}

variable "pagerduty_integration_key" {
  description = "PagerDuty integration key"
  type        = string
  default     = ""
  sensitive   = true
}
