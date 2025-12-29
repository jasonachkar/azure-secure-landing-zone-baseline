variable "name_prefix" {
  type        = string
  description = "Name prefix used for RBAC resources."
}

variable "scope" {
  type        = string
  description = "Scope for role definitions and assignments."
}

variable "principal_object_id" {
  type        = string
  description = "Optional AAD principal object ID for role assignments."
  default     = null
  nullable    = true
}
