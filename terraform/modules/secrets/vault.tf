# Secrets Management Module - HashiCorp Vault Integration
# Provides centralized secrets management with automatic rotation

terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.20"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ============================================
# Vault KV Secrets Engine v2
# ============================================

# Enable KV secrets engine
resource "vault_mount" "kv" {
  path        = "${var.project_name}/${var.environment}"
  type        = "kv-v2"
  description = "KV secrets engine for ${var.project_name} ${var.environment}"
  
  options = {
    version = "2"
  }
}

# AWS Credentials Secret
resource "vault_kv_secret_v2" "aws_credentials" {
  count = var.enable_aws_secrets ? 1 : 0
  
  mount               = vault_mount.kv.path
  name                = "aws/credentials"
  delete_all_versions = false
  
  data_json = jsonencode({
    access_key_id     = var.aws_access_key_id
    secret_access_key = var.aws_secret_access_key
    region            = var.aws_region
  })
  
  custom_metadata {
    max_versions = 10
    data = {
      environment = var.environment
      managed_by  = "terraform"
      rotation    = "enabled"
    }
  }
}

# GCP Credentials Secret
resource "vault_kv_secret_v2" "gcp_credentials" {
  count = var.enable_gcp_secrets ? 1 : 0
  
  mount               = vault_mount.kv.path
  name                = "gcp/credentials"
  delete_all_versions = false
  
  data_json = jsonencode({
    project_id    = var.gcp_project_id
    credentials   = var.gcp_service_account_key
    region        = var.gcp_region
  })
  
  custom_metadata {
    max_versions = 10
    data = {
      environment = var.environment
      managed_by  = "terraform"
      rotation    = "enabled"
    }
  }
}

# Azure Credentials Secret
resource "vault_kv_secret_v2" "azure_credentials" {
  count = var.enable_azure_secrets ? 1 : 0
  
  mount               = vault_mount.kv.path
  name                = "azure/credentials"
  delete_all_versions = false
  
  data_json = jsonencode({
    subscription_id = var.azure_subscription_id
    tenant_id       = var.azure_tenant_id
    client_id       = var.azure_client_id
    client_secret   = var.azure_client_secret
  })
  
  custom_metadata {
    max_versions = 10
    data = {
      environment = var.environment
      managed_by  = "terraform"
      rotation    = "enabled"
    }
  }
}

# Database Credentials Secret
resource "vault_kv_secret_v2" "database" {
  count = var.enable_database_secrets ? 1 : 0
  
  mount               = vault_mount.kv.path
  name                = "database/credentials"
  delete_all_versions = false
  
  data_json = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = var.db_host
    port     = var.db_port
    database = var.db_name
  })
  
  custom_metadata {
    max_versions = 10
    data = {
      environment = var.environment
      managed_by  = "terraform"
      rotation    = "automatic"
      rotation_period = "30d"
    }
  }
}

# API Keys and Tokens
resource "vault_kv_secret_v2" "api_keys" {
  count = var.enable_api_secrets ? 1 : 0
  
  mount               = vault_mount.kv.path
  name                = "api/keys"
  delete_all_versions = false
  
  data_json = jsonencode({
    github_token    = var.github_token
    slack_webhook   = var.slack_webhook
    datadog_api_key = var.datadog_api_key
  })
  
  custom_metadata {
    max_versions = 10
    data = {
      environment = var.environment
      managed_by  = "terraform"
    }
  }
}

# ============================================
# Vault AWS Secrets Engine (Dynamic Credentials)
# ============================================

# Enable AWS secrets engine
resource "vault_aws_secret_backend" "aws" {
  count = var.enable_dynamic_aws_credentials ? 1 : 0
  
  path                      = "aws/${var.environment}"
  description               = "AWS secrets engine for ${var.environment}"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 86400
  
  access_key = var.aws_root_access_key
  secret_key = var.aws_root_secret_key
  region     = var.aws_region
}

# AWS IAM role for dynamic credentials
resource "vault_aws_secret_backend_role" "developer" {
  count = var.enable_dynamic_aws_credentials ? 1 : 0
  
  backend         = vault_aws_secret_backend.aws[0].path
  name            = "developer"
  credential_type = "iam_user"
  
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "s3:ListBucket",
          "s3:GetObject",
          "rds:Describe*",
          "lambda:List*"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================
# Vault Database Secrets Engine (Dynamic DB Credentials)
# ============================================

# Enable database secrets engine
resource "vault_database_secrets_mount" "db" {
  count = var.enable_dynamic_db_credentials ? 1 : 0
  
  path = "database/${var.environment}"
  
  postgresql {
    name              = "postgres"
    username          = var.db_root_username
    password          = var.db_root_password
    connection_url    = "postgresql://{{username}}:{{password}}@${var.db_host}:${var.db_port}/postgres?sslmode=require"
    verify_connection = true
    allowed_roles     = ["readonly", "readwrite"]
  }
}

# Database role - Read Only
resource "vault_database_secret_backend_role" "readonly" {
  count = var.enable_dynamic_db_credentials ? 1 : 0
  
  backend             = vault_database_secrets_mount.db[0].path
  name                = "readonly"
  db_name             = "postgres"
  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
    "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";"
  ]
  default_ttl         = 3600
  max_ttl             = 86400
}

# Database role - Read Write
resource "vault_database_secret_backend_role" "readwrite" {
  count = var.enable_dynamic_db_credentials ? 1 : 0
  
  backend             = vault_database_secrets_mount.db[0].path
  name                = "readwrite"
  db_name             = "postgres"
  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
    "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";"
  ]
  default_ttl         = 3600
  max_ttl             = 86400
}

# ============================================
# Vault Policies
# ============================================

# Policy for developers - read access
resource "vault_policy" "developer" {
  name = "${var.project_name}-${var.environment}-developer"
  
  policy = <<EOT
# Read secrets
path "${vault_mount.kv.path}/data/*" {
  capabilities = ["read", "list"]
}

# Generate dynamic AWS credentials
path "aws/${var.environment}/creds/developer" {
  capabilities = ["read"]
}

# Generate dynamic database credentials
path "database/${var.environment}/creds/readonly" {
  capabilities = ["read"]
}
EOT
}

# Policy for admins - full access
resource "vault_policy" "admin" {
  name = "${var.project_name}-${var.environment}-admin"
  
  policy = <<EOT
# Full access to secrets
path "${vault_mount.kv.path}/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage AWS secrets engine
path "aws/${var.environment}/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage database secrets engine
path "database/${var.environment}/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOT
}

# Policy for CI/CD - limited access
resource "vault_policy" "cicd" {
  name = "${var.project_name}-${var.environment}-cicd"
  
  policy = <<EOT
# Read deployment secrets
path "${vault_mount.kv.path}/data/aws/*" {
  capabilities = ["read"]
}

path "${vault_mount.kv.path}/data/gcp/*" {
  capabilities = ["read"]
}

path "${vault_mount.kv.path}/data/azure/*" {
  capabilities = ["read"]
}

# Generate dynamic credentials
path "aws/${var.environment}/creds/*" {
  capabilities = ["read"]
}

path "database/${var.environment}/creds/readwrite" {
  capabilities = ["read"]
}
EOT
}

# ============================================
# Outputs
# ============================================

output "vault_kv_path" {
  description = "Vault KV secrets engine path"
  value       = vault_mount.kv.path
}

output "vault_aws_path" {
  description = "Vault AWS secrets engine path"
  value       = var.enable_dynamic_aws_credentials ? vault_aws_secret_backend.aws[0].path : null
}

output "vault_database_path" {
  description = "Vault database secrets engine path"
  value       = var.enable_dynamic_db_credentials ? vault_database_secrets_mount.db[0].path : null
}

output "vault_policies" {
  description = "Created Vault policies"
  value = {
    developer = vault_policy.developer.name
    admin     = vault_policy.admin.name
    cicd      = vault_policy.cicd.name
  }
}
