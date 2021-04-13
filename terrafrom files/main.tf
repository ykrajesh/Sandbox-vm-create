terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.55.0"
    }
  }
}

provider "azurerm" {
  features {
    
  }
}
data "azurerm_resource_group" "rg" {
  name = "learn-dc6ab2d3-ee74-4d52-b1cf-fdf3a238ec08"
}
output "rgname" {
  value = data.azurerm_resource_group.rg.name   
}
output "rgnlocation" {
  value = data.azurerm_resource_group.rg.location   
}
# create virtual network 
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.Virtual_Machine_name[1]}-Vnet"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}
# create subnet in vnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.Virtual_Machine_name[1]}-Subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}
#create Network interface 
resource "azurerm_network_interface" "Interface" {
  name                = "${var.Virtual_Machine_name[1]}-Nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${var.Virtual_Machine_name[1]}-IP"
    subnet_id                     = azurerm_subnet.subnet.id
    //private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.public.id
    private_ip_address_allocation = "Static"
    private_ip_address = var.dc_ips[0]
  }
}

#create public ip address
resource "azurerm_public_ip" "public" {
  name                    = "${var.Virtual_Machine_name[1]}-PIP"
  location                = data.azurerm_resource_group.rg.location
  resource_group_name     = data.azurerm_resource_group.rg.name
  allocation_method       = "Dynamic"
  
}
# create the  Vm machine 
resource "azurerm_windows_virtual_machine" "vm" {
  name                = var.Virtual_Machine_name[1]
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  size                = "Standard_DS1_v2"
  admin_username      = "vmadmin"
  admin_password      = "Welcome@1234"
  network_interface_ids = [
    azurerm_network_interface.Interface.id,
  ]
# Disk type define here
  os_disk {
    name = "${var.Virtual_Machine_name[1]}-OS-Disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
# os Source 
 source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}
#install IIS Role 
resource "azurerm_virtual_machine_extension" "vm_extension_install_iis" {
  name                       = "vm_extension_install_iis"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.8"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell -ExecutionPolicy Unrestricted Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools"
    }
SETTINGS
}

