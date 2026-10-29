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
  description = "Resource group to create the environment in"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID receiving container logs"
  type        = string
}

variable "infrastructure_subnet_id" {
  description = "ID of the subnet delegated to Microsoft.App/environments"
  type        = string
}

variable "internal_load_balancer_enabled" {
  description = "Use an internal-only load balancer. Keep false so the gateway's external ingress gets a public endpoint; other apps stay internal via their ingress setting."
  type        = bool
  default     = false
}

variable "zone_redundancy_enabled" {
  description = "Spread the environment across availability zones (forces replacement when changed)"
  type        = bool
  default     = false
}
