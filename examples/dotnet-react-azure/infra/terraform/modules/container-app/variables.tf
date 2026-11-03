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

# --- Container App specific ---

variable "app_name" {
  description = "Logical app name (e.g. orders, gateway); the resource is named {project}-ca-{app_name}-{env}-{location_short}"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,14}[a-z0-9]$", var.app_name))
    error_message = "app_name must be 2-16 lowercase alphanumeric characters or hyphens."
  }
}

variable "revision_mode" {
  description = "Revision mode; Single means each apply with a new image tag replaces the active revision"
  type        = string
  default     = "Single"

  validation {
    condition     = contains(["Single", "Multiple"], var.revision_mode)
    error_message = "revision_mode must be Single or Multiple."
  }
}

variable "ingress_external" {
  description = "Expose ingress publicly. Only the gateway sets true; everything else is internal (https://<app>.internal.<env-domain>)"
  type        = bool
  default     = false
}

variable "target_port" {
  description = "Container port that ingress and probes target"
  type        = number
  default     = 8080
}

variable "min_replicas" {
  description = "Minimum replicas (0 enables scale-to-zero)"
  type        = number
  default     = 0

  validation {
    condition     = var.min_replicas >= 0 && var.min_replicas <= 300
    error_message = "min_replicas must be between 0 and 300."
  }
}

variable "max_replicas" {
  description = "Maximum replicas (must be >= min_replicas)"
  type        = number
  default     = 3

  validation {
    condition     = var.max_replicas >= 1 && var.max_replicas <= 300
    error_message = "max_replicas must be between 1 and 300."
  }
}

variable "http_concurrent_requests" {
  description = "Concurrent HTTP requests per replica that trigger scale-out"
  type        = number
  default     = 50
}

variable "liveness_probe_path" {
  description = "HTTP liveness probe path (no dependency checks)"
  type        = string
  default     = "/health/live"
}

variable "readiness_probe_path" {
  description = "HTTP readiness probe path (checks dependencies before traffic is routed)"
  type        = string
  default     = "/health/ready"
}
