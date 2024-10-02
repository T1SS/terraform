terraform {
  #  backend "remote" {
  #}
}

module "fabric-network" {
  source             = "github.com/T1SS/terraform-modules.git//triton/network/fabric?ref=main"
  vlan_id            = var.vlan_id
  name               = var.name
  description        = var.description
  subnet             = var.subnet
  provision_start_ip = var.provision_start_ip
  provision_end_ip   = var.provision_end_ip
  gateway            = var.gateway
  resolvers          = var.resolvers
  internet_nat       = var.internet_nat
}
