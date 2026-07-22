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

output "subnet_ids" {
  description = "Map of subnet IDs keyed by hub/spoke role."
  value       = { for key, subnet in azurerm_subnet.this : key => subnet.id }
}

output "vnet_ids" {
  description = "Map of hub and spoke virtual network IDs."
  value = {
    hub   = azurerm_virtual_network.hub.id
    spoke = azurerm_virtual_network.spoke.id
  }
}

output "firewall_id" {
  description = "Azure Firewall resource ID if enabled."
  value       = var.enable_firewall ? azurerm_firewall.this[0].id : null
}
