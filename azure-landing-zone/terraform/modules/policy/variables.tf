variable "name_prefix" {
  type        = string
  description = "Name prefix used for policy assignment names."
}

variable "scope" {
  type        = string
  description = "Scope for policy assignments (subscription or management group ID)."
}

variable "policy_path" {
  type        = string
  description = "Path to policy definition JSON files."
}

variable "allowed_locations" {
  type        = list(string)
  description = "Allowed Azure locations for the allowed-locations policy."
}

variable "policy_enforcement_mode" {
  type        = string
  description = "Effect for deny-based policies (Deny or Audit)."
}

variable "allow_public_ip" {
  type        = bool
  description = "If true, the public IP policy is assigned in Audit mode."
  default     = false
}

variable "admin_ip_allowlist" {
  type        = list(string)
  description = "Optional list of allowed admin IPs for SSH/RDP policy exceptions."
  default     = []
}
