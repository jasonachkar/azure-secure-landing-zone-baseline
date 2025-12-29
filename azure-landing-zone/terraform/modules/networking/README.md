# Networking Module

Creates a hub-and-spoke network baseline with subnets, NSGs, and peering. An optional Azure Firewall can be enabled for centralized egress control.

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
- firewall_id: Firewall ID when enabled.
