variable "scope" {
  type        = string
  description = "Subscription scope for Defender for Cloud configuration."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics Workspace resource ID connected to Defender for Cloud."
  default     = null
  nullable    = true
}

variable "security_contact_email" {
  type        = string
  description = "Email address that receives Defender for Cloud security notifications."
  default     = null
  nullable    = true
}

variable "security_contact_phone" {
  type        = string
  description = "Optional phone number for the Defender for Cloud security contact."
  default     = ""
}

variable "enable_defender_plans" {
  type        = list(string)
  description = "Defender for Cloud resource types to enable. Set to [] in dev to avoid cost."
  default     = ["VirtualMachines", "StorageAccounts", "KeyVaults", "Arm", "Dns"]
}
