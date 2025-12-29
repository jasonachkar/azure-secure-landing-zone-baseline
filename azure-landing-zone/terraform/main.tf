# Used to scope policy and RBAC assignments at the subscription level.
data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "core" {
  name     = "${local.name_prefix}-rg-core"
  location = var.location
  tags     = local.tags
}

resource "azurerm_resource_group" "network" {
  name     = "${local.name_prefix}-rg-network"
  location = var.location
  tags     = local.tags
}

module "logging" {
  source               = "./modules/logging"
  name_prefix          = local.name_prefix
  resource_group_name  = azurerm_resource_group.core.name
  location             = var.location
  tags                 = local.tags
  log_retention_days   = var.log_retention_days
  storage_account_name = local.storage_account_name
}

module "networking" {
  source                  = "./modules/networking"
  name_prefix             = local.name_prefix
  resource_group_name     = azurerm_resource_group.network.name
  location                = var.location
  tags                    = local.tags
  hub_vnet_address_space  = var.hub_vnet_address_space
  spoke_vnet_address_space = var.spoke_vnet_address_space
  hub_subnet_prefixes     = var.hub_subnet_prefixes
  spoke_subnet_prefixes   = var.spoke_subnet_prefixes
  admin_ip_allowlist      = var.admin_ip_allowlist
  enable_firewall         = var.enable_firewall
}

module "policy" {
  source                  = "./modules/policy"
  name_prefix             = local.name_prefix
  scope                   = data.azurerm_subscription.current.id
  # Policy JSON stays in /policies and is registered here to keep IaC and rules in sync.
  policy_path             = "${path.module}/../policies"
  allowed_locations       = local.allowed_locations
  policy_enforcement_mode = var.policy_enforcement_mode
  allow_public_ip         = var.allow_public_ip
  admin_ip_allowlist      = var.admin_ip_allowlist
}

module "rbac" {
  source               = "./modules/rbac"
  name_prefix          = local.name_prefix
  scope                = data.azurerm_subscription.current.id
  principal_object_id  = var.principal_object_id
}

locals {
  # Build maps to drive diagnostics across VNets and NSGs without duplicating blocks.
  vnet_ids = {
    hub   = module.networking.hub_vnet_id
    spoke = module.networking.spoke_vnet_id
  }

  nsg_ids = module.networking.nsg_ids
}

# Diagnostics for VNets
data "azurerm_monitor_diagnostic_categories" "vnet" {
  for_each    = local.vnet_ids
  resource_id = each.value
}

resource "azurerm_monitor_diagnostic_setting" "vnet" {
  for_each                   = local.vnet_ids
  name                       = "${local.name_prefix}-diag-vnet-${each.key}"
  target_resource_id         = each.value
  log_analytics_workspace_id = module.logging.log_analytics_workspace_id

  # Enable all supported logs/metrics for baseline visibility.

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.vnet[each.key].logs
    content {
      category = enabled_log.value.category
      enabled  = true
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.vnet[each.key].metrics
    content {
      category = metric.value.category
      enabled  = true
    }
  }
}

# Diagnostics for NSGs
data "azurerm_monitor_diagnostic_categories" "nsg" {
  for_each    = local.nsg_ids
  resource_id = each.value
}

resource "azurerm_monitor_diagnostic_setting" "nsg" {
  for_each                   = local.nsg_ids
  name                       = "${local.name_prefix}-diag-nsg-${each.key}"
  target_resource_id         = each.value
  log_analytics_workspace_id = module.logging.log_analytics_workspace_id

  # Enable all supported logs/metrics for baseline visibility.

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.nsg[each.key].logs
    content {
      category = enabled_log.value.category
      enabled  = true
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.nsg[each.key].metrics
    content {
      category = metric.value.category
      enabled  = true
    }
  }
}

# Diagnostics for Storage Account
data "azurerm_monitor_diagnostic_categories" "storage" {
  resource_id = module.logging.storage_account_id
}

resource "azurerm_monitor_diagnostic_setting" "storage" {
  name                       = "${local.name_prefix}-diag-storage"
  target_resource_id         = module.logging.storage_account_id
  log_analytics_workspace_id = module.logging.log_analytics_workspace_id

  # Enable all supported logs/metrics for baseline visibility.

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.storage.logs
    content {
      category = enabled_log.value.category
      enabled  = true
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.storage.metrics
    content {
      category = metric.value.category
      enabled  = true
    }
  }
}

# Diagnostics for Log Analytics Workspace (sent to Storage)
data "azurerm_monitor_diagnostic_categories" "law" {
  resource_id = module.logging.log_analytics_workspace_id
}

resource "azurerm_monitor_diagnostic_setting" "law" {
  name               = "${local.name_prefix}-diag-law"
  target_resource_id = module.logging.log_analytics_workspace_id
  # Log Analytics cannot send diagnostics to itself; use storage for its own diagnostics.
  storage_account_id = module.logging.storage_account_id

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.law.logs
    content {
      category = enabled_log.value.category
      enabled  = true
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.law.metrics
    content {
      category = metric.value.category
      enabled  = true
    }
  }
}
