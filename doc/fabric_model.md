# Building repeatable infrastructure with fabrics


## Background

This document is an attempt to address a small, yet very crucial set of challenges in building repeatable infrastructure.

This document relies on Triton built-in features which are not unique to it, most infrastructure vendors offer similar or identical features. The major difference is Triton's clean end-to-end implementation of these features as as an integrated set of core built-in functions.

The general concept is applicable in any virtualized setting.

### Motivation

To address some of the most overlooked and underestimated infrastructure challenges presented by replaceable and repeatable workloads.

### Challenges

Difficulties with semi-immutable workloads.

  - new environment provisioning (networks, firewall rules, routes)
  - cross DC portability
  - instance replacement (with new versions)
  - IP address changes
  - DNS record changes
  - firewall rule changes
  - service discovery and configuration changes
  - monitoring changes

### Anti-patterns

Failure to address some of those challenges listed above, usually results in the adoption of anti-patterns, which in turn undermines the idea of repeatable infrastructure and its inherent benefits.

Usual issues:

  - partial automation
  - complexity
  - fragile workarounds
  - privileged access requirements
  - undocumented procedures
  - excessive reliance on operator or administrative actions
  - unclear processes and boundaries

Additionally a closer look at the challenges above reveils a pattern. Directly or indirectly most of them fall into a loosely defined set of "network category" issues.

On the other hand, the adopted anti-pattern list, falls almost entirely outside of this network category.

This creates a disproportional imbalance and great deal of friction, where the majority of challenges come from a set of network related issues, but the resulting corrective actions (anti-patterns) to address those happen almost entirely outside of the network scope higher up on a different level.

The solution lies in the network itself, and is the base building block of all infrastructure patterns impacting **everything** down the line.

## Responding to challenges

### Desired outcomes

  - enable on-demand environment provisioning
  - support multiple copies of the same environment
  - infrastructure as code
  - enable dynamic provisioning models (Terraform style reprovisioning, rolling upgrades, scale up/down events)
  - repeatable and reusable infrastructure patterns (deploy to any environment or DC)
  - end-to-end automation for all application life-cycle aspects (service discovery, monitoring, logs, network, DNS, firewall rules)
  - secure application confinement
  - reduced overall complexity
  - reduced management and maintenance burden
  - observability (logs/metrics/alerting)

To meet the goals listed above, the key building block of all environments must be addressed first - the network.

## Fabric Environment Design

The number one requirement for new environments is network connectivity. Traditionally this piece requires an allocation of new VLANs and subnets. This in most organizations still requires some level of lenghty manual actions, takes also considerable configuration time on both the network and the actual infrastructure side.
Additionally this step is prone to error, think about routes, firewall rules, connectivity tests, return routes, the list goes on. It requires touches to most of the stack, including the provisioning and configuration management tools.

All aspects of modern infrastructure are virtualized and automated - except the underlying physical network configuration. There are solutions for this problem by various SDN vendors, these are usually expensive, support only specific products, require additional resources and staff training.

The solution described in this document explores a lightweight approach, utilizing Triton's built-in fabric networking and makes a case for this model by highlighting its major strength - **simplicity**.

This model is:

  - simple
  - low effort
  - non intrusive
  - confined to Triton only
  - requires 0 ongoing network administration
  - fully automated
  - requires little staff training

Another big advantage of this model is that on the surface it just looks and feels like a traditional IPv4 network. No obscure port maps, iptables mangling, NAT rules, etc.

Each instance owns its own dedicated TCP/IP stack with a localhost and primary NIC interface.
Looking at the instance interfaces from the inside with tools such as ifconfig or netstat we are presented with the age old (+30 years) Unix interfaces view.
For this reason alone, anyone with basic Unix/Linux sysadmin skills (in the past three decades) can reason about this model with no special training.

### Fabric network intro

A fabric is a network virtualization technology based on industry standard VXLAN encapsulation documented in [IETF RFC 7348](https://tools.ietf.org/html/rfc7348).
It enables overlaying virtualized layer 2 networks over layer 3 networks.

Fabric networks are an integral and core feature of Triton. Designed with strict isolation for multi-tenant safe environments. Its main objective is to support and enable secure/isolated virtual network provisioning for Triton end users.
This objective was driven by the need to create new networks for highly dynamic containerized applications and to enable full environment provisioning from scratch.

#### Anatomy of fabric networks

##### Underlay network

An underlay is a purpose built IPv4 network deployed on top of a dedicated VLAN. Its role is to carry VXLAN traffic.

##### Overlay network

An overlay is a layer 2 VXLAN network deployed on top of the underlay network.

##### Fabric

A fabric is an IPv4 network deployed on top of the overlay network.
IPv4 is the only supported IP protocol.

##### Non routable

Access between fabric networks is not supported. For example fabric "A" can't reach fabric "B" even for the same tenant. No routing to other fabric networks takes place.
If desired, there is an optional outbound NAT service to enable default outbound access to services such as DNS. This will NAT out traffic through the "external" network defined at fabric network creation.

##### Traffic ingestion

The only way to handle incoming traffic is via "ingestion" points which are dual-homed dedicated instances between a routable network and the fabric itself. These ingestion instances become a single control point for application traffic, serving as a firewall and application gateway for the fabric.

### Fabric Environment Breakdown

A fabric environment is deployed on top of a single dedicated fabric network. This model also requires certain design choices to enable self sustainability due to its strict network isolation nature.
For example, to support in-fabric applications we need to augment service discovery, DNS, monitoring and logging to work independently in each fabric. These services are decoupled from the usual central organizational services
and plugged into a hybrid model where these services can coexist but still be integrated into the usual organizational hierarchy.
This is a small trade-off which in turn will enable the packaging and repeatability of the entire environment.
In essence this means the virtualization of core services into logical units.

Worth noting is some of the inherent security benefits this isolation brings, for example direct access (e.g. SSH) to instances is eliminated. Firewall management is by orders of magnitude simplified. Instead of managing rules for every application and instance, only a set of ingestion instances require attention.

And lastly, in this fabric-isolation model there are always two distinct set of paradigms, in-fabric and external (non-fabric) resources. This design choice affects all fabric environments.

#### Individual components

The components listed below make up the core skeleton of the fabric environment. Together they form a larger piece where each component individually is providing a single base function, in line with the successful Unix philosophy. This loose coupling also ensures that each component is independently extendible and replaceable. This guarantees a portable future proof architecture which is easily adaptable to future needs.

##### TCNS

"Triton Container Naming System" is an autonomous dynamic DNS and service discovery system and a core built-in feature of Triton.
TCNS is instance, account, network and service aware. Each instance inherits certain default DNS records which can be further extended
with custom service records via instance tags (meta-data).
This system was invented to solve catch-22 provisioning issues and to allow external service discovery of services and instances on Triton.

TCNS DNS service records are created by meta-data tagging of instances. It does not provide health-checking of these services. A record will exists for the lifetime of an instance or until the tag is removed from an instance.

##### Consul

Consul provides a set of rich features to cover a spectrum of service discovery requirements. It is actively health-checking each service and node in its catalogue.

##### Prometheus

Prometheus is used for monitoring, metric collection and alerting. It has native integration with Consul, Haproxy and Triton itself.

##### Haproxy

The fabric ingestion is powered by Haproxy. It has over two decades of production use and track record of powering some of the largest organizations on the Internet. It is mature, simple, fast (written in C), Opensource with commercial backing and support. Supports hitless configuration reloads (without loosing requests or state). Also comes with unique distributed session persistence features which are included in the Opensource version.

##### Rsyslog

Industry standard syslog server.

##### PowerDNS

Internal fabric DNS is served by PowerDNS recursors. The recursor part is a small component without the authoritative DNS part. It is used to forward DNS lookups to both upstream authoritative systems and Consul's DNS interface.

---

### Milestone #1 - Self sustainability

Once a fabric environment is capable of self sustaining itself, it can be easily modified, duplicated and re-deployed into any other environment or datacenter with minimal effort.

To achieve this, there is a set of basic, core fabric infrastructure services which are required to support applications inside a fabric.

These are:

  - service discovery (required)
  - DNS (required)
  - ingress traffic ingestion (required)
  - log shipping  (non-essential)
  - HTTP/TCP proxy (non-essential)
  - monitoring (non-essential)

#### Core fabric infrastructure services

Most of the core services require communication to external resources, e.g. DNS, HTTP proxy, log shipping. In other words these require egress communication to upstream external services.

As best practice these services should be separate from the main application traffic ingestion flow, to guarantee availability, performance and security. To meet these requirements a standalone fabric-infrastructure Haproxy cluster is provisioned (3 nodes). This infra-cluster is configured to provide all core services - except service discovery (described later).

The following services are configured:

  - lightweight DNS recursor
  - syslog forwarding
  - HTTP proxy to upstream central proxies

Additionally this infra-cluster also provides ingress access for two in-fabric services:

  - Prometheus monitoring (API and dashboard)
  - Consul UI dashboard

Access to these dashboards is usually required for operations and support staff. Prometheus access is for central Grafana dashboards. Consul UI is required to monitor, troubleshoot and verify in-fabric services and overall health of the environment.

#### Service discovery and DNS

##### In-fabric discovery

Each fabric requires a dedicated service discovery mechanism operating inside, to allow automated service discovery for services deployed inside the fabric. A dedicated per-fabric Consul cluster (3 nodes) are deployed inside each fabric. Consul's gossip traffic will only communicate inside the fabric. Applications register themselves by the usual Consul health-checking mechanism.

_Note: fabric environments are not connected into a mesh together; this could be easily achieved if desired (service mesh architecture)._

##### In-fabric DNS resolution

This is handled by lightweight PowerDNS recursors deployed on the Haproxy infrastructure cluster, configured to look up DNS records from upstream DNS servers, TCNS and internal Consul service discovery catalogue.
This hybrid DNS model means that services can be discovered by standard DNS lookups transparently from both TCNS and the internal Consul service catalog. Additionally other upstream, external DNS lookups work transparently.

Internal DNS records originating from Consul's service catalog are not resolvable externally, these records are confined in the given fabric environment only. TCNS maintains a record for each instance and these are resolvable both inside and outside the fabric. These however are bound to a separate internal sub-domain and although they are resolvable outside the fabric, connectivity is not possible to these as the fabric is a sealed environment.

**_DNS flow:_**

```
                        .-,(  ),-.
                     .-(          )-.
                    (  upstream dns  )
                     '-(          ).-'
                         '-.( ).-'
                             ^
                             |
                     .--------------.
                     | Internal DNS |
                     '--------------'
                             ^
                             |
                             v
                         .------.
         .-------------->| TCNS |<---------------.
         |               '------'                |
         |                   ^                   |
         |                   |                   |
         v                   v                   v
   .----------.        .----------.        .----------.
   | dev1 DNS |        | dev2 DNS |        | prd1 DNS |
   '----------'        '----------'        '----------'
         ^                   ^                   ^
         |                   |                   |
.----------------.  .----------------.  .----------------.
| dev1 instances |  | dev2 instances |  | prd1 instances |
'.----------------. '.----------------. '.----------------.
 | dev1 instances |  | dev2 instances |  | prd1 instances |
 '.----------------. '.----------------. '.----------------.
  | dev1 instances |  | dev2 instances |  | prd1 instances |
  '----------------'  '----------------'  '----------------'
```

##### External discovery and DNS resolution

To resolve an internal fabric service record externally (external to the fabric; not public DNS) so that clients can connect to it by using its FQDN, the service name tag must be assigned to the Haproxy ingestion nodes. Triton TCNS service records work through a special "CNS" tag that is assigned to instances and yields resolvable DNS records.
Service name tags assigned this way will resolve to external (non-fabric) IP addresses of the Haproxy ingestion nodes.

##### Traffic Ingestion

Internal fabric service endpoints configured for external traffic ingestion get routed to the dedicated fabric Haproxy ingestion cluster. This cluster auto discovers services for ingestion by the combination of Consul service discovery meta fields.
Each time a service registers itself with the required meta fields and passes the necessary health-checks, the ingestion cluster auto-discovers these by an event-driven discovery hook.
The ingestion configuration is then re-templated, verified and gracefully reloaded. This ensures consistent and safe configuration changes, requires no administration privileges or any other management tasks.
The service discovery catalog is the single point of truth, with Consul's built-in consistency guarantees.

For a service to respond to external client requests, these conditions must be true:

  - the external CNS service name tag must map to the internal Consul service name
  - at least one of the nodes in a service group (same service, multiple instances) must be healthy
  - the health-checks in Consul is passing
  - Haproxy's internal health-check is passing
  - valid service meta fields configured in Consul

###### Service meta fields

Service meta fields example, declared in the service health-check JSON file:

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
      "haproxy_balance": "random"
    }
  }
}
```

Meta fields listed above provide a service discovery mechanism for Haproxy ingestion. If a service successfully registers itself in Consul's catalog the Haproxy nodes auto-discover it and independently verify the service health. Once this succeeds the service is enabled for traffic ingestion.

As a side effect, this dual health checking mechanism (in Consul and Haproxy) yields a more robust service ingestion setup. For example, it is highly unlikely that a service is misconfigured in Consul's heath-checking and the meta fields at the same time.

###### Service name mapping

An external service name tag must map to the internal fabric service name declared in Consul. If these don't map, no ingestion is possible. Mapping is done by extracting the internal `servicename` from the external `servicename-env` service tag.

Example:
| Service Names | DNS/SD Catalog Records |
| ------------- | ------------------------------------- |
|external name: | **web**-env1.svc.myaccount.dc1.domain |
|internal name: | **web**.service.dc1.env1.consul |

The service is assigned to the ingestion cluster with the following Triton CNS `service_tags` property:

_haproxy/env/fabric-env1.tfvars:_
```terraform
service_tags  = ["web-env1"]
```

**_Traffic ingestion:_**
```
                        .-,(  ),-.
                     .-(          )-.
                    (  ext resources )
                     '-(          ).-'
                         '-.( ).-'
                             |
                             v
                   .-------------------.
                   | routeable network |
                   | 10.X.X.X/24       |
                   '-------------------'
                             |
                             v
                        .---------.
                        | HAProxy |.
                        '---------'|.
                         '---------'|
                          '---------'
                              |
                              v
                     .----------------.
                 .---| fabric network |-----.
                 |   '----------------'     |
                 |                          |
                 v                          v
         .--------------.          .----------------.
         | applications |--.       | consul cluster |.
         '--------------'  |-.     '----------------'|-.
          '----------------' |      '----------------' |
            '----------------'        '----------------'
```

##### Log shipping

The Haproxy infra-cluster is responsible for appication log forwarding to upstream log ingestion. In this setup rsyslog is used. The upstream destination can be a log aggregator or the final log ingestion system (ELK, Splunk, etc). The diagram below depicts a core logserver which is handling logs from all environments and in turn relays these further upstream to a log ingestion system.


**_Log shipping:_**
```

                        .-,(  ),-.
                     .-(          )-.
                    (     logz.io    )
                     '-(          ).-'
                         '-.( ).-'
                             .>
                             |
                     .--------------.
                     | core rsyslog |
         .---------->| server x 2   |<-----------.
         |           '--------------'            |
         |                   |                   |
         |                   v                   |
   .----------.        .----------.        .----------.
   | dev1 DNS |        | dev2 DNS |        | prd1 DNS |
   '----------'        '----------'        '----------'
         ^                   ^                   ^
         |                   |                   |
.----------------.  .----------------.  .----------------.
| dev1 instances |  | dev2 instances |  | prd1 instances |
'.----------------. '.----------------. '.----------------.
 | dev1 instances |  | dev2 instances |  | prd1 instances |
 '.----------------. '.----------------. '.----------------.
  | dev1 instances |  | dev2 instances |  | prd1 instances |
  '----------------'  '----------------'  '----------------'
```

#### HTTP proxy

HTTP proxy is provided via a simple TCP forward to upstream proxy servers.

**_HTTP proxy forwarding:_**
```
                        .-,(  ),-.
                     .-(          )-.
                    (     internet    )
                     '-(          ).-'
                         '-.( ).-'
                             .>
                             |
                     .---------------.
          .--------->| proxy servers |<---------.
          |          '---------------'          |
          |                  |                  |
          |                  v                  |
   .------------.     .------------.     .-------------.
   | dev1 proxy |     | dev2 proxy |     | prd1 proxy  |
   | forward    |     | forward    |     | forward     |
   '------------'     '------------'     '-------------'
          ^                  ^                  ^
          |                  |                  |
 .----------------. .----------------. .----------------.
 | dev1 instances | | dev2 instances | | prd1 instances |
 '.----------------.'.----------------.'.----------------.
  | dev1 instances | | dev2 instances | | prd1 instances |
  '.----------------.'.----------------.'.----------------.
   | dev1 instances | | dev2 instances | | prd1 instances |
   '----------------' '----------------' '----------------'
```

#### Monitoring

Prometheus is deployed inside each fabric. This is in-line with best practices (close as possible to targets). Prometheus is configured to scrape metrics from Consul via built-in metrics and a standalone exporter instance, Haproxy via its built-in metric endpoint and Triton through its native CMON endpoint.

Alerts get routed to a single Alertmanager cluster.

---

### Milestone #2 - Infrastructure as code

To achieve one of the primary objectives outlined in this architecture, **repeatability**, infrastructure components require end-to-end automation. All automation aspects must be captured as code with no exception to this rule.

Each building block is automated in a modular fashion. Environment components are broken down into logical units which are decoupled from the larger overall environment view. The aim is to detach complex dependencies as much as possible and to enable simple, safe and granular changes. The result is environments which are simple to operate, maintain in a repeatable fashion.

The examples below are based on Terraform code to showcase this modular approach.

#### Creating fabric environments

Before instances can land in environments a network is required. This is the corner stone of each environment. Traditionally this step is one of the most time consuming. In terms of overall effort spent on a full environment setup this job ranks low (assuming operational physical network) and is very small compared to other environment setup tasks. Yet, generally the setup time for a new logical network evoke the image of substantial effort.

And here is why.

A new network usually requires:

 - initial team communication/discussions/meetings
 - planning and checks
 - allocation of subnet range
 - documentation
 - usually a CR/ticket
 - CR approval by relevant parties
 - VLAN and subnet configuration on switches/routers/firewalls/load balancers
 - VLAN & subnet setup on servers
 - troubleshooting

This usually involves a number of parties and can be a very lengthy process.

Triton's fabric network model requires none of the above. It is a non-intrusive way to deploy low cost, low touch SDN networks as it doesn't rely on specialized network hardware nor features. Instead, Triton fabrics utilise the existing ubiquitous VLAN feature of switches and operates its own closed loop automated VXLAN fabrics on top.

In other words, there is no need for extensive network configuration changes, staff training or proprietary network hardware.

To create a fabric network the following module can be used:

**_fabric/main.tf:_**
```terraform
module "fabric-network" {
  source             = "github.com/myorg/terraform-modules.git//triton/fabric"
  vlan_id            = var.vlan_id
  name               = var.name
  description        = var.description
  subnet             = var.subnet
  provision_start_ip = var.provision_start_ip
  provision_end_ip   = var.provision_end_ip
  gateway            = var.gateway
  resolvers          = var.resolvers
  internet_nat       = var.internet_nat
}
```

Example environment variables as plain text key/val file. Variable keys match the module's parameters. After applying this configuration (`terraform apply`) Triton creates a new fabric VLAN and subnet, which is ready for instances.

**_fabric/env/environment1.tfvar:_**
```terraform
vlan_id            = 131
name               = "fabric-env1"
description        = "Fabric ENV1 network"
subnet             = "10.90.131.0/24"
provision_start_ip = "10.90.131.1"
provision_end_ip   = "10.90.131.254"
gateway            = "10.90.131.1"
resolvers          = ["192.168.100.1", "192.168.100.2"]
internet_nat       = true
```

The network is created in seconds and is ready for use.
If a new network is required for a second environment, simply copy/edit a new variables file and apply it with the same fabric module.

**_fabric/env/environment2.tfvar:_**
```terraform
vlan_id            = 132
name               = "fabric-env2"
description        = "Fabric ENV2 network"
subnet             = "10.90.132.0/24"
provision_start_ip = "10.90.132.1"
provision_end_ip   = "10.90.132.254"
gateway            = "10.90.132.1"
resolvers          = ["192.168.100.1", "192.168.100.2"]
internet_nat       = true
```

**Conclusions:**

  - new network provisioning takes seconds
  - re-using the same network module for all fabric networks
  - to create new networks, just copy/modify a single file

#### Declaring environment globals

Each environment comes with certain values which are constant across all applications. For example, DNS search path, domain name, log servers, proxy servers, etc. Makes sense to separate these out into environment globals. This way these are managed in one place and reduce the burden on maintaining application specific variable files.

Globals example:

**_globals/fabric-env1.tfvars:_**
```terraform
fabric_id        = "env1"
consul_key       = "false"
consul_dc        = "dc1"
consul_domain    = "env1.consul"
consul_tcns_name = "fabric-env1.consul.svc.myaccount.dc1.domain"
upstream_dns     = "192.168.100.1;192.168.100.2"
ext_tcns_domain  = "myaccount.dc1.domain"
int_tcns_domain  = "myaccount.dc1.domain"
http_proxy       = "http://proxy.service.dc1.env1.consul:3128"
syslog-address   = "syslog.svc.myaccount.dc1.domain:514"
account          = "myaccount"
```

#### Adding instances

There are three basic instance types in Triton; infrastructure containers, Docker containers and VMs. From a provisioning perspective these are divided into two categories, Docker and non-Docker.
Docker containers are provisioned via Triton's DockerAPI while all other resources are provisioned through Triton's built-in CloudAPI endpoint. For this reason to create instances of any type just two basic module types are required, infrastructure and Docker.

The code example below is for an infrastructure container type used to provision Consul nodes (the module is called infra).

**_consul/main.tf:_**
```terraform
locals {
  metadata = {
    app_hooks = file("${path.root}/files/app-hooks.sh")
    config    = file("${path.root}/files/health.json")
  }
  env_vars = <<EOF
ROLE=${var.role}
CONSUL_DC=${var.consul_dc}
CONSUL_DOMAIN=${var.consul_domain}
CONSUL_KEY=${var.consul_key}
CONSUL_TCNS_NAME=${var.consul_tcns_name}
EXT_TCNS_DOMAIN=${var.ext_tcns_domain}
FABRIC_ID=${var.fabric_id}
UPSTREAM_DNS=${var.upstream_dns}
SYSLOG_SRV=${var.syslog-address}
EOF
}

module "consul" {
  source         = "github.com/myorg/terraform-modules.git//triton/infra"
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
  env_vars       = local.env_vars
  metadata       = local.metadata
}

output "instance_name" {
  value = module.consul.instance_name
}

output "primaryip" {
  value = module.consul.primaryip
}

output "compute_node" {
  value = module.consul.compute_node
}
```

**Environment specific variables:**

**_consul/env/environment1.tfvars:_**
```terraform
hostname          = "consul1"
image_name        = "consul"
image_version     = "1.x.x"
package           = "medium"
user_script       = "../../scripts/user-script.sh"
instances         = 3
networks          = ["fabric-env1"]
consul_primary_dc = "false"
role              = "consul"
service_tags      = ["consul-env1"]
```

##### Firewall rules

Firewall rules are managed for all environments for the given application by a single variable file. This ensures that firewall rules are managed in one place for all incarnations of the application in all environments. If a new rule needs to be created or an existing changed it is done via this single file.

**_consul/env/firewall-rules.tfvars_**

```terraform
firewall_rules = {
  rule_any_to_consul_rpc = {
    description = "Server RPC address"
    from        = "tag \"firewall_id\" = \"<FIREWALL_ID>\""
    to          = "tag \"firewall_id\" = \"<FIREWALL_ID>\""
    action      = "ALLOW"
    protocol    = "tcp"
    port        = 8300
    enabled     = true
  },
  rule_any_to_consul_serf_tcp = {
    description = "Serf LAN port TCP"
    from        = "any"
    to          = "tag \"firewall_id\" = \"<FIREWALL_ID>\""
    action      = "ALLOW"
    protocol    = "tcp"
    port        = 8301
    enabled     = true
  }
```

The following declaration is for the haproxy ingestion cluster which is using the same infrastructure module called _"infra"_ as the previous Consul example. Re-using the same module for all infrastructure type instances. The `metadata` and `env_vars` fields are dynamic lists, which can be extended or reduced, this enables flexibility for the majority of instance provisioning use cases.

**_haproxy/main.tf:_**
```terraform
locals {
  metadata = {
    app_hooks      = file("${path.root}/files/app-hooks.sh")
    haproxy_reload = file("${path.root}/files/haproxy-reload.sh")
    haproxy_cfg    = file("${path.root}/files/haproxy.cfg.ctmpl")
    consul_watch   = file("${path.root}/files/watch.json")
    haproxy_health = file("${path.root}/files/health.json")
    proxy_health   = file("${path.root}/files/proxy_health.json")
    certs_sh       = file("${path.root}/files/certs.sh")
    dns_health     = file("${path.root}/files/dns_health.json")
    recursor_conf  = file("${path.root}/files/recursor.conf.ctmpl")
    rsyslog_conf   = file("${path.root}/files/rsyslog.conf")
    syslog_health  = file("${path.root}/files/syslog_health.json")
  }
  env_vars = <<EOF
ROLE=${var.role}
CONSUL_DC=${var.consul_dc}
CONSUL_DOMAIN=${var.consul_domain}
CONSUL_KEY=${var.consul_key}
CONSUL_TCNS_NAME=${var.consul_tcns_name}
EXT_TCNS_DOMAIN=${var.ext_tcns_domain}
IMAGE_VERSION=${var.image_version}
FABRIC_ID=${var.fabric_id}
HTTP_PROXY=${var.http_proxy}
SSL_STAGING=${var.ssl_staging}
SYSLOG_UPSTREAM=${var.syslog-address}
UPSTREAM_DNS=${var.upstream_dns}
EOF
}

module "haproxy" {
  source         = "github.com/myorg/terraform-modules.git//triton/infra"
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
  env_vars       = local.env_vars
  metadata       = local.metadata
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
```

The following variables are supplied to the same infra module.

**_haproxy/env/environment1.tfvars:_**
```terraform
hostname      = "haproxy1"
image_name    = "haproxy"
image_version = "2.x.x"
package       = "medium"
user_script   = "../../scripts/user-script.sh"
instances     = "3"
networks      = ["routable-net", "fabric-env1"]
role          = "haproxy"
service_tags  = ["myweb-env1", "myapi-env1", "..."]
```

Applying this, will create 3 haproxy instances attached to the routable and fabric-env1 networks.

To provision Docker containers, use the same concept as outlined above, but this time use the docker module instead.
This example will use the official consul-exporter docker image, without modification. This also means that stock Docker images and custom built ones can be provisioned the same way with no modification to the underlying terraform module.

**_consul-exporter/main.tf:_**
```terraform
locals {
  command = ["--consul.server=${var.consul_tcns_name}:8500"]
  image   = "${var.image}:${var.docker_tag}"
  log_opts = {
    "syslog-address"  = "udp://${var.syslog-address}"
    "syslog-facility" = "daemon"
    "syslog-tag"      = var.labels.triton_cns_services.value
  }
}

module "consul-exporter" {
  source       = "github.com/myorg/terraform-modules.git//triton/docker"
  instances    = var.instances
  hostname     = var.hostname
  image        = local.image
  ports        = var.ports
  env          = var.app_env
  command      = local.command
  entrypoint   = var.entrypoint
  upload_files = var.upload_files
  labels       = var.labels
  log_driver   = var.log_driver
  log_opts     = local.log_opts
}
```

**_consul-exporter/env/fabric-env1.tfvars:_**
```terraform
instances   = "1"
docker_host = "tcp://docker.dc.domain:2376"
hostname    = "consul-exp1"
account     = "myaccount"
docker_tag  = "latest"
app_env     = ["ROLE=exporter"]
entrypoint  = ["/bin/consul_exporter"]
image       = "prom/consul-exporter"
ports       = ["9107"]
log_driver  = "syslog"

labels = {
  triton_cns_disable = {
    label = "triton.cns.disable"
    value = "false"
  },
  triton_cns_services = {
    label = "triton.cns.services"
    value = "csl-exporter-env1"
  },
  com_joyent_package = {
    label = "com.joyent.package"
    value = "small"
  },
  com_docker_swarm_affinities = {
    label = "com.docker.swarm.affinities"
    value = "[\"container!=~consul-exp1*\"]"
  },
  triton_network_public = {
    label = "triton.network.public"
    value = "fabric-env1"
  }
}
```

From the examples provided above a generic provisioning pattern is emerging. This pattern is highly re-usable for the creation of repeatable infrastructure that only requires *three terraform modules*. These three modules cover the full spectrum of machine and network life-cycle management.

---

### Milestone #3 - Cloning Environments

As demonstrated in the examples above an environment can be fully packaged into a self-sustainable logical fabric unit. The same pattern which enabled applications and networks to be provisioned by simple variable changes can be re-used to create copies of existing environments or the addition of new environments - by simple file/copy/replace actions. The same model holds true for multi-DC and DR deployment scenarios.

Lastly the modularity and repeatability of fabrics lends itself naturally to secure isolation controls detailed in the next section.

---

### Access Boundaries

The following section is an overview of the various built-in isolation and protection mechanisms designed to prevent unauthorized access or changes.

#### The account model and its impact

Each set of distinct environments is isolated into its own top level Triton account.

This per account model ensures that environments are fully confined not just from the usual network boundaries perspective but also in terms of ownership. This distinct ownership model guarantees that environments don't clash with each other, e.g. changes in dev cannot impact production or that access under one account is confined to its own resources only.

The end result is a clear set of visible isolation boundaries which are simple to reason about.

Triton was designed from the start with multi-tenancy in mind for public Cloud. Top level accounts are effectively treated as standalone untrusted tenants of the Cloud. This strict account isolation model runs down very deep into fine grained control aspects and each object's ownership is enforced.

In practice this means that each machine's NIC (mac address), IP address, DNS record, image, etc. has an ownership attached to it. Only the owner is allowed to see or modify these.

This ownership model is also applied to each VLAN, subnet, fabric, SSH key, firewall rule and many other properties. Administrative access under account A has nothing to do with account B, in other words a dev account is unable to influence production resources.

Each account also provides additional built-in resource limits. An account can be limited to certain number of instances, RAM, CPU and disk space.

#### Instance protection mechanisms

Each instance inherits certain network protection defaults such as immutable MAC addresses (to prevent ARP spoofing) or IP addresses. Certain traffic types are classified as restricted and prohibited.

Additionally there are built-in deletion protection flags, to prevent accidental instance deletion or data loss for vital workloads.

#### Firewall

Firewall rules in Triton are instance, IP, tag and account aware. By default all inbound traffic is blocked to instances except ICMP.
In practice this means that network traffic and filtering rules can be managed in a very effective and automated way. For example to allow certain type of traffic between specific instances based on ownership or a number of other aspects such as tags a similar rule can be employed  `ALLOW from my machines tagged webserver to my machines tagged mysql TCP port 3389`.

#### Networks

Ownership is also applied to networks. A non-fabric network can have one or multiple owners, a fabric network however can only have a single owner. Changing a fabric network's ownership is not allowed nor supported - therefore this is a great isolation/encapsulation barrier.

#### Ingestion endpoints

A set of dedicated Haproxy instances are the only way to get into a fabric environment. They are in essence application gateway nodes and serve as an additional isolation and protection element on top of firewalling.

#### DNS

Each DNS record in TCNS is namespaced under the account it belongs to. Therefore a DNS record namespaced under production cannot be altered from other accounts such as dev or uat.

## Final notes

The architecture described in this document is highly modular and easy to modify and extend to evolving requirements. Each individual piece is replaceable, repeatable and scalable on its own. Majority of the elements, concepts and software is portable and forms a future-proof model in line with emerging service mesh initiatives.

The software products and components mentioned in this document are all Opensource and have proven production use track record. The focus is on small, simple, repeatable concepts and patterns forming a larger, scalable and maintainable production safe system.
