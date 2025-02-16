resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}

# Create virtual network
resource "azurerm_virtual_network" "holx_terraform_network" {
  name                = "${var.resource_name_prefix}Vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet1
resource "azurerm_subnet" "holx_terraform_subnet1" {
  name                 = "${var.resource_name_prefix}Subnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.holx_terraform_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create subnet2
resource "azurerm_subnet" "holx_terraform_subnet2" {
  name                 = "${var.resource_name_prefix}Subnet2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.holx_terraform_network.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create public IP1
resource "azurerm_public_ip" "holx_terraform_public_ip1" {
  name                = "${var.resource_name_prefix}PublicIP1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create public IP2
resource "azurerm_public_ip" "holx_terraform_public_ip2" {
  name                = "${var.resource_name_prefix}PublicIP2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "holx_terraform_nsg" {
  name                = "${var.resource_name_prefix}NetworkSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "RDP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface 1
resource "azurerm_network_interface" "holx_terraform_nic1" {
  name                = "${var.resource_name_prefix}NIC1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "holx_nic1_configuration"
    subnet_id                     = azurerm_subnet.holx_terraform_subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.holx_terraform_public_ip1.id
  }
}

# Create network interface 2
resource "azurerm_network_interface" "holx_terraform_nic2" {
  name                = "${var.resource_name_prefix}NIC2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "holx_nic2_configuration"
    subnet_id                     = azurerm_subnet.holx_terraform_subnet2.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.holx_terraform_public_ip2.id
  }
}

# Connect the security group to the network interface 1
resource "azurerm_network_interface_security_group_association" "example1" {
  network_interface_id      = azurerm_network_interface.holx_terraform_nic1.id
  network_security_group_id = azurerm_network_security_group.holx_terraform_nsg.id
}

# Connect the security group to the network interface 2
resource "azurerm_network_interface_security_group_association" "example2" {
  network_interface_id      = azurerm_network_interface.holx_terraform_nic2.id
  network_security_group_id = azurerm_network_security_group.holx_terraform_nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics with Disaster Recovery copies
resource "azurerm_storage_account" "holx_storage_account" {
  count                    = var.disaster_recovery_copies
  name                     = format("diag${random_id.random_id.hex}%d", count.index + 1)
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

# Create virtual machine 1 (Linux)
resource "azurerm_linux_virtual_machine" "holx_terraform_vm1" {
  name                  = "${var.resource_name_prefix}-${random_pet.rg_name.id}VM1"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.holx_terraform_nic1.id]
  size                  = "Standard_DS1_v2"
  computer_name         = "mcLinux"
  custom_data           = filebase64("linux_user_data.tpl")
  admin_username        = var.username
  admin_password        = var.password

  os_disk {
    name                 = "${var.resource_name_prefix}OsDisk1"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  admin_ssh_key {
    username   = var.username
    public_key = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.holx_storage_account[0].primary_blob_endpoint #adjust index count to match the number of storage accounts
  }
}

# Create virtual machine 2 (Windows)
resource "azurerm_windows_virtual_machine" "holx_terraform_vm2" {
  name                  = "${var.resource_name_prefix}-${random_pet.rg_name.id}VM2"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.holx_terraform_nic2.id]
  size                  = "Standard_DS2_v2"
  admin_username        = var.username
  admin_password        = var.password
  computer_name         = "mcWindows"

  os_disk {
    name                 = "${var.resource_name_prefix}OsDisk2"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.holx_storage_account[0].primary_blob_endpoint #adjust index count to match the number of storage accounts
  }
}

# Install IIS web server to VM2 (Windows)
resource "azurerm_virtual_machine_extension" "web_server_install" {
  name                       = "${var.resource_name_prefix}-${random_pet.rg_name.id}-wsi"
  virtual_machine_id         = azurerm_windows_virtual_machine.holx_terraform_vm2.id
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

# Configure the filename for storing the private key
resource "local_file" "private_key" {
  content = jsondecode(azapi_resource_action.ssh_public_key_gen.output).privateKey
  #content  = base64decode(output.private_key_data.value)
  filename = "private_key.pem"
}
