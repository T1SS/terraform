hostname      = "ingress1"
networks      = ["fabric-dev1", "external"]
role          = "ingress-dev1"
logz_account  = "xyz"
service_tags  = ["certcheck:443", "ingress-dev1:8080", "webapp-dev1", "webapi-dev1", "ingress-dev1-rsyslog-exporter:9104"]
syslog-core   = "syslog.svc.xyz"
image_version = "2.x.x"
