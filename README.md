# Infra Workload Identity

Workload Identities (UAMI), Federated Identity Credentials (FIC), and RBAC for application services running on AKS in the ecare project.

## Purpose

This repository contains Terraform code and helper scripts to:
- Create User Assigned Managed Identities (UAMI) per service.
- Create GitHub OIDC Federated Identity Credentials (FIC) per service to enable passwordless deployments from GitHub Actions.
- Assign RBAC for services to Azure resources (Key Vault, Storage, Service Bus, plus optional custom roles).
- Keep configuration per environment (dev, test, stage, prod).

## Structure

```
terraform/
├── modules/
│   └── workload-identity/   # UAMI + FIC + RBAC
└── environments/
    ├── dev/
    ├── test/
    ├── stage/
    └── prod/

scripts/
├── common.sh
└── add-service.sh
```

## What is created per service

For each service declared in `terraform/environments/<env>/services.tf`:
- **User Assigned Managed Identity (UAMI)**  
  Name: `mi-ecare-<service>-<env>`
- **Federated Identity Credential (FIC)** for GitHub OIDC  
  Issuer: `https://token.actions.githubusercontent.com`  
  Subject: `repo:{org}/{repo}:ref:refs/heads/{branch}` (default branch = `main`)
- **RBAC assignments** (conditional, based on flags):
  - Key Vault: `Key Vault Secrets User` on `key_vault_id`
  - Storage: `Storage Blob Data Contributor` on `storage_account_id`
  - Service Bus: `Azure Service Bus Data Owner` on `service_bus_namespace_id`
  - Additional roles: any custom `{ role, scope }` entries

All tags are aligned with the platform/foundation conventions (`Environment`, `Project`, `ManagedBy`, `Phase=WorkloadIdentity`, `GitRepository`, `Service`).

## Configuration per environment

Each environment has a `services.tf` with a `local.services` map. Example (dev):

```hcl
locals {
  services = {
    billing = {
      repo                    = "funmagsoft/billing-service"
      branch                  = "main"
      enable_key_vault_access = true
      enable_storage_access   = true
      enable_service_bus_access = false
      additional_roles        = []
    }
  }
}
```

IDs of KV/Storage/SB are pulled from `infra-platform` remote state in `main.tf`, so you only need to set the feature flags per service. If a flag is `true` but the corresponding ID is missing, a precondition will fail.

## Scripts

### add-service.sh

Add or update a service entry in `services.tf`:

```
scripts/add-service.sh --env dev --service billing --repo funmagsoft/billing-service --kv --storage --sb
```

Options:
- `--env dev|test|stage|prod|all` – target environment(s)
- `--service <name>` – logical service name
- `--repo <org/repo>` – GitHub repo for OIDC subject
- `--kv` – enable Key Vault access
- `--storage` – enable Storage access
- `--sb` – enable Service Bus access
- `--dry-run` – show the resulting `services.tf` without writing

Behavior:
- Updates `terraform/environments/<env>/services.tf` (inserts/replaces a block `# Service: <name>`).
- In `--dry-run` mode, prints the would-be file content and does not write.
- If `services.tf` is missing and `--dry-run`, it only prints a template; otherwise it creates a template and appends the service.

### common.sh

Shared helpers: `parse_dry_run`, logging, optional `.env` loading (ignored if missing).

## Running Terraform

1. Go to the environment directory, e.g.:
   ```bash
   cd terraform/environments/dev
   ```
2. Configure services in `services.tf` (or via `add-service.sh`).
3. Initialize:
   ```bash
   terraform init
   ```
4. Plan / apply:
   ```bash
   terraform plan
   terraform apply
   ```

## Backends and Remote State

- Backends use the same naming as foundation/platform: `tfstatehycomecare{env}` in `rg-ecare-{env}`, container `tfstate`.
- Remote states:
  - `infra-foundation/terraform.tfstate`
  - `infra-platform/terraform.tfstate`
  These provide RG/location and IDs of KV/Storage/SB used for RBAC scopes.

## Important Notes

- Do not commit `terraform.tfvars` or `.tfstate`. State is remote; config stays in `services.tf`.
- Ensure `az login` and correct subscription before running Terraform, or use GitHub OIDC in CI.
- RBAC scopes rely on outputs from `infra-platform`. Keep platform deployed and outputs available for each env.

## Cleanup

To remove identities/RBAC for an environment:
```
cd terraform/environments/<env>
terraform destroy
```
Be mindful of shared platform resources; the destroy will remove only the identities/RBAC created here.
