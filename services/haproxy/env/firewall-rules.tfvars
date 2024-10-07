firewall_rules = {
  rule_haproxy_stick = {
    description = "haproxy to haproxy stick table cluster sync"
    from        = "tag \"firewall_id\" = \"<FIREWALL_ID>\""
    to          = "tag \"firewall_id\" = \"<FIREWALL_ID>\""
    action      = "ALLOW"
    protocol    = "tcp"
    port        = 10000
    enabled     = true
  },
  rule_haproxy_http = {
    description = "clients to haproxy http"
    from        = "any"
    to          = "tag \"firewall_id\" = \"<FIREWALL_ID>\""
    action      = "ALLOW"
    protocol    = "tcp"
    port        = 80
    enabled     = true
  },
  rule_haproxy_https = {
    description = "clients to haproxy https"
    from        = "any"
    to          = "tag \"firewall_id\" = \"<FIREWALL_ID>\""
    action      = "ALLOW"
    protocol    = "tcp"
    port        = 443
    enabled     = true
  },
  rule_haproxy_alt_http = {
    description = "clients to haproxy alternate http"
    from        = "any"
    to          = "tag \"firewall_id\" = \"<FIREWALL_ID>\""
    action      = "ALLOW"
    protocol    = "tcp"
    port        = 8080
    enabled     = true
  },
  rule_haproxy_consul_lt_surf = {
    description = "Consul LAN tcp surf to haproxy"
    from        = "any"
    to          = "tag \"firewall_id\" = \"<FIREWALL_ID>\""
    action      = "ALLOW"
    protocol    = "tcp"
    port        = 8301
    enabled     = true
  },
  rule_haproxy_consul_lu_surf = {
    description = "Consul LAN udp surf to haproxy"
    from        = "any"
    to          = "tag \"firewall_id\" = \"<FIREWALL_ID>\""
    action      = "ALLOW"
    protocol    = "udp"
    port        = 8301
    enabled     = true
  },
  rule_haproxy_consul_lt_surf = {
    description = "Consul WAN tcp surf to haproxy"
    from        = "any"
    to          = "tag \"firewall_id\" = \"<FIREWALL_ID>\""
    action      = "ALLOW"
    protocol    = "tcp"
    port        = 8302
    enabled     = true
  },
  rule_haproxy_consul_lu_surf = {
    description = "Consul WAN udp surf to haproxy"
    from        = "any"
    to          = "tag \"firewall_id\" = \"<FIREWALL_ID>\""
    action      = "ALLOW"
    protocol    = "udp"
    port        = 8302
    enabled     = true
  }
}
