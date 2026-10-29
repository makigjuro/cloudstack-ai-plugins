# Resource group that holds every resource of one environment.

locals {
  name = "${var.project}-rg-${var.environment}-${var.location_short}"
  tags = merge({
    project      = var.project
    environment  = var.environment
    "managed-by" = "terraform"
  }, var.tags)
}

resource "azurerm_resource_group" "this" {
  name     = local.name
  location = var.location
  tags     = local.tags
}
