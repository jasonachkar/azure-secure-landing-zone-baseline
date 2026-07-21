variable "name_prefix" {
  type        = string
  description = "Name prefix used for the Key Vault name."
}

variable "location" {
  type        = string
  description = "Azure region for the Key Vault."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for the Key Vault."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the Key Vault."
}

variable "admin_ip_allowlist" {
  type        = list(string)
  description = "CIDR blocks included in the Key Vault network ACL."
  default     = []
}
