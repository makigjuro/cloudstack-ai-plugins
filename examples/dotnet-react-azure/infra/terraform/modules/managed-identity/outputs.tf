output "id" {
  description = "Resource ID of the user-assigned identity (used for ACA identity, registry and Key Vault references)"
  value       = azurerm_user_assigned_identity.this.id
}

output "name" {
  description = "Name of the user-assigned identity"
  value       = azurerm_user_assigned_identity.this.name
}

output "principal_id" {
  description = "Object (principal) ID of the identity, used for role assignments"
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "client_id" {
  description = "Client ID of the identity (e.g. AZURE_CLIENT_ID for DefaultAzureCredential)"
  value       = azurerm_user_assigned_identity.this.client_id
}
