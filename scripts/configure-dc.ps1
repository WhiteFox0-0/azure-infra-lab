#Requires -RunAsAdministrator
# Post-promotion config for DC1: OUs, DNS forwarder, DHCP scope, Home share.
# Run once after DC1 reboot. Idempotent — safe to re-run.

$ErrorActionPreference = 'Stop'
$base = 'DC=inflab,DC=local'

# OUs
foreach ($ou in 'Staff', 'Groups', 'Servers') {
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ou'" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $ou -Path $base -ProtectedFromAccidentalDeletion $false
        Write-Host "OU created: $ou"
    }
}

# DNS forwarder so the DC resolves internet names (Azure resolver)
if (-not (Get-DnsServerForwarder | Where-Object IPAddress -eq '168.63.129.16')) {
    Add-DnsServerForwarder -IPAddress '168.63.129.16'
    Write-Host 'DNS forwarder added: 168.63.129.16'
}

# DHCP scope (DCs are auto-authorized in AD)
if (-not (Get-DhcpServerv4Scope -ErrorAction SilentlyContinue | Where-Object Name -eq 'inflab-lab')) {
    Add-DhcpServerv4Scope -Name 'inflab-lab' -StartRange 10.10.1.100 -EndRange 10.10.1.200 `
        -SubnetMask 255.255.255.0 -State Active
    Set-DhcpServerv4OptionValue -ScopeId 10.10.1.0 -DnsServer 10.10.1.4 -DnsDomain 'inflab.local'
    Write-Host 'DHCP scope created: 10.10.1.100-200'
}

# Home share (target of the GPO mapped drive)
New-Item -Path 'C:\Shares\Home' -ItemType Directory -Force | Out-Null
if (-not (Get-SmbShare -Name 'Home' -ErrorAction SilentlyContinue)) {
    New-SmbShare -Name 'Home' -Path 'C:\Shares\Home' `
        -FullAccess 'INFLAB\Domain Admins' -ChangeAccess 'Authenticated Users'
    Write-Host 'SMB share created: \\inflab.local\Home'
}

Write-Host 'DC1 configuration complete.'
