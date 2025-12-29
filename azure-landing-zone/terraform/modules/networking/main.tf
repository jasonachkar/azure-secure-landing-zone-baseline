resource "azurerm_virtual_network" "hub" {
  name                = "${var.name_prefix}-vnet-hub"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.hub_vnet_address_space
  tags                = var.tags
}

resource "azurerm_virtual_network" "spoke" {
  name                = "${var.name_prefix}-vnet-spoke"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.spoke_vnet_address_space
  tags                = var.tags
}

locals {
  hub_subnets = {
    app  = var.hub_subnet_prefixes.app
    data = var.hub_subnet_prefixes.data
    mgmt = var.hub_subnet_prefixes.mgmt
  }

  spoke_subnets = {
    app  = var.spoke_subnet_prefixes.app
    data = var.spoke_subnet_prefixes.data
    mgmt = var.spoke_subnet_prefixes.mgmt
  }

  subnets = merge(
    {
      for name, prefix in local.hub_subnets : "hub-${name}" => {
        role                 = name
        vnet_name            = azurerm_virtual_network.hub.name
        resource_group_name  = var.resource_group_name
        address_prefixes     = [prefix]
      }
    },
    {
      for name, prefix in local.spoke_subnets : "spoke-${name}" => {
        role                 = name
        vnet_name            = azurerm_virtual_network.spoke.name
        resource_group_name  = var.resource_group_name
        address_prefixes     = [prefix]
      }
    }
  )

  base_rules = [
    {
      name                       = "deny-internet-inbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
      destination_port_range     = "*"
    },
    {
      name                       = "allow-vnet-inbound"
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
      destination_port_range     = "*"
    }
  ]
}

resource "azurerm_subnet" "this" {
  for_each             = local.subnets
  name                 = "snet-${each.value.role}"
  resource_group_name  = each.value.resource_group_name
  virtual_network_name = each.value.vnet_name
  address_prefixes     = each.value.address_prefixes
}

resource "azurerm_network_security_group" "subnet" {
  for_each            = local.subnets
  name                = "${var.name_prefix}-nsg-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  dynamic "security_rule" {
    for_each = local.base_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
      source_port_range          = "*"
      destination_port_range     = security_rule.value.destination_port_range
    }
  }

  dynamic "security_rule" {
    for_each = (each.value.role == "mgmt" && length(var.admin_ip_allowlist) > 0) ? [1] : []
    content {
      name                       = "allow-admin-ssh-rdp"
      priority                   = 90
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefixes    = var.admin_ip_allowlist
      destination_address_prefix = "*"
      source_port_range          = "*"
      destination_port_ranges    = ["22", "3389"]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each                  = local.subnets
  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.subnet[each.key].id
}

resource "azurerm_subnet" "firewall" {
  count                = var.enable_firewall ? 1 : 0
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.hub_subnet_prefixes.firewall]
}

resource "azurerm_public_ip" "firewall" {
  count               = var.enable_firewall ? 1 : 0
  name                = "${var.name_prefix}-pip-fw"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall" "this" {
  count               = var.enable_firewall ? 1 : 0
  name                = "${var.name_prefix}-fw"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall[0].id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "${var.name_prefix}-peer-hub-to-spoke"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "${var.name_prefix}-peer-spoke-to-hub"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false
}
