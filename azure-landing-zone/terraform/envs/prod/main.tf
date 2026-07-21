terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "project_name" {
  type        = string
  description = "Short project name used for resource naming."
}

variable "environment" {
  type        = string
  description = "Deployment environment name."
  default     = "prod"
}

variable "location" {
  type        = string
  description = "Primary Azure region for deployment."
}

variable "allowed_locations" {
  type        = list(string)
  description = "Allowed Azure regions for policy enforcement."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
}

variable "admin_ip_allowlist" {
  type        = list(string)
  description = "Optional list of CIDR ranges allowed to access management ports (SSH/RDP)."
  default     = []
}

variable "enable_firewall" {
  type        = bool
  description = "Deploy Azure Firewall in the hub VNet."
  default     = true
}

variable "rbac_assignments" {
  type = list(object({
    principal_id    = string
    role_definition = string
    description     = optional(string, "")
  }))
  description = "List of AAD principal-to-role mappings at subscription scope."
  default     = []
}

variable "policy_enforcement_mode" {
  type        = string
  description = "Policy enforcement mode for deny-based policies (Deny or Audit)."
  default     = "Deny"
}

variable "allow_public_ip" {
  type        = bool
  description = "Allow public IP creation by setting the policy effect to Audit for dev or lab scenarios."
  default     = false
}

variable "hub_vnet_address_space" {
  type        = list(string)
  description = "Address space for the hub VNet."
  default     = ["10.0.0.0/16"]
}

variable "spoke_vnet_address_space" {
  type        = list(string)
  description = "Address space for the spoke VNet."
  default     = ["10.1.0.0/16"]
}

variable "hub_subnet_prefixes" {
  type        = map(string)
  description = "Subnet prefixes for hub VNet subnets."
  default = {
    app      = "10.0.1.0/24"
    data     = "10.0.2.0/24"
    mgmt     = "10.0.3.0/24"
    firewall = "10.0.254.0/24"
  }
}

variable "spoke_subnet_prefixes" {
  type        = map(string)
  description = "Subnet prefixes for spoke VNet subnets."
  default = {
    app  = "10.1.1.0/24"
    data = "10.1.2.0/24"
    mgmt = "10.1.3.0/24"
  }
}

variable "log_retention_days" {
  type        = number
  description = "Log Analytics Workspace retention in days."
  default     = 90

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "log_retention_days must be between 30 and 730."
  }
}

variable "storage_account_name" {
  type        = string
  description = "Optional storage account name override."
  default     = null
  nullable    = true
}

variable "enable_defender_plans" {
  type        = list(string)
  description = "Defender for Cloud resource types to enable at Standard tier."
  default     = ["VirtualMachines", "StorageAccounts", "KeyVaults", "Arm", "Dns"]
}

variable "security_contact_email" {
  type        = string
  description = "Email address that receives Defender for Cloud security notifications."
  default     = null
  nullable    = true
}

variable "alert_email_addresses" {
  type        = list(string)
  description = "Email addresses that receive Azure Monitor security activity alerts."
  default     = []
}

module "landing_zone" {
  # Environment wrapper passes prod-specific variables into the root composition.
  source                   = "../.."
  project_name             = var.project_name
  environment              = var.environment
  location                 = var.location
  allowed_locations        = var.allowed_locations
  tags                     = var.tags
  admin_ip_allowlist       = var.admin_ip_allowlist
  enable_firewall          = var.enable_firewall
  rbac_assignments         = var.rbac_assignments
  policy_enforcement_mode  = var.policy_enforcement_mode
  allow_public_ip          = var.allow_public_ip
  hub_vnet_address_space   = var.hub_vnet_address_space
  spoke_vnet_address_space = var.spoke_vnet_address_space
  hub_subnet_prefixes      = var.hub_subnet_prefixes
  spoke_subnet_prefixes    = var.spoke_subnet_prefixes
  log_retention_days       = var.log_retention_days
  storage_account_name     = var.storage_account_name
  enable_defender_plans    = var.enable_defender_plans
  security_contact_email   = var.security_contact_email
  alert_email_addresses    = var.alert_email_addresses
}
