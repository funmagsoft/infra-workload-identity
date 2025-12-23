terraform {
  backend "azurerm" {
    resource_group_name  = "rg-ecare-prod"
    storage_account_name = "tfstatehycomecareprod"
    container_name       = "tfstate"
    key                  = "infra-workload-identity/terraform.tfstate"
    use_azuread_auth     = true
  }
}
