output "hub_vnet_id" {
  description = "Hub VNet resource ID."
  value       = module.networking.hub_vnet_id
}

output "spoke_vnet_id" {
  description = "Spoke VNet resource ID."
  value       = module.networking.spoke_vnet_id
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace resource ID."
  value       = module.logging.log_analytics_workspace_id
}

output "policy_assignment_ids" {
  description = "Policy assignment IDs created by the policy module."
  value       = module.policy.policy_assignment_ids
}

output "key_vault_id" {
  description = "Key Vault resource ID."
  value       = module.keyvault.key_vault_id
}

output "key_vault_uri" {
  description = "Key Vault data-plane URI."
  value       = module.keyvault.key_vault_uri
}

output "security_action_group_id" {
  description = "Azure Monitor security action group resource ID."
  value       = module.alerts.action_group_id
}
