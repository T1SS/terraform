${jsonencode({
          for k, v in tcns_sd : k => {
            external_service_name  = v.external_service_name
            internal_service_name  = v.internal_service_name
            internal_service_port  = v.internal_service_port
            haproxy_balance        = v.haproxy_balance
            haproxy_path           = v.haproxy_path
            haproxy_check_uri      = v.haproxy_check_uri
            haproxy_expect_status  = v.haproxy_expect_status
            haproxy_method         = v.haproxy_method
            haproxy_timeout_client = v.haproxy_timeout_client
            haproxy_timeout_server = v.haproxy_timeout_server
            haproxy_expect_nodes   = v.haproxy_expect_nodes
            haproxy_fabric         = v.haproxy_fabric
	  }
})}
