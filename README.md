# azure-infra-lab

Three-week entry-level Azure infrastructure portfolio project: network foundation →
Windows Server 2022 Active Directory domain → security hardening, backup & monitoring.

Target role: **Enterprise Infrastructure Engineer (entry level)**.

## Architecture

- **Region:** centralindia (policy-restricted subscription), ~₹7,000 budget
- **VNet** `10.10.0.0/16` — subnets `servers` (10.10.1.0/24), `management`, `AzureBastionSubnet` (optional)
- **DC1** `10.10.1.4` — AD DS + DNS + DHCP, domain `inflab.local`, 12 users (OU Staff), 4 GPOs
- **DC2** `10.10.1.5` — second DC, healthy replication (0 fails)
- **GPOs:** password policy (min 12), `Restrict-TaskManager`, `Map-H-Drive` (GPP → H: share)
- **Hardening:** SMBv1 off, LLMNR off, audit policy, Defender MAPS advanced, NLA
- **Backup:** Recovery Services vault `rv-inflab`, both DCs protected (daily 23:00)
- **Monitoring:** Log Analytics `law-inflab`, VNet flow logs + traffic analytics, CPU alerts, $25 budget alert

Diagram: [docs/network-diagram.drawio](docs/network-diagram.drawio) · IP plan: [docs/ip-plan.md](docs/ip-plan.md)

## Layout

```
terraform/          # IaC: RG, VNet, NSGs, DC1, DC2, budget alert, auto-shutdown
scripts/            # PowerShell: promote DCs, configure domain, users CSV, GPOs, hardening
runbooks/           # step-by-step: week1-network, week2-windows-ad
docs/               # IP plan, diagram, week3 security report
```

## Quick start

```bash
cd terraform && terraform apply          # network + both DCs
# follow runbooks/week1-network.md, then week2-windows-ad.md
# hardening/backup/monitoring: docs/week3-security.md
```

## Cost

Auto-shutdown 21:30 IST both DCs; deallocate when idle. Teardown order in
[docs/week3-security.md](docs/week3-security.md) → `terraform destroy` + resource cleanup ≈ ₹0.
