# Azure Container Registry. Admin user is disabled: Container Apps pull with the
# workload managed identity (AcrPull) and CI pushes with its OIDC identity
# (AcrPush), so no registry password exists anywhere.

locals {
  # ACR names must be 5-50 alphanumeric characters (no hyphens).
  name = lower(replace("${var.project}acr${var.environment}${var.location_short}", "-", ""))
  tags = merge({
    project      = var.project
    environment  = var.environment
    "managed-by" = "terraform"
  }, var.tags)
}

resource "azurerm_container_registry" "this" {
  name                   = local.name
  location               = var.location
  resource_group_name    = var.resource_group_name
  sku                    = var.sku
  admin_enabled          = false
  anonymous_pull_enabled = false
  tags                   = local.tags

  lifecycle {
    precondition {
      condition     = can(regex("^[a-z0-9]{5,50}$", local.name))
      error_message = "ACR name '${local.name}' must be 5-50 lowercase alphanumeric characters."
    }
  }
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = var.pull_principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "acr_push" {
  for_each             = toset(var.push_principal_ids)
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPush"
  principal_id         = each.value
  principal_type       = "ServicePrincipal"
}
