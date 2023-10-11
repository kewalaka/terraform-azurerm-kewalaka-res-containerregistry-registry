output "resource" {
  value       = azurerm_container_registry.this
  description = "The Container Registry resource."
}

output "private_endpoints" {
  value       = azurerm_private_endpoint.this
  description = "A map of private endpoints. The map key is the supplied input to var.private_endpoints. The map value is the entire azurerm_private_endpoint resource."
}
