resource "azurerm_security_center_subscription_pricing" "this" {
  for_each      = toset(var.enable_defender_plans)
  tier          = "Standard"
  resource_type = each.value
}

resource "azurerm_security_center_workspace" "this" {
  count        = var.log_analytics_workspace_id != null ? 1 : 0
  scope        = var.scope
  workspace_id = var.log_analytics_workspace_id
}

resource "azurerm_security_center_contact" "this" {
  count               = var.security_contact_email != null ? 1 : 0
  name                = "default"
  email               = var.security_contact_email
  phone               = var.security_contact_phone
  alert_notifications = true
  alerts_to_admins    = true
}
