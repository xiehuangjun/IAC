# Configure the Microsoft Azure Provider

terraform {
    required_providers {
        azurerm = {
            source = "hashicorp/azurerm"
            version = "~> 2.65"
        }
    }

    required_version = ">=1.1.0"
}

provider "azurerm"{
    features {}
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "SAP" {
    name     = var.resource_group_name
    location = var.location

    tags = {
        environment = "primary region"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "PRD_Vnet" {
    name                = "PRD_Vnet"
    address_space       = ["10.1.0.0/16"]
    location            = var.location
    resource_group_name = azurerm_resource_group.SAP.name

    tags = {
        environment = "PRD"
    }
}