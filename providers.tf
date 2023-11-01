terraform {
  required_version = "~> 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.76"
    }
  }

  # backend "azurerm" {
  #   resource_group_name  = "##tfstate-resource-group-name##"
  #   storage_account_name = "##tfstate-storage-account-name##"
  #   container_name       = "##tfstate-container-name##"
  #   key                  = "terraformstate.tfstate"
  #   subscription_id      = "##tfstate-subscription-id##"
  #   tenant_id            = "##tfstate-tenant-id##"
  #   client_id            = "##uai-client-id##"
  #   use_azuread_auth     = true
  # }
}

provider "azurerm" {
  features {}
  subscription_id = "" # REPLACE ME
}

provider "azurerm" {
  alias = "management"
  features {}
  subscription_id = "" # REPLACE ME
}

provider "azurerm" {
  alias = "connectivity"
  features {}
  subscription_id = "" # REPLACE ME
}

provider "azurerm" {
  alias = "identity"
  features {}
  subscription_id = "" # REPLACE ME
}
