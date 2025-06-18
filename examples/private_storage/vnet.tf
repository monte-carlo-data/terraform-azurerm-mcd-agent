# VNet
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.suffix}"
  resource_group_name = azurerm_resource_group.mcd_agent_rg.name
  location            = azurerm_resource_group.mcd_agent_rg.location
  address_space       = var.vnet_address_space
}

# Default subnet
resource "azurerm_subnet" "default" {
  address_prefixes     = var.vnet_default_subnet_address_prefixes
  name                 = "DefaultSubnet"
  resource_group_name  = azurerm_resource_group.mcd_agent_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

# Agent subnet
resource "azurerm_subnet" "agent" {
  address_prefixes     = var.vnet_agent_subnet_address_prefixes
  name                 = "AgentSubnet"
  resource_group_name  = azurerm_resource_group.mcd_agent_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  delegation {
    name = "agent-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Private endpoints subnet
resource "azurerm_subnet" "private_endpoint" {
  address_prefixes     = var.vnet_private_endpoint_subnet_address_prefixes
  name                 = "PrivateEndpointsSubnet"
  resource_group_name  = azurerm_resource_group.mcd_agent_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}
