<#
  Replication verification — run on DC1 or DC2 after DC2 is promoted.
  All three must show success with no errors.
#>
$ErrorActionPreference = 'Continue'

Write-Host '=== repadmin /replsummary ===' -ForegroundColor Cyan
repadmin /replsummary

Write-Host "`n=== Replication partner metadata ===" -ForegroundColor Cyan
Get-ADReplicationPartnerMetadata -Target * |
    Select-Object Server, Partner, LastReplicationResult, LastReplicationSuccess |
    Format-Table -AutoSize

Write-Host "`n=== dcdiag replication test ===" -ForegroundColor Cyan
dcdiag /test:replications /s:DC1
dcdiag /test:replications /s:DC2

$fail = (repadmin /replsummary | Select-String -Pattern 'fails|error' -SimpleMatch)
if ($fail) { Write-Host "`nRESULT: check output above — replication errors found." -ForegroundColor Red }
else       { Write-Host "`nRESULT: replication healthy." -ForegroundColor Green }
