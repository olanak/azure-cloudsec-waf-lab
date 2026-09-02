#the main resource group to hold all the resources for the lab, including the virtual network, subnets, and security groups
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

#the virtual network with a /16 address space, and two subnets: one for the application gateway and one for the backend VMs
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-cloudsec-lab-dev"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

#the subnet for the application gateway with a /24 address space
resource "azurerm_subnet" "snet-appgw" {
  #checkov:skip=CKV2_AZURE_31: NSG omitted to avoid conflicting with strict AppGW v2 management port requirements.
  name                 = "snet-appgw"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

#the subnet for the backend VMs with a /24 address space
resource "azurerm_subnet" "snet-backend" {
  name                 = "snet-backend"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

#the network security group for the backend subnet, allowing inbound traffic from the application gateway on port 80
resource "azurerm_network_security_group" "nsg-backend" {
  name                = "nsg-backend-cloudsec-lab-dev"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  security_rule {
    name                       = "Allow-AppGateway-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "10.0.2.0/24"
  }
}

#associate the network security group with the backend subnet
resource "azurerm_subnet_network_security_group_association" "snet-backend-nsg" {
  subnet_id                 = azurerm_subnet.snet-backend.id
  network_security_group_id = azurerm_network_security_group.nsg-backend.id
}
