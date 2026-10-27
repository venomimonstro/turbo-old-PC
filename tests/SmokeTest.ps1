param([switch]$FullDiagnostics)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$files = @(foreach ($folder in @('app','install','tools','tests')) {
    Get-ChildItem -LiteralPath (Join-Path $root $folder) -Recurse -File |
        Where-Object { $_.Extension -in @('.ps1','.psm1') }
})
if ($files.Count -lt 5) { throw 'Не найдены основные скрипты проекта.' }

foreach ($file in $files) {
    $tokens = $null
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile(
        $file.FullName, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count -gt 0) {
        throw "Ошибка PowerShell в $($file.Name): $($parseErrors[0].Message)"
    }
    Write-Host "PASS: syntax $($file.Name)"
}

$gui = Get-Content -LiteralPath (Join-Path $root 'app\TurboOldPC.ps1') -Raw -Encoding UTF8
$match = [regex]::Match($gui, "(?s)\[xml\]\`$xaml\s*=\s*@'\s*(.*?)\s*'@")
if (-not $match.Success) { throw 'XAML GUI not found.' }
[xml]$view = $match.Groups[1].Value
if ($view.DocumentElement.LocalName -ne 'Window') { throw 'Некорректный корневой элемент XAML.' }
$names = @(Select-Xml -Xml $view -XPath "//*[@*[local-name()='Name']]" |
    ForEach-Object { $_.Node.GetAttribute('Name','http://schemas.microsoft.com/winfx/2006/xaml') })
foreach ($required in @('MainTabs','BtnAnalyze','BtnScan','BtnScanFull','BtnTempPreview',
 'BtnTempClean','BtnDriversUpdate','WorkProgress','NavHome','NavSecurity','NavCleanup')) {
    if ($required -notin $names) { throw "В XAML отсутствует элемент: $required" }
}
Write-Host 'PASS: GUI XML and essential controls'
foreach ($required in @('NavAudit','NavBoost','BtnDriverSearch','BtnDriverInstall',
 'DriverUpdatesGrid','BtnSecurityAudit','SecurityGrid','BtnBoostUI',
 'BtnBoostPower','BtnBoostRestore','BtnScanOffline')) {
    if ($required -notin $names) { throw "Missing v0.3 dashboard control: $required" }
}
Write-Host 'PASS: security/driver/boost controls present'
$securityModule = Join-Path $root 'app\Turbo.Security.psm1'
Import-Module -Name $securityModule -Force -ErrorAction Stop
if (-not (Get-Command Get-TurboSecurityAudit -ErrorAction SilentlyContinue)) {
    throw 'Security audit module export unavailable.'
}
Write-Host 'PASS: security audit module imports'

Import-Module (Join-Path $root 'app\Turbo.Core.psm1') -Force -ErrorAction Stop
$previousLocal = $env:LOCALAPPDATA
$sandbox = Join-Path ([IO.Path]::GetTempPath()) ('TurboOldPC-Smoke-' + [guid]::NewGuid().ToString('N'))
$fakeTemp = Join-Path $sandbox 'Temp'
[void][IO.Directory]::CreateDirectory($fakeTemp)
try {
    $env:LOCALAPPDATA = $sandbox
    $old = Join-Path $fakeTemp 'old-cache.tmp'
    $new = Join-Path $fakeTemp 'in-use-recent.tmp'
    [IO.File]::WriteAllText($old, 'This is old temp data.')
    [IO.File]::SetLastWriteTime($old, (Get-Date).AddDays(-5))
    [IO.File]::WriteAllText($new, 'This is recent temp data.')

    $preview = Get-TurboTempCandidates -MinimumAgeHours 48
    if ($preview.Count -ne 1) { throw "Ожидался 1 старый файл, получено: $($preview.Count)" }
    if (-not (Test-Path -LiteralPath $old)) { throw 'Предпросмотр неожиданно удалил файл.' }
    Write-Host 'PASS: preview does not delete data'

    $result = Clear-TurboTemp -Preview $preview
    if ($result.Deleted -ne 1 -or (Test-Path -LiteralPath $old) -or -not (Test-Path -LiteralPath $new)) {
        throw 'Очистка тестовых файлов выполнилась неправильно.'
    }
    Write-Host 'PASS: only old user temp data removed'

    $forged = [pscustomobject]@{
        Root = 'C:\Windows'
        Files = @([pscustomobject]@{ Path = 'C:\Windows\not-a-real-file'; Bytes = 10 })
    }
    $blocked = $false
    try { Clear-TurboTemp -Preview $forged | Out-Null } catch { $blocked = $true }
    if (-not $blocked) { throw 'Не сработала проверка разрешённой папки.' }
    Write-Host 'PASS: unauthorized system path rejected'
    # Read-only boost history must work without touching a real user's registry.
    $boostOutput = Join-Path $sandbox 'boost-history.json'
    & (Join-Path $root 'app\Workers\Boost.ps1') -Mode History -OutputPath $boostOutput
    if (-not (Test-Path -LiteralPath $boostOutput)) { throw 'Boost history did not create a result.' }
    $boostResult = Get-Content -LiteralPath $boostOutput -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $boostResult.Success) { throw 'Boost history read failed.' }
    Write-Host 'PASS: boost history sandbox test'
} finally {
    $env:LOCALAPPDATA = $previousLocal
    if (Test-Path -LiteralPath $sandbox) {
        Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue
    }
}
if ($FullDiagnostics) {
    $snapshot = New-TurboSnapshot
    if ($null -eq $snapshot.Hardware) {
        throw "Диагностика оборудования не удалась: $($snapshot.Error)"
    }
    Write-Host "PASS: live hardware diagnostics $($snapshot.Hardware.Model)"
}
Write-Host 'ALL SMOKE TESTS PASSED'
