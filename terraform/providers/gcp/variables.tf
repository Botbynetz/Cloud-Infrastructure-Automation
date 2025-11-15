# ==============================================================================
# GCP Provider Variables
# ==============================================================================

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
  
  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]$", var.gcp_region))
    error_message = "GCP region must be in format like us-central1, europe-west1, etc."
  }
}

variable "gcp_zone" {
  description = "GCP zone for zonal resources"
  type        = string
  default     = "us-central1-a"
}

variable "gcp_credentials_file" {
  description = "Path to GCP service account credentials JSON file (optional if using ADC)"
  type        = string
  default     = ""
}

# ==============================================================================
# Project Configuration
# ==============================================================================

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "cloud-infra"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    project    = "cloud-infrastructure-automation"
    managed_by = "terraform"
  }
}

# ==============================================================================
# Networking Configuration
# ==============================================================================

variable "app_subnet_cidr" {
  description = "CIDR block for application subnet"
  type        = string
  default     = "10.2.1.0/24"
}

variable "data_subnet_cidr" {
  description = "CIDR block for data subnet"
  type        = string
  default     = "10.2.2.0/24"
}

variable "services_subnet_cidr" {
  description = "CIDR block for GKE services (secondary range)"
  type        = string
  default     = "10.2.16.0/20"
}

variable "pods_subnet_cidr" {
  description = "CIDR block for GKE pods (secondary range)"
  type        = string
  default     = "10.2.32.0/20"
}

variable "admin_source_ip" {
  description = "Source IP address for SSH access"
  type        = string
  default     = "0.0.0.0/0"
}

# ==============================================================================
# Storage Configuration
# ==============================================================================

variable "force_destroy_bucket" {
  description = "Allow destruction of bucket even with objects"
  type        = bool
  default     = false
}

variable "enable_cmek" {
  description = "Enable Customer-Managed Encryption Keys"
  type        = bool
  default     = false
}

# ==============================================================================
# Database Configuration
# ==============================================================================

variable "enable_cloud_sql" {
  description = "Enable Cloud SQL instance"
  type        = bool
  default     = false
}

variable "cloud_sql_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
  
  validation {
    condition = can(regex("^db-(f1-micro|g1-small|custom-[0-9]+-[0-9]+|n1-standard-[0-9]+|n1-highmem-[0-9]+|n1-highcpu-[0-9]+)$", var.cloud_sql_tier))
    error_message = "Cloud SQL tier must be a valid GCP machine type."
  }
}

variable "cloud_sql_disk_size" {
  description = "Cloud SQL disk size in GB"
  type        = number
  default     = 10
  
  validation {
    condition     = var.cloud_sql_disk_size >= 10 && var.cloud_sql_disk_size <= 65536
    error_message = "Cloud SQL disk size must be between 10 and 65536 GB."
  }
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for Cloud SQL"
  type        = bool
  default     = true
}

# ==============================================================================
# Container Registry Configuration
# ==============================================================================

variable "enable_artifact_registry" {
  description = "Enable Artifact Registry for container images"
  type        = bool
  default     = true
}

# ==============================================================================
# Monitoring Configuration
# ==============================================================================

variable "enable_monitoring_alerts" {
  description = "Enable Cloud Monitoring alerts"
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Email address for monitoring alerts"
  type        = string
  default     = "admin@example.com"
}

# ==============================================================================
# Security Configuration
# ==============================================================================

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "enable_private_google_access" {
  description = "Enable Private Google Access for subnets"
  type        = bool
  default     = true
}
