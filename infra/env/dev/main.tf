//////////////////////////////////////////////////////
// envs/dev/main.tf
// App RG + Web VM (public subnet) + Azure SQL Database
//////////////////////////////////////////////////////

locals {
  location       = var.location
  project_name   = var.project_name
  admin_username = var.admin_username
  admin_password = var.admin_password
}

############################################
# 1) Use existing network (from /network)
############################################

data "azurerm_resource_group" "network" {
  name = "dev-cloud-network-rg"   # must match network/main.tf
}

data "azurerm_virtual_network" "vnet" {
  name                = "dev-cloud-vnet"        # must match network/main.tf
  resource_group_name = data.azurerm_resource_group.network.name
}

data "azurerm_subnet" "public" {
  name                 = "public-subnet"        # must match network/main.tf
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.network.name
}

data "azurerm_subnet" "private" {
  name                 = "private-subnet"       # not used now, but kept for future
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.network.name
}

############################################
# 2) App Resource Group
############################################

resource "azurerm_resource_group" "app" {
  name     = "${local.project_name}-app-rg"
  location = local.location
}

############################################
# 3) Public IP for Web VM
############################################

resource "azurerm_public_ip" "web_pip" {
  name                = "${local.project_name}-web-pip"
  location            = local.location
  resource_group_name = azurerm_resource_group.app.name

  allocation_method   = "Static"
  sku                 = "Standard"
}

############################################
# 4) NIC (network interface) for Web VM (PUBLIC subnet)
############################################

resource "azurerm_network_interface" "web_nic" {
  name                = "${local.project_name}-web-nic"
  location            = local.location
  resource_group_name = azurerm_resource_group.app.name

  ip_configuration {
    name                          = "web-ipconfig"
    subnet_id                     = data.azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web_pip.id
  }
}

############################################
# 5) Web VM (Ubuntu, in public subnet)
############################################

resource "azurerm_linux_virtual_machine" "web" {
  name                = "${local.project_name}-web-vm"
  location            = local.location
  resource_group_name = azurerm_resource_group.app.name
  size                = "Standard_B1s"          # change if SKU not available

  admin_username                  = local.admin_username
  admin_password                  = local.admin_password
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.web_nic.id
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Later you can add custom_data here to auto-install nginx/app
}

############################################
# 6) Azure SQL logical server (managed DB)
############################################

resource "azurerm_mssql_server" "sql" {
  name                = "${local.project_name}-sql-server-01"   # must be globally unique in Azure SQL
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location

  # Azure SQL logical server "version" is always 12.0
  version = "12.0"

  # SQL admin (server-level) credentials
  administrator_login          = var.administrator_login
  administrator_login_password = var.administrator_login_password    

  # SQL server settings
  minimum_tls_version           = "1.2"
  public_network_access_enabled = true
}

############################################
# 7) Azure SQL Database (single DB)
############################################

resource "azurerm_mssql_database" "appdb" {
  name      = "${local.project_name}-sqldb"
  server_id = azurerm_mssql_server.sql.id

  # Small dev SKU – you can change later (Basic, S0, S1, etc.)
  sku_name    = "Basic"
  max_size_gb = 2

  collation = "SQL_Latin1_General_CP1_CI_AS"
}

############################################
# 8) Private DNS Zone for SQL Private Endpoint
############################################

resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.app.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_link" {
  name                  = "${local.project_name}-sql-dns-link"
  resource_group_name   = azurerm_resource_group.app.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = data.azurerm_virtual_network.vnet.id
}

############################################
# 9) Private Endpoint for Azure SQL in PRIVATE subnet
############################################

resource "azurerm_private_endpoint" "sql_pe" {
  name                = "${local.project_name}-sql-pe"
  location            = local.location
  resource_group_name = azurerm_resource_group.app.name

  # 👇 This is where the PE lives: in your PRIVATE subnet
  subnet_id = data.azurerm_subnet.private.id

  private_service_connection {
    name                           = "${local.project_name}-sql-psc"
    private_connection_resource_id = azurerm_mssql_server.sql.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${local.project_name}-sql-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }
}

