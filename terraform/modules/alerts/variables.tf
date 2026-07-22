variable "name_prefix" {
  type        = string
  description = "Name prefix used for alert resources."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for the action group and activity log alerts."
}

variable "subscription_id" {
  type        = string
  description = "Subscription resource ID used as the activity log alert scope."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to alert resources."
}

variable "key_vault_id" {
  type        = string
  description = "Optional Key Vault resource ID for access-policy change alerts."
  default     = null
  nullable    = true
}

variable "alert_email_addresses" {
  type        = list(string)
  description = "Email addresses subscribed to the security action group."
  default     = []
}
