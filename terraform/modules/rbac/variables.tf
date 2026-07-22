variable "scope" {
  type        = string
  description = "Scope for role assignments."
}

variable "name_prefix" {
  type        = string
  description = "Name prefix retained for a consistent module interface."
}

variable "rbac_assignments" {
  type = list(object({
    principal_id    = string
    role_definition = string
    description     = optional(string, "")
  }))
  description = "List of principal-to-role mappings to assign at the configured scope."
  default     = []
}
