locals {
  name_prefix = lower(regexreplace("${var.project_name}-${var.environment}", "[^a-zA-Z0-9-]", ""))

  allowed_locations = length(var.allowed_locations) > 0 ? var.allowed_locations : [var.location]

  tags = merge(var.tags, {
    project = var.project_name
  })

  storage_name_base    = regexreplace(lower("${var.project_name}${var.environment}logs"), "[^a-z0-9]", "")
  storage_account_name = var.storage_account_name != null ? var.storage_account_name : substr(local.storage_name_base, 0, 24)
}
