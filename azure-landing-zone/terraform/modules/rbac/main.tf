resource "azurerm_role_definition" "landing_zone_reader" {
  name        = "${var.name_prefix}-LandingZoneReader"
  scope       = var.scope
  description = "Read-only access to landing zone resources."

  permissions {
    actions = [
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Resources/subscriptions/resourceGroups/resources/read",
      "Microsoft.Network/*/read",
      "Microsoft.Compute/*/read",
      "Microsoft.Storage/*/read",
      "Microsoft.OperationalInsights/*/read",
      "Microsoft.Insights/*/read",
      "Microsoft.Authorization/policyAssignments/read",
      "Microsoft.Authorization/policyDefinitions/read"
    ]
    not_actions = []
  }

  assignable_scopes = [var.scope]
}

resource "azurerm_role_assignment" "landing_zone_reader" {
  count              = var.principal_object_id != null ? 1 : 0
  scope              = var.scope
  role_definition_id = azurerm_role_definition.landing_zone_reader.role_definition_resource_id
  principal_id       = var.principal_object_id
}

resource "azurerm_role_assignment" "reader" {
  count                = var.principal_object_id != null ? 1 : 0
  scope                = var.scope
  role_definition_name = "Reader"
  principal_id         = var.principal_object_id
}

resource "azurerm_role_assignment" "log_analytics_reader" {
  count                = var.principal_object_id != null ? 1 : 0
  scope                = var.scope
  role_definition_name = "Log Analytics Reader"
  principal_id         = var.principal_object_id
}
