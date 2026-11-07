#Requires -RunAsAdministrator
<#
  Promotes a second domain controller in inflab.local.
  Prereqs (see runbook): VNet DNS already pointed at 10.10.1.4,
  machine renamed, AD DS role installed by this script.
  Usage: .\promote-dc2.ps1 -DSRMPassword 'Same-As-DC1!' -DomainCredential (Get-Credential)
  DomainCredential: Administrator@inflab.local / your RDP password.
#>
param(
    [Parameter(Mandatory)]
    [string]$DSRMPassword,

    [Parameter(Mandatory)]
    [pscredential]$DomainCredential
)

$ErrorActionPreference = 'Stop'

if ((Get-CimInstance Win32_ComputerSystem).Name -ne 'DC2') {
    Rename-Computer -NewName 'DC2' -Force
    Write-Host 'Renamed to DC2 — rebooting. Run this script again after login.'
    Restart-Computer -Force
    exit
}

Install-WindowsFeature AD-Domain-Services, DNS, DHCP -IncludeManagementTools

# DomainRole 4/5 = already a DC (ntds.dit check lies after failed attempts)
if ((Get-CimInstance Win32_ComputerSystem).DomainRole -lt 4) {
    $dsrm = ConvertTo-SecureString $DSRMPassword -AsPlainText -Force
    Install-ADDSDomainController -DomainName 'inflab.local' `
        -SafeModeAdministratorPassword $dsrm -InstallDns `
        -Credential $DomainCredential -Force
}
else {
    Write-Host 'Already a domain controller.'
}
