param([Parameter(Mandatory=$true)][string]$OutputPath)
$ErrorActionPreference = 'Stop'
try {
    Import-Module (Join-Path $PSScriptRoot '..\Turbo.Security.psm1') -Force -ErrorAction Stop
    $checks = @(Get-TurboSecurityAudit)
    $result = [pscustomobject]@{Success=$true;Mode='SecurityAudit';Checks=$checks;Message="Проверено параметров: $($checks.Count). Это аудит конфигурации, а не тест на проникновение."}
} catch {
    $result = [pscustomobject]@{Success=$false;Mode='SecurityAudit';Message=$_.Exception.Message}
}
try {$result|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $OutputPath -Encoding UTF8 -ErrorAction Stop} catch {exit 2}
if (-not $result.Success){exit 1}
