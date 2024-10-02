variable "vlan_id" {
}

variable "name" {
}

variable "description" {
}

variable "subnet" {
}

variable "provision_start_ip" {
}

variable "provision_end_ip" {
}

variable "gateway" {
}

variable "resolvers" {
  type    = list(string)
  default = ["192.168.1.1", "192.168.1.2"]
}

variable "internet_nat" {
  default = "true"
}

variable "key_id" {}
variable "account" {}
variable "url" {}
