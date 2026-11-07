# Runbook — Week 1: apply / destroy

## Prerequisites
```bash
brew install terraform azure-cli   # already done on this machine
az login
az account set --subscription <your-sub-id>
```

## First-time setup
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars:
#   admin_source_ip = "$(curl -s ifconfig.me)/32"
#   budget_contact_emails = ["you@example.com"]
terraform init
```

## Deploy
```bash
terraform plan    # review: budget, RG, VNet, 2 subnets, 2 NSGs
terraform apply
```

Done criteria: apply exits 0, outputs show resource group + NSG names.

## Verify
```bash
az network nsg list -o table
az network vnet show -g rg-inflab -n vnet-inflab --query "subnets[].{name:name,prefix:addressPrefix}" -o table
```

## Destroy (must be clean)
```bash
terraform destroy
```
Done criteria: destroy exits 0, `az group list` no longer shows `rg-inflab`.

## Budget note
Budget alert (`budget-inflab`) is created in the same apply, scoped to the
subscription. Delete it with the rest of the stack on destroy. Alert thresholds:
80% and 100% of `budget_amount` (default $25).

## Bastion
Default off. To enable: set `enable_bastion = true`, apply, and remember it
bills while the host exists (~$0.19/hr). Turn off when not needed:
`enable_bastion = false && terraform apply`.
