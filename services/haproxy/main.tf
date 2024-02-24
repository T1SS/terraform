terraform {
  backend "remote" {
  }
}

locals {
  # Optional TCNS service discovery with JSON templating. If var.tcns_sd_on is set to true, go ahead
  # and template the JSON file. If set to false - ignore templating.
  tcns_sd_template = var.tcns_sd_on == true ? templatefile("${path.module}/files/tcns_sd.json.tpl", {
    tcns_sd = var.tcns_sd_data
  }) : false
  metadata = {
    app_hooks      = file("${path.root}/files/app-hooks.sh")
    haproxy_reload = file("${path.root}/../../scripts/haproxy/haproxy-reload.sh")
    haproxy_cfg    = file("${path.root}/files/haproxy.cfg.ctmpl")
    consul_watch   = file("${path.root}/files/watch.json")
    haproxy_health = file("${path.root}/files/health.json")
    certs_sh       = file("${path.root}/../../scripts/haproxy/certs.sh")
    rsyslog_conf   = file("${path.root}/files/rsyslog.conf")
    logship_conf   = file("${path.root}/files/logship.conf")
    exporter_conf  = file("${path.root}/files/exporter.conf")
    env_vars       = <<EOF
ROLE=${var.role}
CONSUL_DC=${var.consul_dc}
CONSUL_DOMAIN=${var.consul_domain}
CONSUL_KEY=${var.consul_key}
CONSUL_TCNS_NAME=${var.consul_tcns_name}
CONSUL_MACHINE_USER=${var.consul_machine_user}
CONSUL_MACHINE_PASSWD=${var.consul_machine_passwd}
EXT_TCNS_DOMAIN=${var.ext_tcns_domain}
INT_TCNS_DOMAIN=${var.int_tcns_domain}
IMAGE_VERSION=${var.image_version}
FABRIC_ID=${var.fabric_id}
HTTP_PROXY=${var.http_proxy}
HTTPS_PROXY=${var.http_proxy}
http_proxy=${var.http_proxy}
https_proxy=${var.http_proxy}
SSL_STAGING=${var.ssl_staging}
SYSLOG_UPSTREAM=${var.syslog-core}
UPSTREAM_DNS="${var.upstream_dns}"
LOGZ_ACCOUNT=${var.logz_account}
TZ="${var.tz}"
TCNS_SD_ON="${var.tcns_sd_on}"
TCNS_SD_JSON='${local.tcns_sd_template}'
FORCE_SSL=${var.force_ssl}
XDC=${var.xdc}
XDC_NAME=${var.xdc_name}
EOF
  }
}

module "haproxy" {
  source         = "github.com/T1SS/terraform-modules.git//triton/infra?ref=main"
  instances      = var.instances
  image_name     = var.image_name
  image_version  = var.image_version
  package        = var.package
  hostname       = var.hostname
  networks       = var.networks
  role           = var.role
  user_script    = var.user_script
  account        = var.account
  service_tags   = var.service_tags
  firewall_rules = var.firewall_rules
  metadata       = local.metadata
  tags           = var.tags
}

output "instance_name" {
  value = module.haproxy.instance_name
}

output "primaryip" {
  value = module.haproxy.primaryip
}

output "compute_node" {
  value = module.haproxy.compute_node
}
