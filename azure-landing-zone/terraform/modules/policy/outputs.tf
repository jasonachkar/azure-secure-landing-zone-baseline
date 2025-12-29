output "policy_assignment_ids" {
  description = "Map of policy assignment IDs."
  value = {
    require_tags            = azurerm_policy_assignment.require_tags.id
    allowed_locations       = azurerm_policy_assignment.allowed_locations.id
    deny_public_ip          = azurerm_policy_assignment.deny_public_ip.id
    deny_internet_ssh_rdp    = azurerm_policy_assignment.deny_internet_ssh_rdp.id
    storage_secure_transfer = azurerm_policy_assignment.storage_secure_transfer.id
    storage_disable_public  = azurerm_policy_assignment.storage_disable_public.id
    audit_vm_disk_encryption = azurerm_policy_assignment.audit_vm_disk_encryption.id
    audit_diagnostics        = azurerm_policy_assignment.audit_diagnostics.id
  }
}
