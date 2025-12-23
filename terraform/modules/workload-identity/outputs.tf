output "identity_id" {
  description = "ID of the User Assigned Managed Identity"
  value       = try(azurerm_user_assigned_identity.service[0].id, null)
}

output "managed_identity_name" {
  value       = try(azurerm_user_assigned_identity.service[0].name, null)
  description = "Name of the Managed Identity (null if Azure access is not enabled)"
}

output "identity_client_id" {
  description = "Client ID of the User Assigned Managed Identity"
  value       = try(azurerm_user_assigned_identity.service[0].client_id, null)
}

output "identity_principal_id" {
  description = "Principal ID of the User Assigned Managed Identity"
  value       = try(azurerm_user_assigned_identity.service[0].principal_id, null)
}

output "service_account_name" {
  value       = kubernetes_service_account_v1.service.metadata[0].name
  description = "Name of the Kubernetes ServiceAccount"
}

output "service_account_namespace" {
  value       = kubernetes_service_account_v1.service.metadata[0].namespace
  description = "Namespace of the Kubernetes ServiceAccount"
}

output "federated_credential_id" {
  description = "ID of the Federated Identity Credential"
  value       = try(azurerm_federated_identity_credential.service[0].id, null)
}

output "federated_credential_name" {
  value       = try(azurerm_federated_identity_credential.service[0].name, null)
  description = "Name of the Federated Identity Credential (null if Azure access is not enabled)"
}

output "enabled_services" {
  value = {
    key_vault              = var.enable_key_vault_access
    storage                = var.enable_storage_access
    service_bus            = var.enable_service_bus_access
    additional_roles_count = length(var.additional_roles)
  }
  description = "Information about which Azure services are enabled for this identity"
}

