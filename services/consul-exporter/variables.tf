variable "docker_host" {
  sensitive = true
}

variable "docker_tag" {
  default = "v0.8.0"
}

variable "instances" {
}

variable "app_env" {
  type = set(string)
}

variable "entrypoint" {
  type = list(string)
}

variable "ports" {
  type = set(string)
}

variable "command" {
  default = null
  type    = list(string)
}

variable "image" {
}

variable "hostname" {
}

variable "key_id" {
  sensitive = true
}

variable "url" {
  sensitive = true
}

variable "account" {
  sensitive = true
}

variable "upload_files" {
  type = map(object({
    local_file  = string
    remote_file = string
    executable  = bool
  }))
  default = null
}

variable "labels" {
  type = map(object({
    label = string
    value = string
  }))
  default = null
}

variable "log_driver" {
  default = null
}

variable "syslog-address" {
  default   = null
  sensitive = true
}

variable "http_proxy" {
  sensitive = true
}

variable "ext_tcns_domain" {
  sensitive = true
}

variable "int_tcns_domain" {
  sensitive = true
}

variable "consul_tcns_name" {
  sensitive = true
}

variable "consul_key" {
  sensitive = true
}

variable "consul_domain" {
  sensitive = true
}

variable "consul_dc" {
}

variable "upstream_dns" {
  sensitive = true
}

variable "fabric_id" {
}

variable "tz" {
  description = "timezone"
}
