resource "azurerm_monitor_action_group" "security" {
  name                = "${var.name_prefix}-ag-security"
  resource_group_name = var.resource_group_name
  short_name          = "sec-alerts"
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = var.alert_email_addresses
    content {
      name          = "email-${email_receiver.key}"
      email_address = email_receiver.value
    }
  }
}

resource "azurerm_monitor_activity_log_alert" "nsg_change" {
  name                = "${var.name_prefix}-alert-nsg-change"
  resource_group_name = var.resource_group_name
  scopes              = [var.subscription_id]
  description         = "NSG security rule created, updated, or deleted."
  tags                = var.tags

  criteria {
    category       = "Administrative"
    operation_name = "Microsoft.Network/networkSecurityGroups/securityRules/write"
  }

  action {
    action_group_id = azurerm_monitor_action_group.security.id
  }
}

resource "azurerm_monitor_activity_log_alert" "rbac_change" {
  name                = "${var.name_prefix}-alert-rbac-change"
  resource_group_name = var.resource_group_name
  scopes              = [var.subscription_id]
  description         = "Subscription-level role assignment change — privilege escalation detection."
  tags                = var.tags

  criteria {
    category       = "Administrative"
    operation_name = "Microsoft.Authorization/roleAssignments/write"
  }

  action {
    action_group_id = azurerm_monitor_action_group.security.id
  }
}

resource "azurerm_monitor_activity_log_alert" "policy_change" {
  name                = "${var.name_prefix}-alert-policy-change"
  resource_group_name = var.resource_group_name
  scopes              = [var.subscription_id]
  description         = "Azure Policy assignment created or deleted."
  tags                = var.tags

  criteria {
    category       = "Administrative"
    operation_name = "Microsoft.Authorization/policyAssignments/write"
  }

  action {
    action_group_id = azurerm_monitor_action_group.security.id
  }
}

resource "azurerm_monitor_activity_log_alert" "kv_policy_change" {
  count               = var.key_vault_id != null ? 1 : 0
  name                = "${var.name_prefix}-alert-kv-policy-change"
  resource_group_name = var.resource_group_name
  scopes              = [var.key_vault_id]
  description         = "Key Vault access policy modified."
  tags                = var.tags

  criteria {
    category       = "Administrative"
    operation_name = "Microsoft.KeyVault/vaults/accessPolicies/write"
  }

  action {
    action_group_id = azurerm_monitor_action_group.security.id
  }
}
