output "id" {
  description = "Key Vault resource ID (resolves only after RBAC propagation)"
  value       = azurerm_key_vault.this.id
  depends_on  = [time_sleep.rbac_propagation]
}

output "name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.this.name
}

output "vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.this.vault_uri
}
