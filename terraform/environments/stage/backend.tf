terraform {
  backend "azurerm" {
    resource_group_name  = "rg-ecare-stage"
    storage_account_name = "tfstatemagsoftecarestage"
    container_name       = "tfstate"
    key                  = "infra-workload-identity/terraform.tfstate"
    use_azuread_auth     = true
  }
}
