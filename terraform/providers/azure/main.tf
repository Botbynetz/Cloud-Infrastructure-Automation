# ==============================================================================
# Azure Provider Configuration
# ==============================================================================
# Multi-cloud infrastructure - Azure provider setup

terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.45"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = var.prevent_rg_deletion
    }
    
    key_vault {
      purge_soft_delete_on_destroy    = var.purge_key_vault_on_destroy
      recover_soft_deleted_key_vaults = true
    }
    
    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = true
      skip_shutdown_and_force_delete = false
    }
  }
  
  skip_provider_registration = false
  
  # Authentication via Azure CLI or Service Principal
  # subscription_id = var.azure_subscription_id
  # tenant_id       = var.azure_tenant_id
  # client_id       = var.azure_client_id
  # client_secret   = var.azure_client_secret
}

provider "azuread" {
  # tenant_id     = var.azure_tenant_id
  # client_id     = var.azure_client_id
  # client_secret = var.azure_client_secret
}

# ==============================================================================
# Data Sources
# ==============================================================================

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

# ==============================================================================
# Resource Group
# ==============================================================================

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.azure_region
  
  tags = merge(
    var.common_tags,
    {
      Environment = var.environment
      ManagedBy   = "terraform"
      Provider    = "azure"
    }
  )
}

# ==============================================================================
# Virtual Network
# ==============================================================================

resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-vnet"
  address_space       = [var.vnet_address_space]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-vnet"
    }
  )
}

# Subnet for application tier
resource "azurerm_subnet" "app" {
  name                 = "${var.project_name}-app-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.app_subnet_prefix]
  
  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.Sql"
  ]
}

# Subnet for data tier
resource "azurerm_subnet" "data" {
  name                 = "${var.project_name}-data-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.data_subnet_prefix]
  
  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.Sql"
  ]
}

# ==============================================================================
# Network Security Group
# ==============================================================================

resource "azurerm_network_security_group" "app" {
  name                = "${var.project_name}-app-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  security_rule {
    name                       = "AllowSSH"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_source_ip
    destination_address_prefix = "*"
  }
  
  tags = var.common_tags
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}

# ==============================================================================
# Storage Account
# ==============================================================================

resource "azurerm_storage_account" "main" {
  name                     = replace("${var.project_name}storage", "-", "")
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = var.storage_replication_type
  
  enable_https_traffic_only       = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  
  blob_properties {
    versioning_enabled = true
    
    delete_retention_policy {
      days = 30
    }
    
    container_delete_retention_policy {
      days = 30
    }
  }
  
  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.app.id]
    bypass                     = ["AzureServices"]
  }
  
  tags = var.common_tags
}

# ==============================================================================
# Key Vault
# ==============================================================================

resource "azurerm_key_vault" "main" {
  name                = "${var.project_name}-kv"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  enable_rbac_authorization       = true
  purge_protection_enabled        = true
  soft_delete_retention_days      = 30
  
  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = [azurerm_subnet.app.id]
  }
  
  tags = var.common_tags
}

# ==============================================================================
# Log Analytics Workspace
# ==============================================================================

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  
  tags = var.common_tags
}

# ==============================================================================
# Application Insights
# ==============================================================================

resource "azurerm_application_insights" "main" {
  name                = "${var.project_name}-insights"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  
  tags = var.common_tags
}

# ==============================================================================
# Container Registry (Optional)
# ==============================================================================

resource "azurerm_container_registry" "main" {
  count = var.enable_container_registry ? 1 : 0
  
  name                = replace("${var.project_name}acr", "-", "")
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  admin_enabled       = false
  
  georeplications {
    location                = var.acr_replica_location
    zone_redundancy_enabled = true
    tags                    = var.common_tags
  }
  
  tags = var.common_tags
}
