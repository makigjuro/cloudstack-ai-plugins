output "id" {
  description = "Static Web App resource ID"
  value       = azurerm_static_web_app.this.id
}

output "name" {
  description = "Static Web App name"
  value       = azurerm_static_web_app.this.name
}

output "default_host_name" {
  description = "Default hostname of the Static Web App (without scheme), used for the gateway CORS origin"
  value       = azurerm_static_web_app.this.default_host_name
}
