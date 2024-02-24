provider "triton" {
  url                      = var.url
  account                  = var.account
  key_id                   = var.key_id
  insecure_skip_tls_verify = false
}
