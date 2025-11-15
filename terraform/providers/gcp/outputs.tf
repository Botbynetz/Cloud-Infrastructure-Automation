# ==============================================================================
# GCP Provider Outputs
# ==============================================================================

# Project Information
output "project_id" {
  description = "GCP Project ID"
  value       = data.google_project.current.project_id
}

output "project_number" {
  description = "GCP Project Number"
  value       = data.google_project.current.number
}

output "project_name" {
  description = "GCP Project Name"
  value       = data.google_project.current.name
}

# ==============================================================================
# Networking Outputs
# ==============================================================================

output "vpc_network_id" {
  description = "VPC Network ID"
  value       = google_compute_network.main.id
}

output "vpc_network_name" {
  description = "VPC Network name"
  value       = google_compute_network.main.name
}

output "vpc_network_self_link" {
  description = "VPC Network self link"
  value       = google_compute_network.main.self_link
}

output "app_subnet_id" {
  description = "Application subnet ID"
  value       = google_compute_subnetwork.app.id
}

output "app_subnet_cidr" {
  description = "Application subnet CIDR range"
  value       = google_compute_subnetwork.app.ip_cidr_range
}

output "data_subnet_id" {
  description = "Data subnet ID"
  value       = google_compute_subnetwork.data.id
}

output "data_subnet_cidr" {
  description = "Data subnet CIDR range"
  value       = google_compute_subnetwork.data.ip_cidr_range
}

output "nat_ip_addresses" {
  description = "NAT gateway IP addresses"
  value       = google_compute_router_nat.main.nat_ips
}

# ==============================================================================
# Storage Outputs
# ==============================================================================

output "storage_bucket_name" {
  description = "Cloud Storage bucket name"
  value       = google_storage_bucket.main.name
}

output "storage_bucket_url" {
  description = "Cloud Storage bucket URL"
  value       = google_storage_bucket.main.url
}

output "storage_bucket_self_link" {
  description = "Cloud Storage bucket self link"
  value       = google_storage_bucket.main.self_link
}

# ==============================================================================
# KMS Outputs
# ==============================================================================

output "kms_keyring_id" {
  description = "KMS keyring ID"
  value       = var.enable_cmek ? google_kms_key_ring.main[0].id : null
}

output "kms_storage_key_id" {
  description = "KMS storage encryption key ID"
  value       = var.enable_cmek ? google_kms_crypto_key.storage[0].id : null
}

# ==============================================================================
# Secret Manager Outputs
# ==============================================================================

output "secret_manager_secret_id" {
  description = "Secret Manager secret ID"
  value       = google_secret_manager_secret.main.secret_id
}

output "secret_manager_secret_name" {
  description = "Secret Manager secret name"
  value       = google_secret_manager_secret.main.name
}

# ==============================================================================
# Cloud SQL Outputs
# ==============================================================================

output "cloud_sql_instance_name" {
  description = "Cloud SQL instance name"
  value       = var.enable_cloud_sql ? google_sql_database_instance.main[0].name : null
}

output "cloud_sql_connection_name" {
  description = "Cloud SQL instance connection name"
  value       = var.enable_cloud_sql ? google_sql_database_instance.main[0].connection_name : null
}

output "cloud_sql_private_ip" {
  description = "Cloud SQL private IP address"
  value       = var.enable_cloud_sql ? google_sql_database_instance.main[0].private_ip_address : null
}

output "cloud_sql_self_link" {
  description = "Cloud SQL instance self link"
  value       = var.enable_cloud_sql ? google_sql_database_instance.main[0].self_link : null
}

# ==============================================================================
# Artifact Registry Outputs
# ==============================================================================

output "artifact_registry_id" {
  description = "Artifact Registry repository ID"
  value       = var.enable_artifact_registry ? google_artifact_registry_repository.main[0].id : null
}

output "artifact_registry_name" {
  description = "Artifact Registry repository name"
  value       = var.enable_artifact_registry ? google_artifact_registry_repository.main[0].name : null
}

output "artifact_registry_location" {
  description = "Artifact Registry repository location"
  value       = var.enable_artifact_registry ? google_artifact_registry_repository.main[0].location : null
}

# ==============================================================================
# Monitoring Outputs
# ==============================================================================

output "notification_channel_ids" {
  description = "Monitoring notification channel IDs"
  value       = var.enable_monitoring_alerts ? [google_monitoring_notification_channel.email[0].id] : []
}

output "alert_policy_ids" {
  description = "Alert policy IDs"
  value       = var.enable_monitoring_alerts ? [google_monitoring_alert_policy.high_cpu[0].id] : []
}

# ==============================================================================
# Logging Outputs
# ==============================================================================

output "log_sink_name" {
  description = "Log sink name"
  value       = google_logging_project_sink.main.name
}

output "log_sink_writer_identity" {
  description = "Log sink writer identity"
  value       = google_logging_project_sink.main.writer_identity
  sensitive   = true
}

# ==============================================================================
# Summary Output
# ==============================================================================

output "gcp_infrastructure_summary" {
  description = "Summary of GCP infrastructure components"
  value = {
    project = {
      id     = data.google_project.current.project_id
      number = data.google_project.current.number
      name   = data.google_project.current.name
    }
    networking = {
      vpc_name       = google_compute_network.main.name
      app_subnet     = google_compute_subnetwork.app.ip_cidr_range
      data_subnet    = google_compute_subnetwork.data.ip_cidr_range
      nat_configured = true
    }
    storage = {
      bucket_name = google_storage_bucket.main.name
      cmek_enabled = var.enable_cmek
    }
    database = {
      enabled       = var.enable_cloud_sql
      instance_name = var.enable_cloud_sql ? google_sql_database_instance.main[0].name : null
    }
    container_registry = {
      enabled       = var.enable_artifact_registry
      repository_id = var.enable_artifact_registry ? google_artifact_registry_repository.main[0].repository_id : null
    }
    monitoring = {
      alerts_enabled = var.enable_monitoring_alerts
      log_sink_configured = true
    }
  }
}
