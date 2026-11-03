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
  description = "Resource group to create the Key Vault in"
  type        = string
}

variable "secrets_user_principal_id" {
  description = "Principal ID of the workload managed identity that is granted Key Vault Secrets User"
  type        = string
}

variable "allowed_subnet_ids" {
  description = "Subnet IDs (with the Microsoft.KeyVault service endpoint) allowed through the Key Vault firewall"
  type        = list(string)
  default     = []
}

variable "allowed_ip_addresses" {
  description = "Public IPs/CIDRs allowed through the Key Vault firewall on create (operators, CI egress). Rules added later out-of-band are not removed by Terraform."
  type        = list(string)
  default     = []
}

variable "network_default_action" {
  description = "Key Vault firewall default action. Deny keeps the data plane private to allowed subnets/IPs; Allow is an escape hatch for environments without a fixed CI egress IP."
  type        = string
  default     = "Deny"

  validation {
    condition     = contains(["Allow", "Deny"], var.network_default_action)
    error_message = "network_default_action must be Allow or Deny."
  }
}

variable "purge_protection_enabled" {
  description = "Enable purge protection (irreversible once enabled; disable only for disposable environments such as dev)"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Soft-delete retention in days"
  type        = number
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "soft_delete_retention_days must be between 7 and 90."
  }
}

variable "rbac_propagation_wait" {
  description = "Time to wait after role assignments so RBAC has propagated before downstream units write or read secrets"
  type        = string
  default     = "60s"
}
