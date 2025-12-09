variable "location" {
  type        = string
  default     = "eastus2"

}

variable "project_name" {
  type        = string
  default     = "dev-cloud"

}

variable "admin_username" {
  type        = string
  description = "Azure VM admin username"

}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Azure VM admin password"

}

variable "administrator_login" {
  type        = string
  description = "Azure SQL admin username"
  
}

variable "administrator_login_password" {
  type        = string
  description = "Azure SQL admin password"
  sensitive   = true
  
}