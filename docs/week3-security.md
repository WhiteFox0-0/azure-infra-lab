# Week 3 — Security Hardening, Backup & Monitoring

## What was done

### 1. OS hardening (both DCs, `scripts/harden-dc.ps1`)
| Control | Setting | Why (baseline ref) |
|---|---|---|
| SMBv1 | disabled | legacy protocol, WannaCry exploit path (CIS: disable unused legacy protocols) |
| LLMNR | disabled via policy | multicast spoofing (Responder) |
| Audit policy | logon/logoff, account lockout, special logon, security group mgmt, user account mgmt, sensitive privilege use — success+failure | CIS audit subcategory baseline subset |
| Defender | real-time on, MAPS=Advanced, sample submission safe | endpoint protection baseline |
| RDP | NLA enforced | pre-auth, reduces unauth RDP exposure |
| Password policy | min length 12, complexity (Week 2) — re-verified | domain policy |
| Windows Firewall | Domain profile enabled | host firewall baseline |

Run: `az vm run-command invoke -g rg-inflab -n dc1 --command-id RunPowerShellScript --scripts "C:\scripts\harden-dc.ps1"` (same for dc2).
Script is idempotent — safe to re-run; prints per-control status.

### 2. Backup — Recovery Services vault
- Vault `rv-inflab` (centralindia), policy `DefaultPolicy` (daily 23:00, 30-day retention)
- DC1 + DC2 enrolled (`az backup protection enable-for-vm`)
- Vault soft-delete (immutable) is on by default → deleted backups recoverable 14 days

Verify:
```bash
az backup item list -g rg-inflab -v rv-inflab --backup-management-type AzureIaasVM -o table
```

### 3. Monitoring — Log Analytics + flow logs + alerts
- **`law-inflab`** Log Analytics workspace (30-day retention; free tier covers this lab)
- **VNet flow logs** `fl-vnet-inflab` → storage `sinflabdiag` (7-day) + traffic analytics → LAW
  - Note: NSG flow logs creation is blocked since Jun 2025 (retirement Sep 2027);
    VNet flow logs are the supported replacement — used that.
- **Metric alerts**: `alert-dc1-cpu`, `alert-dc2-cpu` (avg CPU > 80%, 5m window, severity 2)
- Budget alert `budget-inflab` ($25, 80%/100%) already from Week 1

### 4. Cost posture (lab will be torn down after portfolio use)
- Auto-shutdown both DCs 21:30 IST; `az vm deallocate` when idle (~₹6/day disks each)
- Backup vault + LAW + flow-log storage ≈ ₹200-400/month while alive
- Deallocate stops compute; delete `rv-inflab`/`law-inflab`/`sinflabdiag` at teardown for ₹0

## Teardown order (when done with portfolio)
```bash
az backup item list -g rg-inflab -v rv-inflab -o table          # sanity check
terraform destroy                                               # VMs, NICs, PIPs, VNet, NSGs
az storage account delete -g rg-inflab -n sinflabdiag --yes
az monitor log-analytics workspace delete -g rg-inflab -n law-inflab --yes
az backup vault delete -g rg-inflab -n rv-inflab
az network watcher flow-log delete -g rg-inflab -n fl-vnet-inflab
az group delete -g rg-inflab --yes                               # catches stragglers
```

## JD mapping (Enterprise Infrastructure Engineer)
- "security hardening / compliance": audit policy, protocol hardening, NLA, baseline script
- "backup & disaster recovery": vault + daily policy + soft-delete
- "monitoring & alerting": LAW, flow logs + traffic analytics, metric alerts, budget alert
- "Infrastructure as Code": Terraform for compute/network; runbook documents CLI-managed ops resources
