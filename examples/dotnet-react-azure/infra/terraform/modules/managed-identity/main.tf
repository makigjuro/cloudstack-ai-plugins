# User-assigned managed identity shared by the container apps and jobs.
# It is granted AcrPull (container-registry module) and Key Vault Secrets User
# (key-vault module) so no registry password or secret value is ever stored.

locals {
  name = "${var.project}-id-${var.environment}-${var.location_short}"
  tags = merge({
    project      = var.project
    environment  = var.environment
    "managed-by" = "terraform"
  }, var.tags)
}

resource "azurerm_user_assigned_identity" "this" {
  name                = local.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.tags
}
