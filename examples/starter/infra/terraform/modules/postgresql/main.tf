# PostgreSQL Flexible Server with private access (VNet-delegated subnet +
# private DNS zone, no public endpoint).
#
# The administrator password is generated here and written to Key Vault
# together with a ready-to-use Npgsql connection string; apps read it through a
# Key Vault secret reference. Nothing is created out of band.

locals {
  name = "${var.project}-psql-${var.environment}-${var.location_short}"
  tags = merge({
    project      = var.project
    environment  = var.environment
    "managed-by" = "terraform"
  }, var.tags)

  connection_string = join(";", [
    "Host=${azurerm_postgresql_flexible_server.this.fqdn}",
    "Port=5432",
    "Database=${azurerm_postgresql_flexible_server_database.app.name}",
    "Username=${var.administrator_login}",
    "Password=${random_password.admin.result}",
    "Ssl Mode=Require",
  ])
}

# Restricted special set: no ; ' " = so the value is safe inside an Npgsql
# connection string without quoting.
resource "random_password" "admin" {
  length           = 32
  special          = true
  override_special = "!#%*-_+?"
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
}

resource "azurerm_postgresql_flexible_server" "this" {
  name                          = local.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = var.postgresql_version
  sku_name                      = var.sku_name
  storage_mb                    = var.storage_mb
  administrator_login           = var.administrator_login
  administrator_password        = random_password.admin.result
  backup_retention_days         = var.backup_retention_days
  geo_redundant_backup_enabled  = var.geo_redundant_backup_enabled
  public_network_access_enabled = false
  delegated_subnet_id           = var.delegated_subnet_id
  private_dns_zone_id           = var.private_dns_zone_id
  zone                          = var.zone
  tags                          = local.tags

  dynamic "high_availability" {
    for_each = var.high_availability_mode == null ? [] : [var.high_availability_mode]
    content {
      mode = high_availability.value
    }
  }

  lifecycle {
    # Azure may swap zones after an HA failover; do not fight it.
    ignore_changes = [zone, high_availability[0].standby_availability_zone]
  }
}

resource "azurerm_postgresql_flexible_server_database" "app" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_configuration" "require_secure_transport" {
  server_id = azurerm_postgresql_flexible_server.this.id
  name      = "require_secure_transport"
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "ssl_min_protocol_version" {
  server_id = azurerm_postgresql_flexible_server.this.id
  name      = "ssl_min_protocol_version"
  value     = "TLSv1.2"
}

# Temporarily throttles connections per IP after repeated login failures.
resource "azurerm_postgresql_flexible_server_configuration" "connection_throttle" {
  server_id = azurerm_postgresql_flexible_server.this.id
  name      = "connection_throttle.enable"
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_connections" {
  server_id = azurerm_postgresql_flexible_server.this.id
  name      = "log_connections"
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_checkpoints" {
  server_id = azurerm_postgresql_flexible_server.this.id
  name      = "log_checkpoints"
  value     = "on"
}

# --- Secrets written to Key Vault ---

resource "azurerm_key_vault_secret" "admin_password" {
  name         = var.admin_password_secret_name
  value        = random_password.admin.result
  key_vault_id = var.key_vault_id
  content_type = "text/plain"
  tags         = local.tags
}

resource "azurerm_key_vault_secret" "connection_string" {
  name         = var.connection_string_secret_name
  value        = local.connection_string
  key_vault_id = var.key_vault_id
  content_type = "application/x-npgsql-connection-string"
  tags         = local.tags
}
