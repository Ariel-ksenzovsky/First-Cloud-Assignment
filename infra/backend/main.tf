terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# -------------------------------------------------------
# 1. Resource Group for backend state
# -------------------------------------------------------
resource "azurerm_resource_group" "backend" {
  name     = "rg-backend"
  location = "eastus"
}

# -------------------------------------------------------
# 2. Storage Account for tfstate
# -------------------------------------------------------
resource "azurerm_storage_account" "tfstate" {
  name                     = "tfstate1234567890"   # must be globally unique
  resource_group_name      = azurerm_resource_group.backend.name
  location                 = azurerm_resource_group.backend.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# -------------------------------------------------------
# 3. Storage Container for tfstate blob
# -------------------------------------------------------
resource "azurerm_storage_container" "network-state" {
  name                  = "network-tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "dev-state" {
  name                  = "dev-tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}