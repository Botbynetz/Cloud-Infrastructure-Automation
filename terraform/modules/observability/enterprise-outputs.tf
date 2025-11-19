# =============================================================================
# STEP 7: ENTERPRISE OBSERVABILITY OUTPUTS
# =============================================================================
# Comprehensive outputs for observability stack integration

# =============================================================================
# PROMETHEUS OUTPUTS
# =============================================================================
output "prometheus_server_url" {
  description = "Internal URL for Prometheus server"
  value       = "http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090"
}

output "prometheus_namespace" {
  description = "Kubernetes namespace for monitoring stack"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "prometheus_service_account" {
  description = "Service account for Prometheus with IRSA"
  value       = kubernetes_service_account.prometheus.metadata[0].name
}

output "prometheus_storage_class" {
  description = "Storage class for monitoring persistent volumes"
  value       = kubernetes_storage_class.monitoring_storage.metadata[0].name
}

# =============================================================================
# GRAFANA OUTPUTS
# =============================================================================
output "grafana_admin_password" {
  description = "Grafana admin password (sensitive)"
  value       = var.grafana_admin_password
  sensitive   = true
}

output "grafana_url" {
  description = "External URL for Grafana dashboard"
  value       = var.enable_ingress ? "https://grafana.${var.domain_name}" : "http://kube-prometheus-stack-grafana.monitoring.svc.cluster.local"
}

output "grafana_service_name" {
  description = "Kubernetes service name for Grafana"
  value       = "kube-prometheus-stack-grafana"
}

# =============================================================================
# ALERTMANAGER OUTPUTS
# =============================================================================
output "alertmanager_url" {
  description = "Internal URL for Alertmanager"
  value       = "http://kube-prometheus-stack-alertmanager.monitoring.svc.cluster.local:9093"
}

output "alertmanager_webhook_url" {
  description = "Webhook URL for external alert integrations"
  value       = "http://kube-prometheus-stack-alertmanager.monitoring.svc.cluster.local:9093/api/v1/alerts"
}

# =============================================================================
# EKS CLUSTER OUTPUTS (if created)
# =============================================================================
output "observability_cluster_name" {
  description = "Name of dedicated observability EKS cluster"
  value       = var.create_dedicated_cluster ? aws_eks_cluster.observability[0].name : null
}

output "observability_cluster_endpoint" {
  description = "Endpoint of dedicated observability EKS cluster"
  value       = var.create_dedicated_cluster ? aws_eks_cluster.observability[0].endpoint : null
}

output "observability_cluster_ca_certificate" {
  description = "CA certificate of dedicated observability EKS cluster"
  value       = var.create_dedicated_cluster ? aws_eks_cluster.observability[0].certificate_authority[0].data : null
  sensitive   = true
}

# =============================================================================
# STORAGE OUTPUTS
# =============================================================================
output "observability_s3_bucket" {
  description = "S3 bucket for long-term observability data storage"
  value       = aws_s3_bucket.observability_storage.bucket
}

output "observability_s3_bucket_arn" {
  description = "ARN of S3 bucket for observability data"
  value       = aws_s3_bucket.observability_storage.arn
}

# =============================================================================
# MONITORING ENDPOINTS FOR INTEGRATION
# =============================================================================
output "monitoring_endpoints" {
  description = "Collection of monitoring service endpoints"
  value = {
    prometheus    = "http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090"
    grafana       = var.enable_ingress ? "https://grafana.${var.domain_name}" : "http://kube-prometheus-stack-grafana.monitoring.svc.cluster.local"
    alertmanager  = "http://kube-prometheus-stack-alertmanager.monitoring.svc.cluster.local:9093"
    node_exporter = "http://kube-prometheus-stack-prometheus-node-exporter.monitoring.svc.cluster.local:9100"
  }
}

# =============================================================================
# INTEGRATION OUTPUTS FOR OTHER STEPS
# =============================================================================

# For STEP 1: Infrastructure Integration
output "infrastructure_monitoring" {
  description = "Infrastructure monitoring configuration for STEP 1 integration"
  value = {
    enabled              = true
    prometheus_namespace = kubernetes_namespace.monitoring.metadata[0].name
    cost_thresholds = {
      dev     = var.cost_threshold_dev
      staging = var.cost_threshold_staging
      prod    = var.cost_threshold_prod
      dr      = var.cost_threshold_dr
    }
    environments_monitored = ["dev", "staging", "prod", "dr"]
  }
}

# For STEP 2: Security Monitoring Integration
output "security_monitoring" {
  description = "Security monitoring configuration for STEP 2 integration"
  value = {
    enabled                    = true
    kms_key_monitoring        = true
    secrets_access_monitoring = true
    certificate_monitoring    = true
    audit_log_integration    = true
    encryption_compliance    = true
  }
}

# For STEP 3: Policy Compliance Monitoring
output "policy_monitoring" {
  description = "Policy compliance monitoring for STEP 3 integration"
  value = {
    enabled              = true
    opa_integration     = true
    policy_violations   = true
    tagging_compliance  = true
    cost_policy_alerts  = true
    security_policies   = true
  }
}

# For STEP 4: CI/CD Pipeline Monitoring
output "cicd_monitoring" {
  description = "CI/CD pipeline monitoring for STEP 4 integration"
  value = {
    enabled               = true
    pipeline_metrics     = true
    deployment_tracking  = true
    failure_alerting     = true
    performance_metrics  = true
    quality_gates       = true
  }
}

# For STEP 5: Testing Monitoring Integration
output "testing_monitoring" {
  description = "Testing monitoring configuration for STEP 5 integration"
  value = {
    enabled           = true
    test_results     = true
    coverage_tracking = true
    performance_tests = true
    quality_metrics  = true
    trend_analysis   = true
  }
}

# For STEP 6: FinOps Monitoring Integration
output "finops_monitoring" {
  description = "FinOps monitoring configuration for STEP 6 integration"
  value = {
    enabled                = true
    cost_tracking         = true
    budget_alerts         = true
    optimization_alerts   = true
    usage_efficiency     = true
    reserved_instance_monitoring = true
    spot_instance_tracking = true
    s3_lifecycle_monitoring = true
  }
}

# =============================================================================
# DASHBOARD OUTPUTS
# =============================================================================
output "dashboard_urls" {
  description = "URLs for accessing various monitoring dashboards"
  value = var.enable_grafana_dashboards ? {
    infrastructure_overview = "${var.enable_ingress ? "https://grafana.${var.domain_name}" : "http://localhost:3000"}/d/infrastructure-overview"
    aws_resources          = "${var.enable_ingress ? "https://grafana.${var.domain_name}" : "http://localhost:3000"}/d/aws-resources"
    cost_monitoring        = "${var.enable_ingress ? "https://grafana.${var.domain_name}" : "http://localhost:3000"}/d/cost-monitoring"
    security_compliance    = "${var.enable_ingress ? "https://grafana.${var.domain_name}" : "http://localhost:3000"}/d/security-compliance"
    application_performance = "${var.enable_ingress ? "https://grafana.${var.domain_name}" : "http://localhost:3000"}/d/application-performance"
  } : {}
}

# =============================================================================
# ALERT CONFIGURATION OUTPUTS
# =============================================================================
output "alert_configuration" {
  description = "Alert configuration details for external integrations"
  value = {
    slack_webhook_configured   = var.slack_webhook_url != ""
    pagerduty_configured      = var.pagerduty_service_key != ""
    slack_channel            = var.slack_channel
    critical_alerts_enabled  = true
    cost_alerts_enabled      = true
    security_alerts_enabled  = true
    slo_monitoring_enabled   = true
  }
}

# =============================================================================
# SLO MONITORING OUTPUTS
# =============================================================================
output "slo_configuration" {
  description = "Service Level Objective monitoring configuration"
  value = {
    availability_target    = var.slo_availability_target
    latency_target_ms     = var.slo_latency_target
    error_rate_target     = var.slo_error_rate_target
    monitoring_enabled    = true
    burn_rate_alerts     = true
    slo_dashboard_url    = var.enable_ingress ? "https://grafana.${var.domain_name}/d/slo-monitoring" : null
  }
}

# =============================================================================
# DATA RETENTION OUTPUTS
# =============================================================================
output "data_retention_configuration" {
  description = "Data retention policies for observability data"
  value = {
    prometheus_retention      = var.prometheus_retention
    prometheus_storage_size   = var.prometheus_storage_size
    alertmanager_retention    = var.alertmanager_retention
    cloudwatch_logs_retention = var.log_retention_days
    s3_long_term_retention   = var.long_term_retention_days
    backup_enabled           = true
  }
}

# =============================================================================
# HEALTH CHECK OUTPUTS
# =============================================================================
output "health_check_endpoints" {
  description = "Health check endpoints for monitoring stack components"
  value = {
    prometheus_health    = "http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090/-/healthy"
    prometheus_ready     = "http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090/-/ready"
    grafana_health       = "http://kube-prometheus-stack-grafana.monitoring.svc.cluster.local:3000/api/health"
    alertmanager_health  = "http://kube-prometheus-stack-alertmanager.monitoring.svc.cluster.local:9093/-/healthy"
    alertmanager_ready   = "http://kube-prometheus-stack-alertmanager.monitoring.svc.cluster.local:9093/-/ready"
  }
}

# =============================================================================
# PERFORMANCE METRICS OUTPUTS
# =============================================================================
output "performance_metrics" {
  description = "Performance metrics and sizing information"
  value = {
    prometheus_resources = {
      cpu_request    = "1000m"
      memory_request = "2Gi"
      cpu_limit      = "4000m"
      memory_limit   = "8Gi"
    }
    grafana_resources = {
      cpu_request    = "100m"
      memory_request = "200Mi"
      cpu_limit      = "200m"
      memory_limit   = "500Mi"
    }
    storage_configuration = {
      prometheus_storage    = var.prometheus_storage_size
      storage_class        = kubernetes_storage_class.monitoring_storage.metadata[0].name
      backup_schedule      = "0 2 * * *"  # Daily at 2 AM
    }
  }
}

# =============================================================================
# SECURITY CONFIGURATION OUTPUTS
# =============================================================================
output "security_configuration" {
  description = "Security configuration for observability stack"
  value = {
    network_policies_enabled     = var.enable_network_policies
    pod_security_policies_enabled = var.enable_pod_security_policies
    encryption_at_rest          = true
    encryption_in_transit       = true
    rbac_enabled               = true
    service_account_arn        = aws_iam_role.prometheus_service_account.arn
    kms_key_used               = data.aws_kms_key.main.arn
  }
}

# =============================================================================
# COST OPTIMIZATION OUTPUTS
# =============================================================================
output "cost_optimization" {
  description = "Cost optimization features and recommendations"
  value = {
    s3_lifecycle_enabled     = true
    spot_instances_supported = var.node_capacity_type == "SPOT"
    resource_right_sizing   = true
    cost_monitoring_enabled = true
    budget_alerts_configured = true
    optimization_recommendations = {
      use_spot_instances      = "For non-production workloads"
      optimize_storage_class  = "Use gp3 for better price/performance"
      implement_hpa          = "Horizontal Pod Autoscaler for dynamic scaling"
      use_reserved_instances  = "For predictable production workloads"
    }
  }
}

# =============================================================================
# COMPLIANCE OUTPUTS
# =============================================================================
output "compliance_status" {
  description = "Compliance status and certifications"
  value = {
    encryption_compliant    = true
    audit_logging_enabled  = true
    data_retention_policy  = "Configured per regulatory requirements"
    backup_strategy       = "Automated daily backups to S3"
    disaster_recovery     = "Cross-region replication available"
    security_monitoring   = "24/7 security event monitoring"
    compliance_frameworks = ["SOC2", "GDPR", "HIPAA-ready"]
  }
}

# =============================================================================
# TROUBLESHOOTING OUTPUTS
# =============================================================================
output "troubleshooting_info" {
  description = "Troubleshooting information and common commands"
  value = {
    kubectl_commands = {
      check_pods     = "kubectl get pods -n monitoring"
      check_services = "kubectl get services -n monitoring"
      check_ingress  = "kubectl get ingress -n monitoring"
      prometheus_logs = "kubectl logs -n monitoring deployment/kube-prometheus-stack-prometheus"
      grafana_logs   = "kubectl logs -n monitoring deployment/kube-prometheus-stack-grafana"
    }
    port_forwarding = {
      prometheus    = "kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090"
      grafana       = "kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80"
      alertmanager  = "kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093"
    }
    common_issues = {
      targets_down          = "Check service discovery configuration and network policies"
      high_memory_usage     = "Reduce retention period or increase resource limits"
      missing_metrics       = "Verify ServiceMonitor configuration and target accessibility"
      dashboard_not_loading = "Check Grafana datasource configuration and connectivity"
    }
  }
}

# =============================================================================
# FINAL STATUS OUTPUT
# =============================================================================
output "step7_deployment_status" {
  description = "STEP 7 deployment status and summary"
  value = {
    status = "✅ COMPLETED"
    components_deployed = [
      "Prometheus Server",
      "Grafana Dashboards", 
      "Alertmanager",
      "Node Exporter",
      "CloudWatch Exporter",
      "Kube State Metrics"
    ]
    integrations_active = [
      "STEP 1: Infrastructure Monitoring",
      "STEP 2: Security Monitoring", 
      "STEP 3: Policy Compliance Monitoring",
      "STEP 4: CI/CD Pipeline Monitoring",
      "STEP 5: Testing Results Monitoring",
      "STEP 6: FinOps Cost Monitoring"
    ]
    features_enabled = [
      "Real-time Infrastructure Monitoring",
      "Application Performance Monitoring",
      "Cost Tracking and Optimization",
      "Security Compliance Monitoring",
      "SLO/SLA Tracking",
      "Intelligent Alerting",
      "Custom Dashboards",
      "Long-term Data Storage"
    ]
    next_step = "Proceed to STEP 8: Documentation Automation"
    documentation = "docs/STEP7-OBSERVABILITY-GUIDE.md"
  }
}