terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Remote state: infra-foundation
data "terraform_remote_state" "foundation" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-ecare-${var.environment}"
    storage_account_name = "tfstatehycomecare${var.environment}"
    container_name       = "tfstate"
    key                  = "infra-foundation/terraform.tfstate"
    use_azuread_auth     = true
  }
}

# Remote state: infra-platform
data "terraform_remote_state" "platform" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-ecare-${var.environment}"
    storage_account_name = "tfstatehycomecare${var.environment}"
    container_name       = "tfstate"
    key                  = "infra-platform/terraform.tfstate"
    use_azuread_auth     = true
  }
}

data "azurerm_resource_group" "main" {
  name = "rg-${var.project_name}-${var.environment}"
}

locals {
  common_tags = {
    Environment   = var.environment
    Project       = var.project_name
    ManagedBy     = "Terraform"
    Phase         = "WorkloadIdentity"
    GitRepository = "infra-workload-identity"
    TerraformPath = "terraform/environments/${var.environment}"
  }

  services_expanded = {
    for name, cfg in local.services :
    name => merge(cfg, {
      key_vault_id             = cfg.enable_key_vault_access ? data.terraform_remote_state.platform.outputs.key_vault_id : null
      storage_account_id       = cfg.enable_storage_access ? data.terraform_remote_state.platform.outputs.storage_account_id : null
      service_bus_namespace_id = cfg.enable_service_bus_access ? data.terraform_remote_state.platform.outputs.service_bus_namespace_id : null
    })
  }
}

locals {
  aks_kube_config = yamldecode(data.terraform_remote_state.platform.outputs.aks_kube_config)
}

provider "kubernetes" {
  host                   = local.aks_kube_config["clusters"][0]["cluster"]["server"]
  client_certificate     = base64decode(local.aks_kube_config["users"][0]["user"]["client-certificate-data"])
  client_key             = base64decode(local.aks_kube_config["users"][0]["user"]["client-key-data"])
  cluster_ca_certificate = base64decode(local.aks_kube_config["clusters"][0]["cluster"]["certificate-authority-data"])
}

module "workload_identity" {
  for_each = local.services_expanded

  source = "../../modules/workload-identity"

  project_name        = var.project_name
  service_name        = each.key
  environment         = var.environment
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  namespace       = data.terraform_remote_state.platform.outputs.aks_namespace_name
  aks_oidc_issuer = data.terraform_remote_state.platform.outputs.aks_oidc_issuer_url

  repo   = each.value.repo
  branch = lookup(each.value, "branch", "main")

  enable_key_vault_access   = lookup(each.value, "enable_key_vault_access", false)
  enable_storage_access     = lookup(each.value, "enable_storage_access", false)
  enable_service_bus_access = lookup(each.value, "enable_service_bus_access", false)

  key_vault_id             = each.value.key_vault_id
  storage_account_id       = each.value.storage_account_id
  service_bus_namespace_id = each.value.service_bus_namespace_id

  additional_roles = lookup(each.value, "additional_roles", [])

  tags = local.common_tags
}


