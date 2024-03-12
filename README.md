## Triton instances provisioned with Terraform

Sample apps to deploy instances on top of Triton Data Center utilizing Terraform modules.
Modules are part of this [repo](https://github.com/T1SS/terraform-modules).

Some of the apps in this repo:

  - consul-exporter (docker)
  - haproxy (smartos container)

```
services/
|-- consul-exporter
|   |-- README.md
|   |-- env
|   |   |-- dc1-fabric-dev1.tfbackend
|   |   `-- dc1-fabric-dev1.tfvars
|   |-- files
|   |-- main.tf
|   |-- provider.tf
|   |-- variables.tf
|   `-- versions.tf
`-- haproxy
    |-- README.md
    |-- docs
    |   `-- examples
    |       `-- service-meta-fields.json
    |-- env
    |   |-- dc1-fabric-dev1.tfbackend
    |   `-- dc1-fabric-dev1.tfvars
    |-- files
    |   |-- app-hooks.sh
    |   |-- exporter.conf
    |   |-- haproxy.cfg.ctmpl
    |   |-- health.json
    |   |-- logship.conf
    |   |-- rsyslog.conf
    |   |-- tcns_sd.json.tpl
    |   `-- watch.json
    |-- main.tf
    |-- provider.tf
    |-- variables.tf
    `-- versions.tf
```

The general concept and design is described in the [Building repeatable infrastructure with fabrics](doc/fabric_model.md) document.

