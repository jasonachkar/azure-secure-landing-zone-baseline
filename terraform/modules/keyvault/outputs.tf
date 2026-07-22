output "key_vault_id" {
  description = "Key Vault resource ID."
  value       = azurerm_key_vault.this.id
}

output "key_vault_uri" {
  description = "Key Vault data-plane URI."
  value       = azurerm_key_vault.this.vault_uri
}

output "key_vault_name" {
  description = "Key Vault name."
  value       = azurerm_key_vault.this.name
}

output "storage_encryption_key_id" {
  description = "Versioned Key Vault key ID used to encrypt diagnostics storage."
  value       = azurerm_key_vault_key.storage_encryption.id
}

output "storage_encryption_identity_id" {
  description = "User-assigned identity ID authorized to use the storage encryption key."
  value       = azurerm_user_assigned_identity.storage_encryption.id
}

output "private_endpoint_id" {
  description = "Key Vault private endpoint resource ID."
  value       = azurerm_private_endpoint.this.id
}
