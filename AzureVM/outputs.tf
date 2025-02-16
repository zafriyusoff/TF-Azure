output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "linux_vm_public_ip_address" {
  value = azurerm_linux_virtual_machine.holx_terraform_vm1.public_ip_address
}

output "windows_vm_public_ip_address" {
  value = azurerm_windows_virtual_machine.holx_terraform_vm2.public_ip_address
}

output "public_key_data" {
  value     = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
  sensitive = true
}

output "private_key_data" {
  value     = jsondecode(azapi_resource_action.ssh_public_key_gen.output).privateKey
  sensitive = true
}