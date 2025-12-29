variable "project_name" {
  type        = string
  description = "Short project name used for resource naming."
}

variable "environment" {
  type        = string
  description = "Deployment environment name (e.g., dev, prod)."

  validation {
    condition     = length(var.environment) > 0
    error_message = "environment must not be empty."
  }
}

variable "location" {
  type        = string
  description = "Primary Azure region for deployment."
}

variable "allowed_locations" {
  type        = list(string)
  description = "Allowed Azure regions for policy enforcement. Defaults to the primary location if empty."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources. Must include owner, environment, costCenter, dataClassification."

  # Tag presence is validated here and enforced again via policy for defense in depth.
  validation {
    condition = alltrue([
      for k in ["owner", "environment", "costCenter", "dataClassification"] : contains(keys(var.tags), k)
    ])
    error_message = "tags must include owner, environment, costCenter, and dataClassification."
  }
}

variable "admin_ip_allowlist" {
  type        = list(string)
  description = "Optional list of CIDR ranges allowed to access management ports (SSH/RDP)."
  default     = []
}

variable "enable_firewall" {
  type        = bool
  description = "Whether to deploy Azure Firewall in the hub VNet."
  default     = false
}

variable "principal_object_id" {
  type        = string
  description = "Optional AAD principal object ID for role assignments."
  default     = null
  nullable    = true
}

variable "policy_enforcement_mode" {
  type        = string
  description = "Policy enforcement mode for deny-based policies (Deny or Audit)."
  default     = "Deny"

  validation {
    condition     = contains(["Deny", "Audit"], var.policy_enforcement_mode)
    error_message = "policy_enforcement_mode must be either Deny or Audit."
  }
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
  description = "Subnet prefixes for hub VNet subnets (app, data, mgmt, firewall)."
  default = {
    app      = "10.0.1.0/24"
    data     = "10.0.2.0/24"
    mgmt     = "10.0.3.0/24"
    firewall = "10.0.254.0/24"
  }
}

variable "spoke_subnet_prefixes" {
  type        = map(string)
  description = "Subnet prefixes for spoke VNet subnets (app, data, mgmt)."
  default = {
    app  = "10.1.1.0/24"
    data = "10.1.2.0/24"
    mgmt = "10.1.3.0/24"
  }
}

variable "log_retention_days" {
  type        = number
  description = "Log Analytics retention in days."
  default     = 30
}

variable "storage_account_name" {
  type        = string
  description = "Optional storage account name override (3-24 lowercase alphanumeric)."
  # Storage account names are global; override this if the generated name collides.
  default     = null
  nullable    = true
}
