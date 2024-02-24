locals {
  cloudapi_url = replace(var.url, ".", "_")
  cloudapi_dir = trimprefix(local.cloudapi_url, "https://")
}

provider "docker" {
  host      = var.docker_host
  cert_path = pathexpand("~/.triton/docker/${var.account}@${local.cloudapi_dir}")
}
