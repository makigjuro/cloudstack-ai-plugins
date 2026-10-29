output "id" {
  description = "Container registry resource ID"
  value       = azurerm_container_registry.this.id
}

output "name" {
  description = "Container registry name"
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "Registry login server (e.g. starteracrdevweu.azurecr.io); resolves after AcrPull is granted"
  value       = azurerm_container_registry.this.login_server
  depends_on  = [azurerm_role_assignment.acr_pull]
}
