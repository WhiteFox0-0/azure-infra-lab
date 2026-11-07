variable "location" {
  type    = string
  default = "centralindia"
  # subscription policy `sys.regionrestriction` allows only:
  # koreacentral, centralindia, malaysiawest, southeastasia, uaenorth
}

variable "project" {
  type    = string
  default = "inflab"
}

variable "vnet_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "servers_subnet_cidr" {
  type    = string
  default = "10.10.1.0/24"
}

variable "management_subnet_cidr" {
  type    = string
  default = "10.10.2.0/24"
}

variable "bastion_subnet_cidr" {
  type    = string
  default = "10.10.3.0/26"
}

variable "admin_source_ip" {
  type        = string
  description = "Your public IP in CIDR form (e.g. 203.0.113.10/32). Used for NSG lock-down. Find it: curl -s ifconfig.me"
}

variable "enable_bastion" {
  type        = bool
  default     = false
  description = "Set true only if credits allow. Bastion costs ~$0.19/hr while running."
}

variable "budget_amount" {
  type        = number
  default     = 25
  description = "Monthly budget in USD for the alert."
}

variable "budget_contact_emails" {
  type        = list(string)
  description = "Emails to receive budget alerts (your Azure account email)."
}

variable "admin_username" {
  type    = string
  default = "labadmin"
}

variable "vm_size" {
  type        = string
  default     = "Standard_B2s_v2"
  description = "Windows DC size. Classic Standard_B2s is capacity-blocked in centralindia; fallbacks: Standard_B2ms, Standard_D2s_v5."
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Windows RDP password. Must satisfy Azure: 12+ chars, 3 of 4 categories (upper, lower, digit, symbol)."
}
