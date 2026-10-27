param([Parameter(Mandatory=$true)][string]$OutputPath)
$ErrorActionPreference = 'Stop'
try {
    Import-Module (Join-Path $PSScriptRoot '..\Turbo.Core.psm1') -Force -ErrorAction Stop
    $snapshot = New-TurboSnapshot
    $result = [pscustomobject]@{ Success=$true; Snapshot=$snapshot; Message='Диагностика завершена.' }
} catch {
    $result = [pscustomobject]@{ Success=$false; Message=$_.Exception.Message }
}
try {
    $result | ConvertTo-Json -Depth 9 | Set-Content -LiteralPath $OutputPath -Encoding UTF8 -ErrorAction Stop
} catch { exit 2 }
if (-not $result.Success) { exit 1 }
