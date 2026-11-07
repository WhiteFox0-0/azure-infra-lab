#Requires -RunAsAdministrator
<#
  Group Policy setup:
  1. Domain password policy (complexity, 12 chars, 60-day age, lockout)
  2. Restriction GPO: Task Manager disabled for Staff OU (change ValueName for other restrictions)
  3. Mapped drive: H: -> \\inflab.local\Home via Group Policy Preferences (Drives.xml in SYSVOL)
#>
$ErrorActionPreference = 'Stop'
Import-Module GroupPolicy

$staffOU = 'OU=Staff,DC=inflab,DC=local'

# --- 1. Password policy (effective domain policy) ---
Set-ADDefaultDomainPasswordPolicy -Identity 'inflab.local' `
    -MinPasswordLength 12 `
    -ComplexityEnabled $true `
    -MaxPasswordAge (New-TimeSpan -Days 60) `
    -MinPasswordAge (New-TimeSpan -Days 1) `
    -PasswordHistoryCount 12 `
    -LockoutThreshold 5 `
    -LockoutDuration (New-TimeSpan -Minutes 15) `
    -LockoutObservationWindow (New-TimeSpan -Minutes 15)
Write-Host 'Password/lockout policy set.'

# --- 2. Restriction: disable Task Manager for Staff ---
if (-not (Get-GPO -Name 'Restrict-TaskManager' -ErrorAction SilentlyContinue)) {
    New-GPO -Name 'Restrict-TaskManager' | Out-Null
}
Set-GPRegistryValue -Name 'Restrict-TaskManager' `
    -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System' `
    -ValueName 'DisableTaskMgr' -Type DWord -Value 1
New-GPLink -Name 'Restrict-TaskManager' -Target $staffOU -LinkEnabled Yes -ErrorAction SilentlyContinue | Out-Null
Write-Host 'GPO linked: Restrict-TaskManager -> Staff'

# --- 3. Mapped drive H: via GPP (written to SYSVOL, replicates to all DCs) ---
$gpoName = 'Map-H-Drive'
if (-not (Get-GPO -Name $gpoName -ErrorAction SilentlyContinue)) {
    New-GPO -Name $gpoName | Out-Null
}
$gpoId = (Get-GPO -Name $gpoName).Id
$prefDir = "\\inflab.local\SYSVOL\inflab.local\Policies\{$gpoId}\User\Preferences\Drives"
New-Item -Path $prefDir -ItemType Directory -Force | Out-Null

$uid = "{$([guid]::NewGuid().ToString().ToUpper())}"
$drivesXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<Drives clsid="{8FDDCC1A-019F-4826-9814-03B453CF70C1}">
  <Drive clsid="{935D1B74-9CB8-4e3c-9914-7DD559B7A417}" name="H: (Home)" status="H: (Home)" image="2" changed="2026-11-07 00:00:00" uid="$uid">
    <Properties action="U" thisDrive="NOCHANGE" driveLetter="H:" allDrives="NOCHANGE" path="\\inflab.local\Home" label="Home" persistent="1" useLetter="1" userName="" />
    <Filters />
  </Drive>
</Drives>
"@
Set-Content -Path (Join-Path $prefDir 'Drives.xml') -Value $drivesXml -Encoding UTF8

New-GPLink -Name $gpoName -Target $staffOU -LinkEnabled Yes -ErrorAction SilentlyContinue | Out-Null
gpupdate /force | Out-Null
Write-Host 'GPO linked: Map-H-Drive -> Staff (H: = \\inflab.local\Home)'

Get-GPO -All | Select-Object DisplayName, CreationTime | Format-Table -AutoSize
