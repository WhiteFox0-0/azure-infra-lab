# Runbook — Week 2: Active Directory (DC1 → users → GPO → DC2)

## 0. Cost habit
DC1 is `vm_size` (default `Standard_B2s_v2`, ~₹4-5/hr — classic `B2s` is capacity-blocked
in centralindia; override in tfvars if needed). Auto-shutdown is scheduled at **21:30 IST**. When done for
the day: `az vm deallocate -g rg-inflab -n dc1` (config preserved, ~₹6/day disks).

## 1. Deploy DC1
```bash
cd terraform
# terraform.tfvars must contain admin_password (12+ chars, upper+lower+digit+symbol)
terraform plan && terraform apply
terraform output dc1_rdp      # public IP for mstsc
```
NSG: servers subnet now allows RDP from **your IP only** (rule `allow-rdp-ssh-from-my-ip`).

## 2. First login + promote
1. `mstsc /v:<dc1_rdp>` as `.\labadmin` / your password
2. Copy the `scripts/` folder onto the VM (RDP drag-and-drop)
3. PowerShell **as Administrator**:
```powershell
cd C:\scripts
.\promote-dc1.ps1 -DSRMPassword 'Some-Strong-2026!'   # renames to DC1, reboots
# after reboot, log in again (still local .\labadmin), then:
.\promote-dc1.ps1 -DSRMPassword 'Some-Strong-2026!'   # promotes, reboots
# after promotion you log in as INFLAB\labadmin
```

## 3. Configure the domain
```powershell
.\configure-dc.ps1        # OUs (Staff/Groups/Servers), DNS forwarder, DHCP scope, Home share
.\new-users-from-csv.ps1 -CsvPath .\users.csv -InitialPassword 'Lab-Passw0rd-2026!'
.\set-gpos.ps1            # password policy + Restrict-TaskManager + H: drive map
```
Verify:
```powershell
Get-ADUser -Filter * -Properties Enabled | Measure-Object   # expect 13 (12 users + labadmin)
Get-ADOrganizationalUnit -Filter * | Select Name
Get-GPO -All
gpresult /r               # (after login to a Staff user) shows both GPOs applied
```
Test as a user: log in as `INFLAB\amina.hassan` → H: drive appears, Task Manager blocked,
password change forced at first logon.

## 4. Point Azure DNS at the DC
```bash
az network vnet update -g rg-inflab -n vnet-inflab --dns-servers 10.10.1.4
```
(From here on, VMs in this VNet resolve `inflab.local`. The DC itself forwards
internet lookups to 168.63.129.16.)

## 5. Phase B — second DC + replication
```bash
# add DC2 block to terraform (same shape as dc1.tf: private IP 10.10.1.5), then:
terraform apply
```
1. RDP to DC2 as `.\labadmin`
2. Copy `scripts/`, run: `.\promote-dc2.ps1 -DSRMPassword '...' -DomainCredential (Get-Credential)`
   (credential: `Administrator` / your RDP password) → reboots, joins as DC2
3. On either DC:
```powershell
.\test-replication.ps1    # repadmin /replsummary + metadata + dcdiag — all green
```
**Done when:** `repadmin /replsummary` shows 0 fails for DC1/DC2.

## 6. End of week
```bash
az vm deallocate -g rg-inflab -n dc1   # and dc2 when idle
```
