terraform {
  backend "remote" {
  }
}

locals {
  command = ["--consul.server=${var.consul_tcns_name}:8500"]
  env     = setunion(var.app_env, ["TZ=${var.tz}"])
  log_opts = {
    "syslog-address"  = "udp://${var.syslog-address}"
    "syslog-facility" = "daemon"
    "syslog-tag"      = var.labels.triton_cns_services.value
  }
}

module "consul-exporter" {
  source       = "github.com/T1SS/terraform-modules.git//triton/docker?ref=main"
  instances    = var.instances
  hostname     = var.hostname
  image        = var.image
  docker_tag   = var.docker_tag
  ports        = var.ports
  env          = local.env
  command      = local.command
  entrypoint   = var.entrypoint
  upload_files = var.upload_files
  labels       = var.labels
  log_driver   = var.log_driver
  log_opts     = local.log_opts
}

output "instance_name" {
  value = module.consul-exporter.instance_name
}

output "image" {
  value = module.consul-exporter.image
}
