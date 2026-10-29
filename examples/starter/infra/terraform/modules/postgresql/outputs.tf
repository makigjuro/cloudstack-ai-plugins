output "id" {
  description = "Flexible Server resource ID"
  value       = azurerm_postgresql_flexible_server.this.id
}

output "name" {
  description = "Flexible Server name"
  value       = azurerm_postgresql_flexible_server.this.name
}

output "fqdn" {
  description = "Private FQDN of the server"
  value       = azurerm_postgresql_flexible_server.this.fqdn
}

output "database_name" {
  description = "Application database name"
  value       = azurerm_postgresql_flexible_server_database.app.name
}

output "connection_string_secret_name" {
  description = "Key Vault secret name holding the application connection string"
  value       = azurerm_key_vault_secret.connection_string.name
}

output "connection_string_secret_id" {
  description = "Versionless Key Vault secret ID of the connection string (Container Apps always resolve the latest version)"
  value       = azurerm_key_vault_secret.connection_string.versionless_id
}

output "admin_password_secret_id" {
  description = "Versionless Key Vault secret ID of the administrator password"
  value       = azurerm_key_vault_secret.admin_password.versionless_id
}
