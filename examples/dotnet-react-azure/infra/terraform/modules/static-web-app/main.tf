# Azure Static Web App hosting the React SPA. Static Web Apps is only offered
# in a subset of regions; westeurope is one of them.
#
# The deployment token is deliberately not exported: CI fetches it at deploy
# time with `az staticwebapp secrets list` after authenticating via OIDC, so
# it never lands in a GitHub secret.

locals {
  name = "${var.project}-swa-${var.environment}-${var.location_short}"
  tags = merge({
    project      = var.project
    environment  = var.environment
    "managed-by" = "terraform"
  }, var.tags)
}

resource "azurerm_static_web_app" "this" {
  name                = local.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_tier            = var.sku_tier
  sku_size            = var.sku_tier
  tags                = local.tags
}
