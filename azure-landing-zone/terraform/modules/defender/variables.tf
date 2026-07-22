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
  description = "E.164 phone number for the Defender for Cloud security contact."
  nullable    = false

  validation {
    condition     = can(regex("^\\+[1-9][0-9]{7,14}$", var.security_contact_phone))
    error_message = "security_contact_phone must be a valid E.164 number, for example +14165550100."
  }
}

variable "enable_defender_plans" {
  type        = list(string)
  description = "Defender for Cloud resource types to enable. Set to [] in dev to avoid cost."
  default     = ["VirtualMachines", "StorageAccounts", "KeyVaults", "Arm", "Dns"]
}
