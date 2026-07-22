# Networking Module

Creates a hub-and-spoke network baseline with subnets, NSGs, and peering. The optional Azure Firewall Premium uses a dedicated Firewall Policy with threat intelligence and IDPS in deny mode.

Inputs:
- name_prefix: Prefix for resource naming.
- resource_group_name: Resource group for networking resources.
- location: Azure region.
- tags: Resource tags.
- hub_vnet_address_space: Address space for hub VNet.
- spoke_vnet_address_space: Address space for spoke VNet.
- hub_subnet_prefixes: Subnet prefixes for hub (app, data, mgmt, firewall).
- spoke_subnet_prefixes: Subnet prefixes for spoke (app, data, mgmt).
- admin_ip_allowlist: CIDR list for optional SSH/RDP access to mgmt subnets.
- enable_firewall: Create Azure Firewall and its subnet if true.

Outputs:
- hub_vnet_id: Hub VNet ID.
- spoke_vnet_id: Spoke VNet ID.
- nsg_ids: Map of NSG IDs keyed by subnet.
- subnet_ids: Map of subnet IDs keyed by hub/spoke role.
- vnet_ids: Map containing the hub and spoke VNet IDs.
- firewall_id: Firewall ID when enabled.
