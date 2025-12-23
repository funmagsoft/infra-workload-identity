output "identity_id" {
  description = "ID of the User Assigned Managed Identity"
  value       = try(azurerm_user_assigned_identity.service[0].id, null)
}

output "identity_client_id" {
  description = "Client ID of the User Assigned Managed Identity"
  value       = try(azurerm_user_assigned_identity.service[0].client_id, null)
}

output "identity_principal_id" {
  description = "Principal ID of the User Assigned Managed Identity"
  value       = try(azurerm_user_assigned_identity.service[0].principal_id, null)
}

output "federated_credential_id" {
  description = "ID of the Federated Identity Credential"
  value       = try(azurerm_federated_identity_credential.service[0].id, null)
}


