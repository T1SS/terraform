## Consul exporter Docker instance

```bash
export ENV=myenv1
export DC=mydc

# initalize provider
# optionally supply -updgrade to get the latest provider version

$ terraform init -reconfigure -backend-config=env/${DC}-fabric-${ENV}.tfbackend

# create a plan

$ terraform plan -var-file=env/${DC}-fabric-${ENV}.tfvars -var-file=../../globals/${DC}-fabric-${ENV}.tfvars -out=my.tfplan

# execute provisioning

$ terraform apply "my.tfplan"

# destroy instances

$ terraform plan -var-file=env/${DC}-fabric-${ENV}.tfvars -var-file=../../globals/${DC}-fabric-${ENV}.tfvars -out=my-destroy.tfplan -destroy

$ terraform apply "my-destroy.tfplan"
```
