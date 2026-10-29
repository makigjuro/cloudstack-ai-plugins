# Log Analytics workspace that receives Container Apps system and console logs.

locals {
  name = "${var.project}-log-${var.environment}-${var.location_short}"
  tags = merge({
    project      = var.project
    environment  = var.environment
    "managed-by" = "terraform"
  }, var.tags)
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = local.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_in_days
  daily_quota_gb      = var.daily_quota_gb
  tags                = local.tags
}
