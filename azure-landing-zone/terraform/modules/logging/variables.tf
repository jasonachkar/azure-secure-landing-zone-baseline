variable "name_prefix" {
  type        = string
  description = "Name prefix used for resource naming."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for logging resources."
}

variable "location" {
  type        = string
  description = "Azure region for logging resources."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to logging resources."
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
  description = "Storage account name for diagnostics storage."
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID used by the diagnostics storage private endpoint."
}

variable "virtual_network_ids" {
  type        = map(string)
  description = "Virtual network IDs linked to the storage private DNS zone."
}

variable "customer_managed_key_id" {
  type        = string
  description = "Versioned Key Vault key ID used for storage encryption."
}

variable "customer_managed_key_identity_id" {
  type        = string
  description = "User-assigned identity ID authorized to use the storage encryption key."
}
