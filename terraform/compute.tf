# Terraform configuration for Azure resources
#availability set for the VMs to tolerate physical hardware failures and maintenance events
resource "azurerm_availability_set" "aset-dvwa" {
  name                         = "aset-dvwa-cloudsec-lab-dev"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

#azure network interface for the VMs with dynamic private IP addresses from the backend subnet
resource "azurerm_network_interface" "nic-dvwa" {
  count               = 2
  name                = "nic-dvwa-${count.index + 2}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.snet-backend.id
    private_ip_address_allocation = "Dynamic"
  }
}

#two Linux virtual machines with Ubuntu 22.04 LTS, using the previously created network interfaces and availability set, and executing a custom script to set up DVWA
resource "azurerm_linux_virtual_machine" "vm-dvwa" {
  count                           = 2
  name                            = "vm-dvwa-${count.index + 2}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  network_interface_ids           = [azurerm_network_interface.nic-dvwa[count.index].id]
  availability_set_id             = azurerm_availability_set.aset-dvwa.id
  disable_password_authentication = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }


  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  custom_data = filebase64("${path.module}/../scripts/setup_dvwa.sh")
}