terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.8.0"

  # The state file will live securely in this Azure storage container
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstate1788183733" # Must be globally unique
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
    use_oidc             = true

  }
}


provider "azurerm" {
  features {}
}

