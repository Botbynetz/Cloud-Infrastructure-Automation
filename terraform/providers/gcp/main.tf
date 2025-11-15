# ==============================================================================
# Google Cloud Provider Configuration
# ==============================================================================
# Multi-cloud infrastructure - GCP provider setup

terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.7"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.7"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
  
  # Authentication via service account key or Application Default Credentials
  # credentials = file(var.gcp_credentials_file)
}

provider "google-beta" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}

# ==============================================================================
# Data Sources
# ==============================================================================

data "google_project" "current" {
  project_id = var.gcp_project_id
}

data "google_compute_zones" "available" {
  region = var.gcp_region
}

# ==============================================================================
# VPC Network
# ==============================================================================

resource "google_compute_network" "main" {
  name                    = "${var.project_name}-vpc"
  auto_create_subnetworks = false
  mtu                     = 1460
  
  routing_mode = "REGIONAL"
}

# Application subnet
resource "google_compute_subnetwork" "app" {
  name          = "${var.project_name}-app-subnet"
  ip_cidr_range = var.app_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.main.id
  
  private_ip_google_access = true
  
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
  
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_subnet_cidr
  }
  
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_subnet_cidr
  }
}

# Data subnet
resource "google_compute_subnetwork" "data" {
  name          = "${var.project_name}-data-subnet"
  ip_cidr_range = var.data_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.main.id
  
  private_ip_google_access = true
}

# ==============================================================================
# Firewall Rules
# ==============================================================================

# Allow internal communication
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.project_name}-allow-internal"
  network = google_compute_network.main.name
  
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  
  allow {
    protocol = "icmp"
  }
  
  source_ranges = [var.app_subnet_cidr, var.data_subnet_cidr]
  priority      = 1000
}

# Allow HTTP/HTTPS from internet
resource "google_compute_firewall" "allow_http_https" {
  name    = "${var.project_name}-allow-http-https"
  network = google_compute_network.main.name
  
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
  priority      = 1000
}

# Allow SSH from specific IP
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.project_name}-allow-ssh"
  network = google_compute_network.main.name
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  
  source_ranges = [var.admin_source_ip]
  target_tags   = ["ssh-enabled"]
  priority      = 1000
}

# ==============================================================================
# Cloud NAT
# ==============================================================================

resource "google_compute_router" "main" {
  name    = "${var.project_name}-router"
  region  = var.gcp_region
  network = google_compute_network.main.id
}

resource "google_compute_router_nat" "main" {
  name                               = "${var.project_name}-nat"
  router                             = google_compute_router.main.name
  region                             = google_compute_router.main.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# ==============================================================================
# Cloud Storage
# ==============================================================================

resource "google_storage_bucket" "main" {
  name          = "${var.gcp_project_id}-${var.project_name}-storage"
  location      = var.gcp_region
  force_destroy = var.force_destroy_bucket
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }
  
  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  }
  
  encryption {
    default_kms_key_name = var.enable_cmek ? google_kms_crypto_key.storage[0].id : null
  }
  
  labels = merge(
    var.common_labels,
    {
      environment = var.environment
      managed_by  = "terraform"
    }
  )
}

# ==============================================================================
# Cloud KMS (Customer-Managed Encryption Keys)
# ==============================================================================

resource "google_kms_key_ring" "main" {
  count    = var.enable_cmek ? 1 : 0
  name     = "${var.project_name}-keyring"
  location = var.gcp_region
}

resource "google_kms_crypto_key" "storage" {
  count           = var.enable_cmek ? 1 : 0
  name            = "${var.project_name}-storage-key"
  key_ring        = google_kms_key_ring.main[0].id
  rotation_period = "7776000s" # 90 days
  
  lifecycle {
    prevent_destroy = true
  }
}

# ==============================================================================
# Secret Manager
# ==============================================================================

resource "google_secret_manager_secret" "main" {
  secret_id = "${var.project_name}-secrets"
  
  replication {
    auto {}
  }
  
  labels = var.common_labels
}

# ==============================================================================
# Cloud SQL (Optional)
# ==============================================================================

resource "google_sql_database_instance" "main" {
  count            = var.enable_cloud_sql ? 1 : 0
  name             = "${var.project_name}-db"
  database_version = "POSTGRES_15"
  region           = var.gcp_region
  
  settings {
    tier              = var.cloud_sql_tier
    availability_type = "REGIONAL"
    disk_size         = var.cloud_sql_disk_size
    disk_type         = "PD_SSD"
    
    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      start_time                     = "03:00"
      transaction_log_retention_days = 7
    }
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.main.id
      require_ssl     = true
    }
    
    maintenance_window {
      day          = 7 # Sunday
      hour         = 3
      update_track = "stable"
    }
    
    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
    }
    
    database_flags {
      name  = "cloudsql.enable_pgaudit"
      value = "on"
    }
  }
  
  deletion_protection = var.enable_deletion_protection
}

# ==============================================================================
# Artifact Registry
# ==============================================================================

resource "google_artifact_registry_repository" "main" {
  count         = var.enable_artifact_registry ? 1 : 0
  location      = var.gcp_region
  repository_id = "${var.project_name}-repo"
  description   = "Container images for ${var.project_name}"
  format        = "DOCKER"
  
  cleanup_policy_dry_run = false
  
  cleanup_policies {
    id     = "delete-old-images"
    action = "DELETE"
    
    condition {
      tag_state  = "UNTAGGED"
      older_than = "2592000s" # 30 days
    }
  }
  
  labels = var.common_labels
}

# ==============================================================================
# Cloud Monitoring
# ==============================================================================

resource "google_monitoring_notification_channel" "email" {
  count        = var.enable_monitoring_alerts ? 1 : 0
  display_name = "${var.project_name} Email Alerts"
  type         = "email"
  
  labels = {
    email_address = var.alert_email
  }
}

resource "google_monitoring_alert_policy" "high_cpu" {
  count        = var.enable_monitoring_alerts ? 1 : 0
  display_name = "High CPU Usage"
  combiner     = "OR"
  
  conditions {
    display_name = "CPU usage above 80%"
    
    condition_threshold {
      filter          = "resource.type = \"gce_instance\" AND metric.type = \"compute.googleapis.com/instance/cpu/utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = [google_monitoring_notification_channel.email[0].id]
  
  alert_strategy {
    auto_close = "86400s" # 24 hours
  }
}

# ==============================================================================
# Cloud Logging
# ==============================================================================

resource "google_logging_project_sink" "main" {
  name        = "${var.project_name}-logs-sink"
  destination = "storage.googleapis.com/${google_storage_bucket.main.name}"
  
  filter = "severity >= WARNING"
  
  unique_writer_identity = true
}

resource "google_storage_bucket_iam_member" "log_writer" {
  bucket = google_storage_bucket.main.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.main.writer_identity
}
