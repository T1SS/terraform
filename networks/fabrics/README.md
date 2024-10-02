```bash
export ENV=myenv1
export  DC=mydc

# Initalize provider for given environment
# optionally supply -updgrade to get the latest provider version

terraform init -reconfigure -backend-config=env/${DC}-fabric-${ENV}.tfbackend

## Deploy and manage

terraform plan -var-file=env/${DC}-fabric-${ENV}.tfvars -out=my.tfplan
terraform apply "my.tfplan"

## Destroy

terraform plan -var-file=env/${DC}-fabric-${ENV}.tfvars -destroy -out=destroy.tfplan
terraform apply "destroy.tfplan"
```
