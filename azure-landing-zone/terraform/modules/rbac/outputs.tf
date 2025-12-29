output "role_definition_id" {
  description = "Custom LandingZoneReader role definition resource ID."
  value       = azurerm_role_definition.landing_zone_reader.role_definition_resource_id
}
