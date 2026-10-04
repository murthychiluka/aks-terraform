terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = "2213e8b1-dbc7-4d54-8aff-b5e315df5e5b"
  resource_provider_registrations = "none"
}

# Existing Resource Group
data "azurerm_resource_group" "aks_rg" {
  name = "1-fcdbd8dd-playground-sandbox"
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "aks-vnet"
  location            = data.azurerm_resource_group.aks_rg.location
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  address_space       = ["10.0.0.0/16"]
}

# Subnet
resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = data.azurerm_resource_group.aks_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "demo-aks"
  location            = data.azurerm_resource_group.aks_rg.location
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  dns_prefix          = "demoaks"

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_D2s_v3"
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"

    service_cidr   = "172.16.0.0/16"
    dns_service_ip = "172.16.0.10"
  }

  tags = {
    Environment = "Dev"
  }
}
