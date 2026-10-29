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
  description = "Resource group to create the network resources in"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space of the virtual network"
  type        = list(string)
  default     = ["10.10.0.0/16"]

  validation {
    condition     = alltrue([for c in var.vnet_address_space : can(cidrhost(c, 0))])
    error_message = "Every vnet_address_space entry must be a valid CIDR block."
  }
}

variable "aca_subnet_prefix" {
  description = "CIDR of the Container Apps infrastructure subnet (workload-profiles environments need at least a /27; /23 leaves room to scale)"
  type        = string
  default     = "10.10.0.0/23"

  validation {
    condition     = can(cidrhost(var.aca_subnet_prefix, 0)) && tonumber(split("/", var.aca_subnet_prefix)[1]) <= 27
    error_message = "aca_subnet_prefix must be a valid CIDR of size /27 or larger."
  }
}

variable "postgresql_subnet_prefix" {
  description = "CIDR of the subnet delegated to PostgreSQL Flexible Server"
  type        = string
  default     = "10.10.2.0/24"

  validation {
    condition     = can(cidrhost(var.postgresql_subnet_prefix, 0))
    error_message = "postgresql_subnet_prefix must be a valid CIDR block."
  }
}
