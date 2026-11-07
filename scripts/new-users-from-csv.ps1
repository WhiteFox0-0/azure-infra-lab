<#
  Creates security groups and users in Active Directory from a CSV.
  This is the automation proof for the resume — no clicking in ADUC.

  Usage:
    .\new-users-from-csv.ps1 -CsvPath .\users.csv -InitialPassword 'Lab-Passw0rd-2026!'
#>
param(
    [Parameter(Mandatory)]
    [string]$CsvPath,

    [Parameter(Mandatory)]
    [string]$InitialPassword,

    [string]$StaffOU   = 'OU=Staff,DC=inflab,DC=local',
    [string]$GroupsOU  = 'OU=Groups,DC=inflab,DC=local',
    [string]$Domain    = 'inflab.local'
)

$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory

$users = Import-Csv $CsvPath
if (-not $users) { throw "CSV empty or not found: $CsvPath" }

$required = 'FirstName', 'LastName', 'UserName', 'Group'
$missing = $required | Where-Object { $_ -notin $users[0].PSObject.Properties.Name }
if ($missing) { throw "CSV missing columns: $($missing -join ', ')" }

# Create any missing security groups
foreach ($g in ($users.Group | Sort-Object -Unique)) {
    if (-not (Get-ADGroup -Filter "Name -eq '$g'" -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $g -GroupCategory Security -GroupScope Global -Path $GroupsOU
        Write-Host "Group created : $g"
    }
}

$created = 0
foreach ($u in $users) {
    if (Get-ADUser -Filter "SamAccountName -eq '$($u.UserName)'" -ErrorAction SilentlyContinue) {
        Write-Host "Skipped (exists): $($u.UserName)"
        continue
    }

    New-ADUser `
        -Name "$($u.FirstName) $($u.LastName)" `
        -GivenName $u.FirstName `
        -Surname $u.LastName `
        -SamAccountName $u.UserName `
        -UserPrincipalName "$($u.UserName)@$Domain" `
        -Path $StaffOU `
        -AccountPassword (ConvertTo-SecureString $InitialPassword -AsPlainText -Force) `
        -Enabled $true `
        -ChangePasswordAtLogon $true

    Add-ADGroupMember -Identity $u.Group -Members $u.UserName
    $created++
    Write-Host "User created  : $($u.UserName) -> $($u.Group)"
}

Write-Host "`nDone. $created created, $($users.Count - $created) skipped of $($users.Count) total."
