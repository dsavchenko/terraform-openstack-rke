variable "name_prefix" {
  type = string
}

variable "rules" {
  type = list
}

variable "bastion_host" {
  type = string
}

variable "bastion_host_internal" {
  type = string
}
