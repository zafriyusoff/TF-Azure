variable "resource_group_location" {
  type        = string
  default     = "westus2"
  description = "Location of the resource group."
}

variable "resource_group_name_prefix" {
  type        = string
  default     = "rg"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "resource_name_prefix" {
  type        = string
  default     = "holx"
  description = "Prefix of the resource name combined with other resources in your Azure resource group."
}

variable "username" {
  type        = string
  description = "The username for the local account that will be created on the new VM."
  default     = "azureadmin"
  sensitive   = true
}

variable "password" {
  type        = string
  description = "The password for the local account that will be created on the new VM."
  default     = ""
  sensitive   = true
}

variable "disaster_recovery_copies" {
  type        = number
  default     = 1
  description = "The number of disaster recovery copies or replicas."
}
