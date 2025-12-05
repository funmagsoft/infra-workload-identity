terraform {
  backend "azurerm" {
    resource_group_name  = "rg-ecare-dev"
    storage_account_name = "tfstatemagsoftecaredev"
    container_name       = "tfstate"
    key                  = "infra-workload-identity/terraform.tfstate"
    use_azuread_auth     = true
  }
}
