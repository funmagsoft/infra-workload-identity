# Workload Identity Module

Creates a User Assigned Managed Identity (UAMI), GitHub OIDC Federated Identity Credential (FIC), and optional RBAC assignments for a single service.

## Resources
- User Assigned Managed Identity (UAMI) — conditional on any access/role being needed
- Federated Identity Credential (GitHub OIDC) bound to the UAMI
- RBAC role assignments (conditional):
  - Key Vault: `Key Vault Secrets User`
  - Storage: `Storage Blob Data Contributor`
  - Service Bus: `Azure Service Bus Data Owner`
  - Additional custom roles (`role_definition_name`, `scope`)

## Inputs (key)
- `project_name` (string)
- `service_name` (string)
- `environment` (string)
- `resource_group_name`, `location` (string)
- `repo` (string, GitHub `org/repo`)
- `branch` (string, default `main`) — for FIC subject
- Flags: `enable_key_vault_access`, `enable_storage_access`, `enable_service_bus_access` (bool)
- IDs: `key_vault_id`, `storage_account_id`, `service_bus_namespace_id`
- `additional_roles` (list of `{ role, scope }`)
- `tags` (map(string))

## Outputs
- `identity_id`
- `identity_client_id`
- `identity_principal_id`
- `federated_credential_id`

## Usage (example)
```hcl
module "workload_identity" {
  source = "../../modules/workload-identity"

  project_name        = "ecare"
  service_name        = "billing"
  environment         = "dev"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  repo   = "funmagsoft/billing-service"
  branch = "main"

  enable_key_vault_access   = true
  enable_storage_access     = true
  enable_service_bus_access = false

  key_vault_id       = data.terraform_remote_state.platform.outputs.key_vault_id
  storage_account_id = data.terraform_remote_state.platform.outputs.storage_account_id

  additional_roles = []

  tags = local.common_tags
}
```

## Notes
- FIC uses GitHub OIDC: issuer `https://token.actions.githubusercontent.com`, subject `repo:{repo}:ref:refs/heads/{branch}`.
- If a flag is true but the corresponding ID is null, a precondition will fail.
- Tags include `Environment`, `Project`, `Service`, `ManagedBy=Terraform`, `Phase=WorkloadIdentity`.

