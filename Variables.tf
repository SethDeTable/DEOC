variable "username" {
  type        = string
  description = "The username for the local account that will be created on the new VM."
  default     = "adminuser"
}

variable "password" {
  description = "The admin password for the VM"
  type        = string
  default     = "Password1234!"
  sensitive   = true
}