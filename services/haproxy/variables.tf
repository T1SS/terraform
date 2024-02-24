variable "hostname" {
  description = "hostname part without the order number suffix. That is auto assigned by the count function."
}

variable "image_name" {
  default     = "haproxy"
  description = "Triton image name."
}

variable "image_version" {
  default     = "2.x.x"
  description = "Triton image version."
}

variable "package" {
  default     = "medium"
  description = "Triton machine size."
}

variable "user_script" {
  default     = "../../scripts/user-script.sh"
  description = "Triton user script executed at boot time."
  sensitive   = true
}

variable "instances" {
  default     = "3"
  description = "Number of instances."
}

variable "networks" {
  type        = list(string)
  description = "Triton network name"
}

variable "role" {
  description = "Application role."
}

variable "consul_dc" {
  description = "Consul DC."
}

variable "consul_domain" {
  description = "Consul domain."
  sensitive   = true
}

variable "consul_key" {
  description = "Consul encryption key."
  sensitive   = true
}

variable "consul_tcns_name" {
  description = "Consul masters TCNS FQDN"
  sensitive   = true
}

variable "consul_machine_user" {
  default     = "machine"
  description = "consul ui user for certs"
  sensitive   = true
}

variable "consul_machine_passwd" {
  default   = "changeme"
  sensitive = true
}

variable "key_id" {
  sensitive = true
}

variable "account" {
  sensitive = true
}

variable "url" {
  sensitive = true
}

variable "service_tags" {
  type = list(string)
}

variable "firewall_rules" {
  type = map(object({
    from        = string
    to          = string
    protocol    = string
    port        = number
    action      = string
    description = string
    enabled     = bool
  }))
}

variable "ext_tcns_domain" {
  sensitive = true
}

variable "int_tcns_domain" {
  sensitive = true
}

variable "upstream_dns" {
  sensitive = true
}

variable "fabric_id" {
}

variable "ssl_staging" {
  default = "false"
}

variable "syslog-address" {
  default   = null
  sensitive = true
}

variable "syslog-core" {
  sensitive = true
}

variable "http_proxy" {
  sensitive = true
}

variable "logz_account" {
  sensitive = true
}

variable "tz" {
  description = "timezone"
}

variable "tcns_sd_data" {
  default = {
    default = {
      external_service_name  = "svc-foo-ext"
      internal_service_name  = "svc-foo-int"
      internal_service_port  = 8080
      haproxy_balance        = "roundrobin"
      haproxy_path           = "/"
      haproxy_check_uri      = "/"
      haproxy_expect_status  = 200
      haproxy_expect_nodes   = 1
      haproxy_method         = "GET"
      haproxy_timeout_client = "15s"
      haproxy_timeout_server = "15s"
      haproxy_fabric         = "true"
    }
  }

  type = map(object({
    external_service_name  = string
    internal_service_name  = string
    internal_service_port  = number
    haproxy_balance        = string
    haproxy_path           = string
    haproxy_check_uri      = string
    haproxy_expect_status  = number
    haproxy_expect_nodes   = number
    haproxy_method         = string
    haproxy_timeout_client = string
    haproxy_timeout_server = string
    haproxy_fabric         = string
  }))
  sensitive = true
}

variable "tcns_sd_on" {
  default = false
}

variable "tags" {
  type    = map(any)
  default = { "haproxy_cluster" : "ingress" }
}

variable "force_ssl" {
  default = false
}

variable "foreign_record_ingress" {
  description = "Enables ingress for non Triton DNS backends with a special ACL rule"
  default     = false
}

variable "xdc" {
  description = "Enables ingress for the remote datacenter's equivalent FQDNs (backends)"
  default     = false
}

variable "xdc_name" {
  description = "The remote datacenter's name in the FQDN records. This is only applied if xdc is true."
  default     = false
}
