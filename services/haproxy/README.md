## Fabric HAProxy Ingress Controller

### Terminology

Terminology used in this document:

  * [HAProxy](https://www.haproxy.org) - software load-balancer
  * [Consul](https://www.consul.io) - service discovery
  * [Fabric](https://docs.tritondatacenter.com/private-cloud/networks/sdn/architecture) - Triton software defined network segment
  * [TCNS](https://github.com/TritonDataCenter/triton-cns/blob/master/docs/operator-guide.md) - Triton Container Name Service

### Description

Terraform config for fabric ingress service routing.
Built on top of HAProxy, Consul and TCNS.

Provides three main functions:

  - fabric ingestion control
  - load-balancing
  - optional egress routing

The objective is to provide a highly available, robust, service routing capability for services which are exclusively attached to fabric networks only (isolated non-routable networks).

### Features

  * service discovery
  * high availability
  * active/active load-balancing
  * [distributed stick tables (sticky sessions)](https://www.haproxy.com/blog/haproxy-2-0-and-beyond/#peers-stick-tables-improvements)
  * [seamless configuration reload](https://www.haproxy.com/blog/truly-seamless-reloads-with-haproxy-no-more-hacks/)
  * SSL termination

### Topology

Docker instances attached to a single fabric network (FAB). Requests coming from external clients are routed via HAProxy instances (HAP) which are dual homed between the external network (EXT) and fabric (FAB).

```
[ docker0 ] <-- {   } -- [ HAP0 ] -- |   | <--- requests ---
[ docker1 ] <-- { F }                | E |                   \
[ docker2 ] <-- { A } -- [ HAP1 ] -- | X | <--- requests ---- ( clients )
[ docker3 ] <-- { B }                | T |                   /
[ docker4 ] <-- {   } -- [ HAP2 ] -- |   | <--- requests ---
```

### Service Discovery

Service discovery by HAProxy instances is primarily done via Consul catalog monitoring and service metadata keys. When a new service appears in Consul's service catalog it is checked for the presence of haproxy metadata keys. If the service has these keys a new configuration is generated and a seamless config reload is triggered.

Secondary service discovery option can be enabled via TCNS (DNS SRV records). As TCNS has no concept of rich metadata features (such as Consul's metadata keys) this needs to be injected as a JSON object (TCNS_SD_JSON env variable).

#### Consul Service Metadata Keys

To advertise a service for fabric ingestion,
the following service metadata keys are supported:

  * haproxy (required)
  * haproxy_method (optional)
  * haproxy_expect_status (optional)
  * haproxy_path (optional)
  * haproxy_balance (optional)
  * haproxy_timeout_client (optional)
  * haproxy_timeout_server (optional)
  * haproxy_sticky (optional)

##### haproxy
```
  NAME
       haproxy

  DESCRIPTION
       Setting this to "true" will mark the service for fabric ingestion.
       HAProxy will auto configure this service as a backend.

  Supported values
       true | false

       (Default: not set)
```

##### haproxy_method
```
  NAME
       haproxy_method

  DESCRIPTION
       HTTP method to use for HAProxy health checking.

  Supported values:
       GET, POST, OPTIONS (any valid HTTP method)

       (Default: GET)
```

##### haproxy_expect_status
```
  NAME
       haproxy_expect_status

  DESCRIPTION
       HTTP return code to consider the service healthy.

  Supported values:
       Any valid HTTP return code

       (Default: 200)
```

##### haproxy_path
```
  NAME
       haproxy_path

  DESCRIPTION
       Simple rewrite rule for path handling. This path will be
       used for health checking and request will be rewritten to contain this path.

  Supported values:
       Any valid path, expected in the following format "/mypath/".

       (Default: /)
```

##### haproxy_check_uri
```
  NAME
       haproxy_check_uri

  DESCRIPTION
       URL to use for http health check

       (Default: defaults to the value of `haproxy_path`)
```

##### haproxy_balance
```
  NAME
       haproxy_balance

  DESCRIPTION
       HAProxy load-balancing algorithm to use.

  Supported values:
       Any valid HAProxy load-balancing algorithm.

       (Default: roundrobin)

       Example:
       random|random(<draws>)|roundrobin|leastconn
```

##### haproxy_timeout_client
```
  NAME
       haproxy_timeout_client

  DESCRIPTION
       HAProxy client timeout to the backend
```

##### haproxy_timeout_server
```
  NAME
       haproxy_timeout_server

  DESCRIPTION
       HAProxy server timeout to the backend
```

##### haproxy_sticky
```
  NAME
       haproxy_sticky

  DESCRIPTION
       Enables sessions stickyness

  VALUES
       true or false
```


**Please note:**

Services participating in the same service group must have the same
metadata key/val configuration (with the exception of `haproxy`).

##### Example Consul Service JSON:
```json
{
  "service": {
    "name": "myservice",
    "port": 80,
    "meta": {
      "haproxy": "true",
      "haproxy_method": "GET",
      "haproxy_expect_status": "200",
      "haproxy_path": "/myservice/",
      "haproxy_balance": "random",
      "haproxy_timeout_client": "30s",
      "haproxy_timeout_server": "30s"
    }
  }
}
```

#### TCNS SD (service discovery)

TCNS is a DNS based service discovery built into Triton as a core feature. Instances can be tagged with `cns` tags
which will become resolvable service records in TCNS. Non Docker instances use the `service_tags` variable, while Docker instances use the `labels.triton_cns_services` variable.

TCNS is used extensively to manage dynamic DNS records in Triton, it is also useful for Docker instances which are not Consul enabled (namely instances based on upstream images).

##### TCNS service configuration metadata keys

To enable Haproxy TCNS SD the following must be true:

###### Set variable tcns_sd_on

To enable the JSON service configuration templating set terraform variable `tcns_sd_on` to `true` (default is false).

###### Service metadata configuration

Terraform `tcns_sd_data` must contain a valid service configuration, example:
```
svc-foo = {
  external_service_name  = "svc-foo-ext" # external TCNS service tag assigned to Haproxy instances only
  internal_service_name  = "svc-foo-int" # in-fabric TCNS service tag assigned to the application only
  internal_service_port  = 8080
  haproxy_balance        = "roundrobin"
  haproxy_path           = "/"
  haproxy_expect_status  = 200
  haproxy_expect_nodes   = 1
  haproxy_method         = "GET"
  haproxy_timeout_client = "15s"
  haproxy_timeout_server = "15s"
  haproxy_fabric         = "true"
}
```

###### external_service_name and internal_service_name

`external_service_name` must be always different from `internal_service_name`, otherwise the DNS records will clash.

`external_service_name` must match the `service_tag` variable assigned to Haproxy instances.

`internal_service_name` must match either the `service_tag` variable assigned to non-Docker instances, or `labels.triton_cns_services` variable assigned to Docker instances.

The example service configuration above assumes external TCNS record `svc-foo-ext.svc.myaccount.dc.mydomain.com` and internal TCNS record `svc-foo-int.svc.myaccount.dc-int.mydomain.com`.

The external record is used to route the service requests to Haproxy, while the internal record is used to load-balance service requests from Haproxy to the actual application instance.

###### internal_service_port

The fabric application's TCP port where it listens for requests.

###### haproxy_balance

Same as the Consul meta-key described above.

###### haproxy_expect_status

Same as the Consul meta-key described above.

###### haproxy_expect_nodes

Number of nodes expected under the service record.

###### haproxy_method

Same as the Consul meta-key described above.

###### haproxy_timeout_client

Same as the Consul meta-key described above.

###### haproxy_timeout_server

Same as the Consul meta-key described above.

###### haproxy_fabric

Value can be `true` (default) or `false`.

`true` will configure load-balancing for a fabric application.

`false` will configure load-balancing for a non fabnric application residing outside of the fabric network (must be reachable by haproxy).

### Runtime Configuration

Boot time configuration is achieved with the standard user-script and app_hook variable.

Runtime configuration is done through a combination of metadata and variables injection.
Each configuration file is injected via Terraform variables. The actual HAProxy configuration generation
is offloaded to consul-template, which is auto triggered on service check event changes.

Example Terraform variables:

```terraform
  haproxy_cfg    = file("${path.root}/files/haproxy.cfg.ctmpl")
  haproxy_health = file("${path.root}/files/health.json")
  consul_watch   = file("${path.root}/files/watch.json")
  service_tags   = list("vault", "consul-ui", ... )
```

#### Force SSL variable

Setting `var.force_ssl` variable to true (default is false) will redirect all plaintext HTTP requests to HTTPS.


#### watch.json

watch.json responsible for watching the Consul catalog for changes and triggering a helper script.

```json
{
  "watches": [
    {
      "type": "checks",
      "state": "passing",
      "args": ["sh", "-c", "pfexec /usr/local/bin/haproxy-reload.sh >> /var/db/consul/watch.log 2>&1"]
    }
  ]
}
```

#### haproxy-reload.sh

A simple wrapper script to generate an up to date configuration and gracefully reload HAProxy via SIGUSR2.

```bash
#!/bin/sh
set -x

sleep 5

haproxy_pid=$(</var/run/haproxy.pid)

mdata-get haproxy_cfg > /opt/local/etc/haproxy.cfg.ctmpl
consul-template-once /opt/local/etc/haproxy.cfg.ctmpl /opt/local/etc/haproxy.cfg

haproxy -c -f /opt/local/etc/haproxy.cfg && kill -SIGUSR2 $haproxy_pid

exit 0
```

### Deployment

```bash

$ export ENV=myenv1
$ export DC=mydc

# Initalize provider for given environment
# optionally supply -updgrade to get the latest provider version

$ terraform init -reconfigure -backend-config=env/${DC}-fabric-${ENV}.tfbackend

## Deploy and manage

$ terraform plan -var-file=env/firewall-rules.tfvars -var-file=../../globals/${DC}-fabric-${ENV}.tfvars -var-file=env/${DC}-fabric-${ENV}.tfvars -out=my.tfplan

$ terraform apply "my.tfplan"

## Destroy

$ terraform plan -var-file=env/firewall-rules.tfvars -var-file=../../globals/${DC}-fabric-${ENV}.tfvars -var-file=env/${DC}-fabric-${ENV}.tfvars -destroy -out=destroy.tfplan

$ terraform apply "destroy.tfplan"
```
