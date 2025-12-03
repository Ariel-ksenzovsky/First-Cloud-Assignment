############################################
# Outputs – see public IP + SQL info
############################################

output "web_public_ip" {
  description = "Public IP of the web VM"
  value       = azurerm_public_ip.web_pip.ip_address
}

output "sql_server_fqdn" {
  description = "Azure SQL server DNS name for connection strings"
  value       = azurerm_mssql_server.sql.fully_qualified_domain_name
}

output "sql_database_name" {
  description = "Azure SQL database name"
  value       = azurerm_mssql_database.appdb.name
}

output "sql_admin_login" {
  description = "SQL admin username (use with the password you set in code/tfvars)"
  value       = azurerm_mssql_server.sql.administrator_login
}
