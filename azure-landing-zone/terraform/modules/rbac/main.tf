resource "azurerm_role_assignment" "this" {
  for_each = {
    for assignment in var.rbac_assignments :
    "${assignment.principal_id}-${replace(lower(assignment.role_definition), " ", "-")}" => assignment
  }

  scope                = var.scope
  role_definition_name = each.value.role_definition
  principal_id         = each.value.principal_id
  description          = each.value.description
}
