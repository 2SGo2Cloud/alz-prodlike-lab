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
  # }
}

provider "azurerm" {
  features {}
}

provider "azurerm" {
  alias = "management"
  features {}
}

provider "azurerm" {
  alias = "connectivity"
  features {}
}

provider "azurerm" {
  alias = "identity"
  features {}
}
