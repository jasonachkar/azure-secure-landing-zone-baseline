variable "name_prefix" {
  type        = string
  description = "Name prefix used for resource naming."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for networking resources."
}

variable "location" {
  type        = string
  description = "Azure region for networking resources."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to networking resources."
}

variable "hub_vnet_address_space" {
  type        = list(string)
  description = "Address space for the hub VNet."
}

variable "spoke_vnet_address_space" {
  type        = list(string)
  description = "Address space for the spoke VNet."
}

variable "hub_subnet_prefixes" {
  type        = map(string)
  description = "Subnet prefixes for hub VNet subnets."

  validation {
    condition = alltrue([
      for k in ["app", "data", "mgmt"] : contains(keys(var.hub_subnet_prefixes), k)
    ])
    error_message = "hub_subnet_prefixes must include app, data, and mgmt keys."
  }

  validation {
    condition     = !var.enable_firewall || contains(keys(var.hub_subnet_prefixes), "firewall")
    error_message = "hub_subnet_prefixes must include firewall when enable_firewall is true."
  }
}

variable "spoke_subnet_prefixes" {
  type        = map(string)
  description = "Subnet prefixes for spoke VNet subnets."

  validation {
    condition = alltrue([
      for k in ["app", "data", "mgmt"] : contains(keys(var.spoke_subnet_prefixes), k)
    ])
    error_message = "spoke_subnet_prefixes must include app, data, and mgmt keys."
  }
}

variable "admin_ip_allowlist" {
  type        = list(string)
  description = "CIDR list allowed to access management ports on mgmt subnets."
  default     = []
}

variable "enable_firewall" {
  type        = bool
  description = "Whether to deploy Azure Firewall in the hub VNet."
  default     = false
}
