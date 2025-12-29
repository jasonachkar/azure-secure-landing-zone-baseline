output "hub_vnet_id" {
  description = "Hub VNet resource ID."
  value       = azurerm_virtual_network.hub.id
}

output "spoke_vnet_id" {
  description = "Spoke VNet resource ID."
  value       = azurerm_virtual_network.spoke.id
}

output "nsg_ids" {
  description = "Map of NSG IDs keyed by subnet identifier."
  value       = { for key, nsg in azurerm_network_security_group.subnet : key => nsg.id }
}

output "firewall_id" {
  description = "Azure Firewall resource ID if enabled."
  value       = var.enable_firewall ? azurerm_firewall.this[0].id : null
}
