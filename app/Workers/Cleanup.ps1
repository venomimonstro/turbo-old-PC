param(
    [Parameter(Mandatory=$true)][ValidateSet('Preview','Cleanup')][string]$Mode,
    [Parameter(Mandatory=$true)][string]$OutputPath
)
$ErrorActionPreference = 'Stop'
try {
    Import-Module (Join-Path $PSScriptRoot '..\Turbo.Core.psm1') -Force -ErrorAction Stop
    $preview = Get-TurboTempCandidates -MinimumAgeHours 48 -Limit 20000
    if ($Mode -eq 'Preview') {
        $result = [pscustomobject]@{
            Success=$true; Mode='Preview'; Count=$preview.Count; Bytes=$preview.Bytes
            Truncated=$preview.Truncated; Root=$preview.Root; Message='Оценка очистки завершена.'
        }
    } else {
        $deleted = if ($preview.Count -gt 0) { Clear-TurboTemp -Preview $preview } else { [pscustomobject]@{ Deleted=0; Failed=0; FreedBytes=[int64]0 } }
        $result = [pscustomobject]@{
            Success=$true; Mode='Cleanup'; Count=$deleted.Deleted; Failed=$deleted.Failed
            Bytes=$deleted.FreedBytes; Truncated=$preview.Truncated; Root=$preview.Root
            Message='Очистка завершена. Действующие и недоступные файлы не удалялись.'
        }
    }
} catch {
    $result = [pscustomobject]@{ Success=$false; Mode=$Mode; Message=$_.Exception.Message }
}
try {
    $result | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $OutputPath -Encoding UTF8 -ErrorAction Stop
} catch { exit 2 }
if (-not $result.Success) { exit 1 }
