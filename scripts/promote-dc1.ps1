#Requires -RunAsAdministrator
<#
  Run 1: renames the machine to DC1 and restarts.
  Run 2 (after reboot): installs AD DS + DNS + DHCP and promotes to first DC.
  Promotion reboots the machine automatically.
  Usage: .\promote-dc1.ps1 -DSRMPassword 'Some-Strong-2026!'
#>
param(
    [Parameter(Mandatory)]
    [string]$DSRMPassword
)

$ErrorActionPreference = 'Stop'
$domain = 'inflab.local'
$netbios = 'INFLAB'

if ((Get-CimInstance Win32_ComputerSystem).Name -ne 'DC1') {
    Rename-Computer -NewName 'DC1' -Force
    Write-Host 'Renamed to DC1 — rebooting. Run this script again after login.'
    Restart-Computer -Force
    exit
}

Install-WindowsFeature AD-Domain-Services, DNS, DHCP -IncludeManagementTools

# DomainRole: 4=backup DC, 5=primary DC — ntds.dit existence is NOT reliable
# (a failed promotion leaves files behind and fakes "already promoted")
if ((Get-CimInstance Win32_ComputerSystem).DomainRole -lt 4) {
    $dsrm = ConvertTo-SecureString $DSRMPassword -AsPlainText -Force
    Install-ADDSForest -DomainName $domain -DomainNetbiosName $netbios `
        -SafeModeAdministratorPassword $dsrm -InstallDns -Force
    # machine reboots here; script ends
}
else {
    Write-Host 'Already promoted.'
}
