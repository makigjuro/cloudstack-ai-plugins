# Generic Azure Container App (one unit per service).
#
#   - Image is {registry}/{repository}:{image_tag}; the tag is a required input
#     (git SHA), so applying a new tag rolls a new revision (revision_mode Single).
#   - Registry auth and Key Vault secret references both use the user-assigned
#     managed identity: no registry password, secret values never enter state.
#   - Liveness /health/live and readiness /health/ready probes on target_port.
#   - Internal ingress by default; only the gateway sets ingress_external.

locals {
  name  = "${var.project}-ca-${var.app_name}-${var.environment}-${var.location_short}"
  image = "${var.registry_server}/${var.image_repository}:${var.image_tag}"
  tags = merge({
    project      = var.project
    environment  = var.environment
    "managed-by" = "terraform"
  }, var.tags)
}

resource "azurerm_container_app" "this" {
  name                         = local.name
  container_app_environment_id = var.container_app_environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                = var.revision_mode
  workload_profile_name        = "Consumption"
  tags                         = local.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.managed_identity_id]
  }

  registry {
    server   = var.registry_server
    identity = var.managed_identity_id
  }

  dynamic "secret" {
    for_each = var.key_vault_secrets
    content {
      name                = secret.key
      key_vault_secret_id = secret.value
      identity            = var.managed_identity_id
    }
  }

  ingress {
    external_enabled           = var.ingress_external
    target_port                = var.target_port
    transport                  = "auto"
    allow_insecure_connections = false

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    http_scale_rule {
      name                = "http-concurrency"
      concurrent_requests = tostring(var.http_concurrent_requests)
    }

    container {
      name    = var.app_name
      image   = local.image
      cpu     = var.cpu
      memory  = var.memory
      command = length(var.command) > 0 ? var.command : null
      args    = length(var.args) > 0 ? var.args : null

      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = var.secret_env_vars
        content {
          name        = env.key
          secret_name = env.value
        }
      }

      liveness_probe {
        transport               = "HTTP"
        port                    = var.target_port
        path                    = var.liveness_probe_path
        initial_delay           = 10
        interval_seconds        = 15
        failure_count_threshold = 3
      }

      readiness_probe {
        transport               = "HTTP"
        port                    = var.target_port
        path                    = var.readiness_probe_path
        interval_seconds        = 10
        failure_count_threshold = 3
        success_count_threshold = 1
      }
    }
  }

  lifecycle {
    precondition {
      condition     = length(local.name) <= 32
      error_message = "Container App name '${local.name}' exceeds the 32 character limit."
    }
    precondition {
      condition     = var.max_replicas >= var.min_replicas
      error_message = "max_replicas must be greater than or equal to min_replicas."
    }
    precondition {
      condition     = alltrue([for s in values(var.secret_env_vars) : contains(keys(var.key_vault_secrets), s)])
      error_message = "Every secret_env_vars value must name a secret defined in key_vault_secrets."
    }
  }
}
