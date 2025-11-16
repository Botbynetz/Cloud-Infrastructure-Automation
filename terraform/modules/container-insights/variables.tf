# ==============================================================================
# CloudWatch Container Insights Module Variables
# ==============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
  validation {
    condition     = can(regex("^(dev|staging|production)$", var.environment))
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# ECS Container Insights Configuration
# ==============================================================================

variable "enable_ecs_insights" {
  description = "Enable Container Insights for ECS"
  type        = bool
  default     = false
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = ""
}

variable "ecs_capacity_providers" {
  description = "List of ECS capacity providers"
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

variable "deploy_fluent_bit" {
  description = "Deploy Fluent Bit for log collection"
  type        = bool
  default     = true
}

variable "fluent_bit_cpu" {
  description = "CPU units for Fluent Bit task (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "fluent_bit_memory" {
  description = "Memory for Fluent Bit task in MB"
  type        = number
  default     = 512
}

variable "fluent_bit_desired_count" {
  description = "Desired count of Fluent Bit tasks"
  type        = number
  default     = 1
}

variable "ecs_subnet_ids" {
  description = "Subnet IDs for ECS tasks"
  type        = list(string)
  default     = null
}

variable "ecs_security_group_ids" {
  description = "Security group IDs for ECS tasks"
  type        = list(string)
  default     = []
}

# ==============================================================================
# EKS Container Insights Configuration
# ==============================================================================

variable "enable_eks_insights" {
  description = "Enable Container Insights for EKS"
  type        = bool
  default     = false
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = ""
}

variable "eks_cluster_role_name" {
  description = "Name of the EKS cluster IAM role"
  type        = string
  default     = ""
}

# ==============================================================================
# CloudWatch Configuration
# ==============================================================================

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch Logs retention period."
  }
}

variable "enable_log_encryption" {
  description = "Enable KMS encryption for CloudWatch Logs"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for log encryption"
  type        = string
  default     = null
}

# ==============================================================================
# Alarm Configuration
# ==============================================================================

variable "enable_container_alarms" {
  description = "Enable CloudWatch alarms for container metrics"
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarms trigger"
  type        = list(string)
  default     = []
}

variable "cpu_utilization_threshold" {
  description = "CPU utilization threshold percentage"
  type        = number
  default     = 80
  validation {
    condition     = var.cpu_utilization_threshold >= 0 && var.cpu_utilization_threshold <= 100
    error_message = "CPU utilization threshold must be between 0 and 100."
  }
}

variable "memory_utilization_threshold" {
  description = "Memory utilization threshold percentage"
  type        = number
  default     = 80
  validation {
    condition     = var.memory_utilization_threshold >= 0 && var.memory_utilization_threshold <= 100
    error_message = "Memory utilization threshold must be between 0 and 100."
  }
}

variable "container_restart_threshold" {
  description = "Number of container restarts to trigger alarm"
  type        = number
  default     = 5
  validation {
    condition     = var.container_restart_threshold > 0
    error_message = "Container restart threshold must be greater than 0."
  }
}

# ==============================================================================
# Dashboard Configuration
# ==============================================================================

variable "enable_container_dashboard" {
  description = "Create CloudWatch dashboard for container metrics"
  type        = bool
  default     = true
}

# ==============================================================================
# Advanced Configuration
# ==============================================================================

variable "enable_enhanced_monitoring" {
  description = "Enable enhanced container monitoring with additional metrics"
  type        = bool
  default     = true
}

variable "custom_metric_namespaces" {
  description = "Additional CloudWatch metric namespaces to monitor"
  type        = list(string)
  default     = []
}
