output "role_assignment_ids" {
  description = "Map of role assignment resource IDs keyed by principal-role pair."
  value       = { for key, assignment in azurerm_role_assignment.this : key => assignment.id }
}
