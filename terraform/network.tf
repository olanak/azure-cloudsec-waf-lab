resource "azurerm_resource_group" "rg" {
    name    = var.resource_group_name
    location = var.location
}

resource "azurerm_virtual_network" "vnet"{
    name                = "vnet-cloudsec-lab-dev"
    address_space       = ["10.0.0.0/16"]
    location = var.location
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "snet-appgw"{
    name                 = "snet-appgw"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "snet-backend"{
    name                 = "snet-backend"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "nsg-backend"{
    name                = "nsg-backend-cloudsec-lab-dev"
    location = var.location
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

resource "azurerm_subnet_network_security_group_association" "snet-backend-nsg" {
    subnet_id                 = azurerm_subnet.snet-backend.id
    network_security_group_id = azurerm_network_security_group.nsg-backend.id
}
