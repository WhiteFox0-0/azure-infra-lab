# Runbook — Active Directory (DC1 → users → GPO → DC2)

## 0. Cost habit
DC1 is `vm_size` (default `Standard_B2s_v2`; classic `B2s` is capacity-blocked in
centralindia; override in tfvars if needed). Auto-shutdown is scheduled at **21:30 IST**. When done for
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
2. Copy `scripts/` to the VM — RDP drag-and-drop is unsupported in some clients;
   reliable path is base64 via run-command:
```bash
B64=$(base64 -i scripts/promote-dc1.ps1 | tr -d '\n')
az vm run-command invoke -g rg-inflab -n dc1 --command-id RunPowerShellScript \
  --scripts "[IO.File]::WriteAllBytes('C:\scripts\promote-dc1.ps1',[Convert]::FromBase64String('$B64'))"
# repeat per script (configure-dc.ps1, new-users-from-csv.ps1, users.csv, set-gpos.ps1, …)
```
3. Promote (run-command, reboot is expected — session may wedge, restart VM if stuck):
```powershell
.\promote-dc1.ps1 -DSRMPassword 'DsrM-Secure-2026!42'   # renames to DC1, reboots
# after reboot: run again → promotes, reboots
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
Test as a user: log in as `INFLAB\amina.hassan` / `Lab-Passw0rd-2026!` → H: drive appears,
Task Manager blocked, password change forced at first logon.

### GPP gotchas (learned the hard way — keep for future GPO work)
- GPO invisible to `gpresult` entirely → `gPCUserExtensionNames` empty; set
  `[{CSE-GUID}{Tool-GUID}]` (Drives: `{5794DAFD-BE60-433f-88A2-1A31939AC01F}{2EA1A81B-48E5-45E9-8BB7-A6E3AC170006}`)
- "Missing drive letter" 0x80070057 → attribute is **`letter="H"`**, not `driveLetter=`; container clsid
  is `{8FDDCC1A-0C3C-43cd-A6B4-71A6DF20DA8C}`; no BOM; bump `gpt.ini` + AD `versionNumber` after edits
  (AD version attr is `versionNumber`, not `gPCVersion`).

## 4. Point Azure DNS at the DC
```bash
az network vnet update -g rg-inflab -n vnet-inflab --dns-servers 10.10.1.4
```
(From here on, VMs in this VNet resolve `inflab.local`. The DC itself forwards
internet lookups to 168.63.129.16.)

## 5. Phase B — second DC + replication
```bash
# dc2.tf (same shape as dc1.tf: private IP 10.10.1.5, pip-inflab-dc2, auto-shutdown), then:
terraform apply
```
1. Upload `promote-dc2.ps1` + `test-replication.ps1` via base64 run-command (step 2 above)
2. Promote via run-command (domain credential is `inflab\labadmin` / admin password;
   plain `labadmin` without domain prefix fails with "Unable to update the password"):
```powershell
$dsrm = ConvertTo-SecureString 'DsrM-Secure-2026!42' -AsPlainText -Force
$cred = [pscredential]::new('inflab\labadmin', (ConvertTo-SecureString '<admin_password>' -AsPlainText -Force))
Install-WindowsFeature AD-Domain-Services,DNS,DHCP -IncludeManagementTools
Install-ADDSDomainController -DomainName inflab.local -SafeModeAdministratorPassword $dsrm -InstallDns -Credential $cred -Force
```
   Post-promotion reboot may wedge the run-command session (stuck "Updating") → `az vm restart -g rg-inflab -n dc2`
3. On DC2 run: `.\test-replication.ps1`
```powershell
# expect: replsummary 0 fails both DCs; partner metadata LastReplicationResult=0;
# DC2 sees 12 Staff users + 4 GPOs
```
**Done when:** `repadmin /replsummary` shows 0 fails for DC1/DC2.

## 6. Teardown
```bash
az vm deallocate -g rg-inflab -n dc1   # and dc2 when idle
```

## 7. Hardening, backup & monitoring
See `docs/security.md` (commands + teardown order).
