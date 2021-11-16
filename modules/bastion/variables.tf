variable "network_name" {
    type = string
}

variable "volume_size" {
    type = number
}

variable "floating_ip_pool" {
    type = string
}

variable "image_id" {
    type = string
}

variable "flavor" {
    type = string
}

variable "access_key_name" {
    type = string
}

variable "to_create" {
    type = bool
}