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
