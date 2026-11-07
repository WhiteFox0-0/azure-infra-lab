#Requires -RunAsAdministrator
<#
  Baseline hardening for a domain controller lab — safe, reversible settings
  that map to common CIS/Windows Server baselines. Run on DC1 and DC2; idempotent.
#>
$ErrorActionPreference = 'Stop'
$report = @()

# --- 1. SMBv1 off (legacy, exploit history: WannaCry) ---
$smb1 = Get-SmbServerConfiguration
if ($smb1.EnableSMB1Protocol) {
    Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
    $report += 'SMBv1: disabled (was enabled)'
} else { $report += 'SMBv1: already disabled' }

# --- 2. LLMNR off (Responder/spoofing) ---
$dnsClient = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient'
if (-not (Test-Path $dnsClient)) { New-Item $dnsClient -Force | Out-Null }
Set-ItemProperty $dnsClient EnableMulticast 0 -Type DWord
$report += 'LLMNR: disabled'

# --- 3. Audit policy (subset of CIS: logon, account logon, object access, policy change) ---
auditpol /set /subcategory:'Logon' /success:enable /failure:enable | Out-Null
auditpol /set /subcategory:'Logoff' /success:enable | Out-Null
auditpol /set /subcategory:'Account Lockout' /success:enable /failure:enable | Out-Null
auditpol /set /subcategory:'Special Logon' /success:enable | Out-Null
auditpol /set /subcategory:'Security Group Management' /success:enable | Out-Null
auditpol /set /subcategory:'User Account Management' /success:enable /failure:enable | Out-Null
auditpol /set /subcategory:'Sensitive Privilege Use' /success:enable /failure:enable | Out-Null
$report += 'Audit policy: logon/lockout/account-mgmt/sensitive-priv enabled'

# --- 4. Defender: real-time + cloud-delivered protection on ---
try {
    Set-MpPreference -DisableRealtimeMonitoring $false -MAPSReporting Advanced -SubmitSamples SendSafe
    $report += 'Defender: real-time + MAPS advanced enabled'
} catch { $report += 'Defender: ' + $_.Exception.Message.Split('.')[0] }

# --- 5. RDP: require NLA (already default on Azure, enforce anyway) ---
$nla = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
Set-ItemProperty $nla UserAuthentication 1 -Type DWord
$report += 'RDP: NLA enforced'

# --- 6. Password policy reminder (set via secedit during domain setup) ---
$pol = secedit /export /cfg - 2>$null | Out-String
$minLen = ([regex]::Match($pol, 'MinimumPasswordLength\s*=\s*(\d+)')).Groups[1].Value
$report += "Password policy: min length = $minLen (expect 12)"

# --- 7. Windows Firewall: ensure domain profile on ---
Set-NetFirewallProfile -Profile Domain -Enabled True
$report += 'Firewall: Domain profile enabled'

$report | ForEach-Object { Write-Host "[hardening] $_" }
Write-Host "[hardening] DONE on $env:COMPUTERNAME"
