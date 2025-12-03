terraform {
  backend "azurerm" {
    resource_group_name  = "rg-backend"
    storage_account_name = "tfstate1234567890"
    container_name       = "dev-tfstate"
    key                  = "dev.tfstate"
  }
}