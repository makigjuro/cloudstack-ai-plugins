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

# --- Workload inputs (shared shape with the container-app module) ---

variable "resource_group_name" {
  description = "Resource group to create the workload in"
  type        = string
}

variable "container_app_environment_id" {
  description = "ID of the Container Apps environment"
  type        = string
}

variable "managed_identity_id" {
  description = "User-assigned identity resource ID used for ACR pulls and Key Vault secret references"
  type        = string
}

variable "registry_server" {
  description = "ACR login server (e.g. starteracrdevweu.azurecr.io); pulled with the managed identity, no password"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+\\.azurecr\\.io$", var.registry_server))
    error_message = "registry_server must be an Azure Container Registry login server (<name>.azurecr.io)."
  }
}

variable "image_repository" {
  description = "Repository name inside the registry (e.g. starter-orders)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+([._/-][a-z0-9]+)*$", var.image_repository))
    error_message = "image_repository must be a valid lowercase repository name without registry or tag."
  }
}

variable "image_tag" {
  description = "Immutable image tag (the git SHA). Required, no default; 'latest' is rejected. Set IMAGE_TAG (or TF_VAR_image_tag) when running Terragrunt."
  type        = string

  validation {
    condition     = var.image_tag != "" && lower(var.image_tag) != "latest" && can(regex("^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$", var.image_tag))
    error_message = "image_tag is required and must be an immutable tag such as the git SHA: export IMAGE_TAG=<sha>. 'latest' and empty values are not allowed."
  }
}

variable "cpu" {
  description = "vCPU per replica (Consumption profile: 0.25-4 in 0.25 steps)"
  type        = number
  default     = 0.5
}

variable "memory" {
  description = "Memory per replica; must be 2x cpu on Consumption (e.g. 1Gi for 0.5 vCPU)"
  type        = string
  default     = "1Gi"

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+)?Gi$", var.memory))
    error_message = "memory must be expressed in Gi, e.g. 1Gi or 0.5Gi."
  }
}

variable "command" {
  description = "Entrypoint override; empty keeps the image ENTRYPOINT"
  type        = list(string)
  default     = []
}

variable "args" {
  description = "Arguments passed to the entrypoint; empty keeps the image CMD"
  type        = list(string)
  default     = []
}

variable "env_vars" {
  description = "Plain (non-secret) environment variables"
  type        = map(string)
  default     = {}
}

variable "key_vault_secrets" {
  description = "Container App secrets backed by Key Vault: map of secret name (lowercase, hyphens) => versionless Key Vault secret ID"
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for k in keys(var.key_vault_secrets) : can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", k))])
    error_message = "Secret names must be lowercase alphanumeric with hyphens."
  }
}

variable "secret_env_vars" {
  description = "Environment variables sourced from secrets: map of ENV_NAME => secret name in key_vault_secrets"
  type        = map(string)
  default     = {}
}

# --- Job specific ---

variable "job_name" {
  description = "Logical job name; the resource is named {project}-job-{job_name}-{env}-{location_short} (max 32 chars in total)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,10}[a-z0-9]$", var.job_name))
    error_message = "job_name must be 2-12 lowercase alphanumeric characters or hyphens."
  }
}

variable "replica_timeout_in_seconds" {
  description = "Maximum run time of one execution before it is killed"
  type        = number
  default     = 600
}

variable "replica_retry_limit" {
  description = "Retries for a failed execution replica"
  type        = number
  default     = 1
}
