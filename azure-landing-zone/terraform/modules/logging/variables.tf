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
  description = "Log Analytics retention in days."
  default     = 30
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name for diagnostics storage."
}
