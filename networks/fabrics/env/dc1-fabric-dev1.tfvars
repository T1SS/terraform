vlan_id            = 17
name               = "fabric-dev1"
description        = "Fabric DEV1 network"
subnet             = "10.100.17.0/24"
provision_start_ip = "10.100.17.1"
provision_end_ip   = "10.100.17.254"
gateway            = "10.100.17.1"
resolvers          = ["192.168.1.1", "192.168.1.2"]
internet_nat       = true