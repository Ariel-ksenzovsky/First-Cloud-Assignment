terraform {
  backend "azurerm" {
    resource_group_name  = "rg-backend"          # your backend RG
    storage_account_name = "tfstate1234567890"   # your backend SA
    container_name       = "network-tfstate"
    key                  = "network.tfstate"     # <- state file for network
  }
}
