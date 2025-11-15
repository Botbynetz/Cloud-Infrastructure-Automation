# ==============================================================================
# Blue-Green Deployment Module - Input Variables
# ==============================================================================

# ------------------------------------------------------------------------------
# General Configuration
# ------------------------------------------------------------------------------

variable "application_name" {
  description = "Name of the application for resource naming"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.application_name))
    error_message = "Application name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

# ------------------------------------------------------------------------------
# Load Balancer Configuration
# ------------------------------------------------------------------------------

variable "internal_alb" {
  description = "Whether the ALB should be internal (true) or internet-facing (false)"
  type        = bool
  default     = false
}

variable "alb_security_groups" {
  description = "List of security group IDs for the ALB"
  type        = list(string)
}

variable "alb_subnets" {
  description = "List of subnet IDs for the ALB (requires at least 2 AZs)"
  type        = list(string)
  validation {
    condition     = length(var.alb_subnets) >= 2
    error_message = "ALB requires at least 2 subnets in different availability zones."
  }
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for the ALB"
  type        = bool
  default     = false
}

variable "enable_access_logs" {
  description = "Enable ALB access logs"
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "S3 bucket name for ALB access logs"
  type        = string
  default     = ""
}

# ------------------------------------------------------------------------------
# HTTPS/SSL Configuration
# ------------------------------------------------------------------------------

variable "enable_https" {
  description = "Enable HTTPS listener with SSL certificate"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS listener"
  type        = string
  default     = ""
}

variable "ssl_policy" {
  description = "SSL policy for HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

# ------------------------------------------------------------------------------
# Target Group Configuration
# ------------------------------------------------------------------------------

variable "application_port" {
  description = "Port on which the application listens"
  type        = number
  default     = 80
}

variable "target_type" {
  description = "Type of target (instance, ip, lambda)"
  type        = string
  default     = "instance"
  validation {
    condition     = contains(["instance", "ip", "lambda"], var.target_type)
    error_message = "Target type must be one of: instance, ip, lambda."
  }
}

variable "deregistration_delay" {
  description = "Time in seconds before deregistering a target"
  type        = number
  default     = 30
  validation {
    condition     = var.deregistration_delay >= 0 && var.deregistration_delay <= 3600
    error_message = "Deregistration delay must be between 0 and 3600 seconds."
  }
}

# ------------------------------------------------------------------------------
# Health Check Configuration
# ------------------------------------------------------------------------------

variable "health_check_path" {
  description = "Health check endpoint path"
  type        = string
  default     = "/health"
}

variable "health_check_interval" {
  description = "Time in seconds between health checks"
  type        = number
  default     = 30
  validation {
    condition     = var.health_check_interval >= 5 && var.health_check_interval <= 300
    error_message = "Health check interval must be between 5 and 300 seconds."
  }
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
  validation {
    condition     = var.health_check_timeout >= 2 && var.health_check_timeout <= 120
    error_message = "Health check timeout must be between 2 and 120 seconds."
  }
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive successful health checks"
  type        = number
  default     = 2
  validation {
    condition     = var.health_check_healthy_threshold >= 2 && var.health_check_healthy_threshold <= 10
    error_message = "Healthy threshold must be between 2 and 10."
  }
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive failed health checks"
  type        = number
  default     = 3
  validation {
    condition     = var.health_check_unhealthy_threshold >= 2 && var.health_check_unhealthy_threshold <= 10
    error_message = "Unhealthy threshold must be between 2 and 10."
  }
}

variable "health_check_matcher" {
  description = "HTTP response codes indicating a healthy target"
  type        = string
  default     = "200-299"
}

# ------------------------------------------------------------------------------
# Sticky Sessions Configuration
# ------------------------------------------------------------------------------

variable "enable_stickiness" {
  description = "Enable sticky sessions for target groups"
  type        = bool
  default     = false
}

variable "stickiness_duration" {
  description = "Duration of sticky sessions in seconds"
  type        = number
  default     = 86400
  validation {
    condition     = var.stickiness_duration >= 1 && var.stickiness_duration <= 604800
    error_message = "Stickiness duration must be between 1 and 604800 seconds (7 days)."
  }
}

# ------------------------------------------------------------------------------
# Deployment Strategy Configuration
# ------------------------------------------------------------------------------

variable "active_environment" {
  description = "Currently active environment (blue or green)"
  type        = string
  default     = "blue"
  validation {
    condition     = contains(["blue", "green"], var.active_environment)
    error_message = "Active environment must be either 'blue' or 'green'."
  }
}

variable "test_traffic_port" {
  description = "Port for routing test traffic to inactive environment"
  type        = number
  default     = 8080
}

# ------------------------------------------------------------------------------
# Canary Deployment Configuration
# ------------------------------------------------------------------------------

variable "enable_canary_deployment" {
  description = "Enable canary deployment with weighted traffic distribution"
  type        = bool
  default     = false
}

variable "canary_weight_active" {
  description = "Traffic weight percentage for active environment (0-100)"
  type        = number
  default     = 90
  validation {
    condition     = var.canary_weight_active >= 0 && var.canary_weight_active <= 100
    error_message = "Canary weight must be between 0 and 100."
  }
}

variable "canary_weight_inactive" {
  description = "Traffic weight percentage for inactive environment (0-100)"
  type        = number
  default     = 10
  validation {
    condition     = var.canary_weight_inactive >= 0 && var.canary_weight_inactive <= 100
    error_message = "Canary weight must be between 0 and 100."
  }
}

# ------------------------------------------------------------------------------
# Auto Scaling Configuration
# ------------------------------------------------------------------------------

variable "enable_autoscaling" {
  description = "Enable Auto Scaling group attachment"
  type        = bool
  default     = false
}

variable "blue_autoscaling_group_name" {
  description = "Name of the Auto Scaling group for blue environment"
  type        = string
  default     = ""
}

variable "green_autoscaling_group_name" {
  description = "Name of the Auto Scaling group for green environment"
  type        = string
  default     = ""
}

# ------------------------------------------------------------------------------
# Monitoring & Alerting Configuration
# ------------------------------------------------------------------------------

variable "enable_cloudwatch_dashboard" {
  description = "Enable CloudWatch dashboard for deployment monitoring"
  type        = bool
  default     = true
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms"
  type        = string
  default     = ""
}

variable "unhealthy_host_alarm_threshold" {
  description = "Threshold for unhealthy host count alarm"
  type        = number
  default     = 1
}

variable "response_time_threshold" {
  description = "Target response time threshold in seconds for alarms"
  type        = number
  default     = 1.0
}
