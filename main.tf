resource "azurerm_container_registry" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  sku                           = var.sku
  location                      = var.location
  admin_enabled                 = var.admin_enabled
  tags                          = var.tags
  public_network_access_enabled = var.public_network_access_enabled
  quarantine_policy_enabled     = var.quarantine_policy_enabled
  zone_redundancy_enabled       = var.zone_redundancy_enabled
  export_policy_enabled         = var.export_policy_enabled
  anonymous_pull_enabled        = var.anonymous_pull_enabled
  data_endpoint_enabled         = var.data_endpoint_enabled
  network_rule_bypass_option    = var.network_rule_bypass_option

  dynamic "georeplications" {
    for_each = var.georeplications != null ? { this = var.georeplications } : {}
    content {
      location                  = georeplications.value.location
      regional_endpoint_enabled = georeplications.value.regional_endpoint_enabled
      zone_redundancy_enabled   = georeplications.value.zone_redundancy_enabled
      tags                      = georeplications.value.tags
    }
  }

  # Only one network_rule_set block is allowed.
  # Create it if the variable is not null.
  dynamic "network_rule_set" {
    for_each = var.network_rule_set != null ? { this = var.network_rule_set } : {}
    content {
      default_action  = network_rule_set.value.default_action
      ip_rule         = network_rule_set.value.ip_rule
      virtual_network = network_rule_set.value.virtual_network
    }
  }

  dynamic "retention_policy" {
    for_each = var.retention_policy != null ? { this = var.retention_policy } : {}
    content {
      days    = retention_policy.value.days
      enabled = retention_policy.value.enabled
    }
  }

  dynamic "identity" {
    for_each = var.identity != null ? { this = var.identity } : {}
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  lifecycle {
    precondition {
      condition     = var.zone_redundancy_enabled && lower(var.sku) == "premium"
      error_message = "The Premium SKU is required if zone redundancy is enabled."
    }
    precondition {
      condition     = var.network_rule_set != [] && lower(var.sku) == "premium"
      error_message = "The Premium SKU is required if a network rule set is defined."
    }
  }
}

resource "azurerm_management_lock" "this" {
  count      = var.lock.kind != "None" ? 1 : 0
  name       = coalesce(var.lock.name, "lock-${var.name}")
  scope      = azurerm_container_registry.this.id
  lock_level = var.lock.kind
}

resource "azurerm_role_assignment" "this" {
  for_each                               = var.role_assignments
  scope                                  = azurerm_container_registry.this.id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  principal_id                           = each.value.principal_id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
}
