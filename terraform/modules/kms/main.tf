# Multi-Cloud KMS Module
# Provides unified encryption key management across AWS, GCP, and Azure

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# ============================================
# AWS KMS Keys
# ============================================

# Primary KMS key for general encryption
resource "aws_kms_key" "primary" {
  count = var.enable_aws_kms ? 1 : 0
  
  description             = "Primary KMS key for ${var.project_name} ${var.environment}"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true
  multi_region            = var.enable_multi_region_kms
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-primary-kms"
      Purpose     = "Primary encryption key"
      Environment = var.environment
    }
  )
}

resource "aws_kms_alias" "primary" {
  count = var.enable_aws_kms ? 1 : 0
  
  name          = "alias/${var.project_name}-${var.environment}-primary"
  target_key_id = aws_kms_key.primary[0].key_id
}

# KMS key for Terraform state encryption
resource "aws_kms_key" "terraform_state" {
  count = var.enable_aws_kms ? 1 : 0
  
  description             = "KMS key for Terraform state encryption"
  deletion_window_in_days = 30  # Longer window for critical infrastructure
  enable_key_rotation     = true
  multi_region            = var.enable_multi_region_kms
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-terraform-state-kms"
      Purpose     = "Terraform state encryption"
      Critical    = "true"
      Environment = var.environment
    }
  )
}

resource "aws_kms_alias" "terraform_state" {
  count = var.enable_aws_kms ? 1 : 0
  
  name          = "alias/${var.project_name}-${var.environment}-terraform-state"
  target_key_id = aws_kms_key.terraform_state[0].key_id
}

# KMS key for secrets (AWS Secrets Manager, Parameter Store)
resource "aws_kms_key" "secrets" {
  count = var.enable_aws_kms ? 1 : 0
  
  description             = "KMS key for secrets encryption"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true
  multi_region            = var.enable_multi_region_kms
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-secrets-kms"
      Purpose     = "Secrets encryption"
      Environment = var.environment
    }
  )
}

resource "aws_kms_alias" "secrets" {
  count = var.enable_aws_kms ? 1 : 0
  
  name          = "alias/${var.project_name}-${var.environment}-secrets"
  target_key_id = aws_kms_key.secrets[0].key_id
}

# KMS key for EBS volume encryption
resource "aws_kms_key" "ebs" {
  count = var.enable_aws_kms ? 1 : 0
  
  description             = "KMS key for EBS volume encryption"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-ebs-kms"
      Purpose     = "EBS encryption"
      Environment = var.environment
    }
  )
}

resource "aws_kms_alias" "ebs" {
  count = var.enable_aws_kms ? 1 : 0
  
  name          = "alias/${var.project_name}-${var.environment}-ebs"
  target_key_id = aws_kms_key.ebs[0].key_id
}

# KMS key for RDS encryption
resource "aws_kms_key" "rds" {
  count = var.enable_aws_kms ? 1 : 0
  
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-rds-kms"
      Purpose     = "RDS encryption"
      Environment = var.environment
    }
  )
}

resource "aws_kms_alias" "rds" {
  count = var.enable_aws_kms ? 1 : 0
  
  name          = "alias/${var.project_name}-${var.environment}-rds"
  target_key_id = aws_kms_key.rds[0].key_id
}

# KMS key for S3 encryption
resource "aws_kms_key" "s3" {
  count = var.enable_aws_kms ? 1 : 0
  
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-s3-kms"
      Purpose     = "S3 encryption"
      Environment = var.environment
    }
  )
}

resource "aws_kms_alias" "s3" {
  count = var.enable_aws_kms ? 1 : 0
  
  name          = "alias/${var.project_name}-${var.environment}-s3"
  target_key_id = aws_kms_key.s3[0].key_id
}

# KMS key policy for cross-account access (optional)
resource "aws_kms_key_policy" "primary" {
  count = var.enable_aws_kms && var.enable_cross_account_access ? 1 : 0
  
  key_id = aws_kms_key.primary[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow services to use the key"
        Effect = "Allow"
        Principal = {
          Service = [
            "s3.amazonaws.com",
            "rds.amazonaws.com",
            "secretsmanager.amazonaws.com"
          ]
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow cross-account access"
        Effect = "Allow"
        Principal = {
          AWS = var.cross_account_role_arns
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================
# GCP KMS Keys
# ============================================

# GCP Key Ring
resource "google_kms_key_ring" "main" {
  count = var.enable_gcp_kms ? 1 : 0
  
  name     = "${var.project_name}-${var.environment}-keyring"
  location = var.gcp_region
}

# Primary crypto key for general encryption
resource "google_kms_crypto_key" "primary" {
  count = var.enable_gcp_kms ? 1 : 0
  
  name     = "${var.project_name}-${var.environment}-primary"
  key_ring = google_kms_key_ring.main[0].id
  
  rotation_period = "7776000s"  # 90 days
  
  lifecycle {
    prevent_destroy = true
  }
  
  labels = merge(
    var.gcp_labels,
    {
      environment = var.environment
      purpose     = "primary-encryption"
    }
  )
}

# Crypto key for Terraform state
resource "google_kms_crypto_key" "terraform_state" {
  count = var.enable_gcp_kms ? 1 : 0
  
  name     = "${var.project_name}-${var.environment}-terraform-state"
  key_ring = google_kms_key_ring.main[0].id
  
  rotation_period = "7776000s"
  
  lifecycle {
    prevent_destroy = true
  }
  
  labels = merge(
    var.gcp_labels,
    {
      environment = var.environment
      purpose     = "terraform-state"
      critical    = "true"
    }
  )
}

# Crypto key for secrets
resource "google_kms_crypto_key" "secrets" {
  count = var.enable_gcp_kms ? 1 : 0
  
  name     = "${var.project_name}-${var.environment}-secrets"
  key_ring = google_kms_key_ring.main[0].id
  
  rotation_period = "7776000s"
  
  labels = merge(
    var.gcp_labels,
    {
      environment = var.environment
      purpose     = "secrets-encryption"
    }
  )
}

# ============================================
# Azure Key Vault
# ============================================

# Resource Group for Key Vault
resource "azurerm_resource_group" "keyvault" {
  count = var.enable_azure_keyvault ? 1 : 0
  
  name     = "${var.project_name}-${var.environment}-keyvault-rg"
  location = var.azure_location
  
  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Purpose     = "Key Vault"
    }
  )
}

# Azure Key Vault
resource "azurerm_key_vault" "main" {
  count = var.enable_azure_keyvault ? 1 : 0
  
  name                = "${var.project_name}${var.environment}kv"
  location            = azurerm_resource_group.keyvault[0].location
  resource_group_name = azurerm_resource_group.keyvault[0].name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"  # Premium for HSM support
  
  # Security features
  enabled_for_disk_encryption     = true
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = var.environment == "prod" ? true : false
  soft_delete_retention_days      = 90
  
  # Network ACLs
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = var.allowed_ip_ranges
  }
  
  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Purpose     = "Secrets Management"
    }
  )
}

# Key Vault access policy for Terraform
resource "azurerm_key_vault_access_policy" "terraform" {
  count = var.enable_azure_keyvault ? 1 : 0
  
  key_vault_id = azurerm_key_vault.main[0].id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id
  
  key_permissions = [
    "Get", "List", "Create", "Delete", "Update",
    "Encrypt", "Decrypt", "WrapKey", "UnwrapKey"
  ]
  
  secret_permissions = [
    "Get", "List", "Set", "Delete"
  ]
  
  certificate_permissions = [
    "Get", "List", "Create", "Delete"
  ]
}

# Azure Key Vault Key for encryption
resource "azurerm_key_vault_key" "primary" {
  count = var.enable_azure_keyvault ? 1 : 0
  
  name         = "${var.project_name}-${var.environment}-primary"
  key_vault_id = azurerm_key_vault.main[0].id
  key_type     = "RSA"
  key_size     = 4096
  
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]
  
  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }
    
    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }
  
  depends_on = [azurerm_key_vault_access_policy.terraform]
}

# ============================================
# Data Sources
# ============================================

data "aws_caller_identity" "current" {}

data "azurerm_client_config" "current" {}
