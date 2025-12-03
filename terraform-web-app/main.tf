terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "tf-backend-rg"
    storage_account_name = "newtfstate123456"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}


provider "azurerm" {
  features {}

  # ---------------------------------------------------------
  # 1) Resource Group
  # ---------------------------------------------------------

}
resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = local.location
}



# ---------------------------------------------------------
# 2) Azure Container Registry (ACR)
# ---------------------------------------------------------
resource "azurerm_container_registry" "acr" {
  name                = "ariel1devops1assigenment" # must be globally unique
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true # BEST PRACTICE: disable admin user
}

# ---------------------------------------------------------
# 3) App Service Plan (Linux)
# ---------------------------------------------------------
resource "azurerm_service_plan" "plan" {
  name                = "cloud-assignment-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  os_type  = "Linux"
  sku_name = "B1"
}


# ---------------------------------------------------------
# 4) Linux Web App (Container from ACR)
# ---------------------------------------------------------
resource "azurerm_linux_web_app" "app" {
  name                = "static-website-docker"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.plan.id

  # You can actually drop identity completely if you use admin creds
  # identity {
  #   type = "SystemAssigned"
  # }

  site_config {
    application_stack {
      docker_image_name        = "${azurerm_container_registry.acr.login_server}/static-site:latest"
      docker_registry_url      = "https://${azurerm_container_registry.acr.login_server}"
      docker_registry_username = azurerm_container_registry.acr.admin_username
      docker_registry_password = azurerm_container_registry.acr.admin_password
    }
  }

  app_settings = {
    WEBSITES_PORT = "8080"
  }
}





