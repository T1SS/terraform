instances   = "1"
docker_host = "tcp://docker.dc1.triton:2376"
hostname    = "exporter1"
account     = "dev"
docker_tag  = "v0.8.0"
app_env     = ["ROLE=exporter"]
entrypoint  = ["/bin/consul_exporter"]
image       = "prom/consul-exporter"
ports       = ["9107"]
log_driver  = "syslog"

labels = {
  triton_cns_disable = {
    label = "triton.cns.disable"
    value = "false"
  },
  triton_cns_services = {
    label = "triton.cns.services"
    value = "csl-exporter-dev1"
  },
  com_joyent_package = {
    label = "com.joyent.package"
    value = "small"
  },
  com_docker_swarm_affinities = {
    label = "com.docker.swarm.affinities"
    value = "[\"container!=~exporter1*\"]"
  },
  triton_network_public = {
    label = "triton.network.public"
    value = "fabric-dev1"
  }
}
