# =============================================================================
# STEP 7: OBSERVABILITY VARIABLES
# =============================================================================

variable "environment" {
  description = "Environment name (dev, staging, prod, dr)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

# =============================================================================
# EKS CONFIGURATION
# =============================================================================

variable "use_existing_eks" {
  description = "Use existing EKS cluster instead of creating new one"
  type        = bool
  default     = true
}

variable "create_dedicated_cluster" {
  description = "Create dedicated EKS cluster for observability"
  type        = bool
  default     = false
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "eks_public_access" {
  description = "Enable public access to EKS API endpoint"
  type        = bool
  default     = false
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access EKS API endpoint"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

# =============================================================================
# NODE GROUP CONFIGURATION
# =============================================================================

variable "node_capacity_type" {
  description = "Capacity type for EKS nodes (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
  
  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "Node capacity type must be ON_DEMAND or SPOT."
  }
}

variable "node_instance_types" {
  description = "Instance types for EKS node group"
  type        = list(string)
  default     = ["t3.large", "t3.xlarge"]
}

variable "node_desired_size" {
  description = "Desired number of nodes in the EKS node group"
  type        = number
  default     = 3
}

variable "node_max_size" {
  description = "Maximum number of nodes in the EKS node group"
  type        = number
  default     = 6
}

variable "node_min_size" {
  description = "Minimum number of nodes in the EKS node group"
  type        = number
  default     = 1
}

# =============================================================================
# PROMETHEUS CONFIGURATION
# =============================================================================

variable "prometheus_chart_version" {
  description = "Version of kube-prometheus-stack Helm chart"
  type        = string
  default     = "55.5.0"
}

variable "prometheus_operator_version" {
  description = "Version of prometheus-operator-crds Helm chart"
  type        = string
  default     = "8.0.0"
}

variable "prometheus_retention" {
  description = "Prometheus data retention period"
  type        = string
  default     = "30d"
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus"
  type        = string
  default     = "100Gi"
}

variable "alertmanager_retention" {
  description = "Alertmanager data retention period"
  type        = string
  default     = "120h"
}

# =============================================================================
# GRAFANA CONFIGURATION
# =============================================================================

variable "grafana_admin_password" {
  description = "Admin password for Grafana (use AWS Secrets Manager in production)"
  type        = string
  sensitive   = true
}

variable "enable_ingress" {
  description = "Enable ingress for Grafana"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Domain name for Grafana ingress"
  type        = string
  default     = ""
}

variable "ssl_certificate_arn" {
  description = "ARN of SSL certificate for ingress"
  type        = string
  default     = ""
}

# =============================================================================
# ALERTING CONFIGURATION
# =============================================================================

variable "slack_webhook_url" {
  description = "Slack webhook URL for alerts"
  type        = string
  sensitive   = true
  default     = ""
}

variable "slack_channel" {
  description = "Slack channel for alerts"
  type        = string
  default     = "#devops-alerts"
}

variable "pagerduty_service_key" {
  description = "PagerDuty service key for critical alerts"
  type        = string
  sensitive   = true
  default     = ""
}

# =============================================================================
# COST MONITORING (Integration with STEP 6)
# =============================================================================

variable "cost_threshold_dev" {
  description = "Cost threshold for dev environment (from STEP 6)"
  type        = number
  default     = 500
}

variable "cost_threshold_staging" {
  description = "Cost threshold for staging environment (from STEP 6)"
  type        = number
  default     = 2000
}

variable "cost_threshold_prod" {
  description = "Cost threshold for prod environment (from STEP 6)"
  type        = number
  default     = 10000
}

variable "cost_threshold_dr" {
  description = "Cost threshold for dr environment (from STEP 6)"
  type        = number
  default     = 10000
}

# =============================================================================
# ADDITIONAL MONITORING COMPONENTS
# =============================================================================

variable "cloudwatch_exporter_version" {
  description = "Version of CloudWatch exporter Helm chart"
  type        = string
  default     = "0.25.3"
}

variable "enable_node_exporter" {
  description = "Enable Node Exporter for system metrics"
  type        = bool
  default     = true
}

variable "node_exporter_version" {
  description = "Version of Node Exporter Helm chart"
  type        = string
  default     = "4.24.0"
}

variable "enable_thanos" {
  description = "Enable Thanos for long-term storage"
  type        = bool
  default     = false
}

variable "thanos_chart_version" {
  description = "Version of Thanos Helm chart"
  type        = string
  default     = "12.13.0"
}

# =============================================================================
# LOG AGGREGATION
# =============================================================================

variable "enable_fluent_bit" {
  description = "Enable Fluent Bit for log collection"
  type        = bool
  default     = true
}

variable "fluent_bit_chart_version" {
  description = "Version of Fluent Bit Helm chart"
  type        = string
  default     = "0.39.0"
}

variable "enable_elasticsearch" {
  description = "Enable Elasticsearch for log storage"
  type        = bool
  default     = false
}

variable "elasticsearch_chart_version" {
  description = "Version of Elasticsearch Helm chart"
  type        = string
  default     = "8.5.1"
}

variable "elasticsearch_storage_size" {
  description = "Storage size for Elasticsearch"
  type        = string
  default     = "200Gi"
}

# =============================================================================
# DISTRIBUTED TRACING
# =============================================================================

variable "enable_jaeger" {
  description = "Enable Jaeger for distributed tracing"
  type        = bool
  default     = true
}

variable "jaeger_chart_version" {
  description = "Version of Jaeger Helm chart"
  type        = string
  default     = "0.71.2"
}

# =============================================================================
# SERVICE LEVEL OBJECTIVES (SLO)
# =============================================================================

variable "slo_availability_target" {
  description = "SLO availability target percentage"
  type        = number
  default     = 99.9
  
  validation {
    condition     = var.slo_availability_target >= 90 && var.slo_availability_target <= 100
    error_message = "SLO availability target must be between 90 and 100."
  }
}

variable "slo_latency_target" {
  description = "SLO latency target in milliseconds"
  type        = number
  default     = 500
}

variable "slo_error_rate_target" {
  description = "SLO error rate target percentage"
  type        = number
  default     = 1.0
}

# =============================================================================
# DATA RETENTION
# =============================================================================

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "long_term_retention_days" {
  description = "Long-term storage retention in days (S3)"
  type        = number
  default     = 2555  # 7 years
}

# =============================================================================
# MONITORING TARGETS
# =============================================================================

variable "enable_aws_lb_monitoring" {
  description = "Enable monitoring for AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "enable_grafana_dashboards" {
  description = "Enable predefined Grafana dashboards"
  type        = bool
  default     = true
}

# =============================================================================
# SECURITY & COMPLIANCE
# =============================================================================

variable "enable_network_policies" {
  description = "Enable Kubernetes network policies"
  type        = bool
  default     = true
}

variable "enable_pod_security_policies" {
  description = "Enable Pod Security Policies"
  type        = bool
  default     = true
}

# =============================================================================
# BACKUP AND DISASTER RECOVERY
# =============================================================================

variable "enable_velero" {
  description = "Enable Velero for backup and disaster recovery"
  type        = bool
  default     = false
}

variable "velero_chart_version" {
  description = "Version of Velero Helm chart"
  type        = string
  default     = "5.1.0"
}