# Manually triggered Container Apps Job (migrations, setup tasks).
#
# Terraform keeps the job definition on the current image tag; the deploy
# pipeline runs `az containerapp job start` and waits for success BEFORE the
# app's new revision takes traffic. parallelism = 1 and
# replica_completion_count = 1 mean one execution is exactly one replica, so a
# migration can never race itself.

locals {
  name  = "${var.project}-job-${var.job_name}-${var.environment}-${var.location_short}"
  image = "${var.registry_server}/${var.image_repository}:${var.image_tag}"
  tags = merge({
    project      = var.project
    environment  = var.environment
    "managed-by" = "terraform"
  }, var.tags)
}

resource "azurerm_container_app_job" "this" {
  name                         = local.name
  location                     = var.location
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_environment_id
  workload_profile_name        = "Consumption"
  replica_timeout_in_seconds   = var.replica_timeout_in_seconds
  replica_retry_limit          = var.replica_retry_limit
  tags                         = local.tags

  manual_trigger_config {
    parallelism              = 1
    replica_completion_count = 1
  }

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

  template {
    container {
      name    = var.job_name
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
    }
  }

  lifecycle {
    precondition {
      condition     = length(local.name) <= 32
      error_message = "Container App Job name '${local.name}' exceeds the 32 character limit."
    }
    precondition {
      condition     = alltrue([for s in values(var.secret_env_vars) : contains(keys(var.key_vault_secrets), s)])
      error_message = "Every secret_env_vars value must name a secret defined in key_vault_secrets."
    }
  }
}
