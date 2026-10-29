# --- Standard inputs (supplied by the Terragrunt root for every unit) ---

variable "project" {
  description = "Project short name used as the resource-name prefix (e.g. starter)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,9}$", var.project))
    error_message = "project must be 2-10 lowercase alphanumeric characters starting with a letter (it is embedded in ACR, Key Vault and storage names)."
  }
}

variable "environment" {
  description = "Environment name (dev, staging or prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region (e.g. westeurope)"
  type        = string
}

variable "location_short" {
  description = "Short region code used in resource names (e.g. weu for westeurope)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{2,6}$", var.location_short))
    error_message = "location_short must be 2-6 lowercase alphanumeric characters."
  }
}

variable "tags" {
  description = "Common tags applied to all resources; merged over the module's project/environment/managed-by defaults"
  type        = map(string)
  default     = {}
}

# --- Module inputs ---

variable "resource_group_name" {
  description = "Resource group to create the server in"
  type        = string
}

variable "delegated_subnet_id" {
  description = "ID of the subnet delegated to Microsoft.DBforPostgreSQL/flexibleServers"
  type        = string
}

variable "private_dns_zone_id" {
  description = "ID of the private DNS zone linked to the VNet (private access)"
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault that receives the generated admin password and connection-string secrets"
  type        = string
}

variable "postgresql_version" {
  description = "PostgreSQL major version"
  type        = string
  default     = "16"

  validation {
    condition     = contains(["14", "15", "16", "17"], var.postgresql_version)
    error_message = "postgresql_version must be one of 14, 15, 16, 17."
  }
}

variable "sku_name" {
  description = "Flexible Server SKU (e.g. B_Standard_B1ms, GP_Standard_D2ds_v5)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "storage_mb" {
  description = "Allocated storage in MB"
  type        = number
  default     = 32768
}

variable "backup_retention_days" {
  description = "Backup retention in days (7-35)"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "backup_retention_days must be between 7 and 35."
  }
}

variable "geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backups (set at create time only)"
  type        = bool
  default     = false
}

variable "high_availability_mode" {
  description = "High availability mode: null (disabled), SameZone or ZoneRedundant (General Purpose SKUs only)"
  type        = string
  default     = null

  validation {
    condition     = var.high_availability_mode == null || contains(["SameZone", "ZoneRedundant"], coalesce(var.high_availability_mode, "none"))
    error_message = "high_availability_mode must be null, SameZone or ZoneRedundant."
  }
}

variable "zone" {
  description = "Availability zone for the primary server"
  type        = string
  default     = "1"
}

variable "administrator_login" {
  description = "Administrator login name (the password is generated, never supplied)"
  type        = string
  default     = "starteradmin"
}

variable "database_name" {
  description = "Application database to create"
  type        = string
  default     = "starter"
}

variable "admin_password_secret_name" {
  description = "Key Vault secret name for the generated administrator password"
  type        = string
  default     = "postgres-admin-password"
}

variable "connection_string_secret_name" {
  description = "Key Vault secret name for the application connection string"
  type        = string
  default     = "orders-db-connection"
}
