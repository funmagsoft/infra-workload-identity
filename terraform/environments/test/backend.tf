terraform {
  backend "azurerm" {
    resource_group_name  = "rg-ecare-test"
    storage_account_name = "tfstatehycomecaretest"
    container_name       = "tfstate"
    key                  = "infra-workload-identity/terraform.tfstate"
    use_azuread_auth     = true
  }
}
