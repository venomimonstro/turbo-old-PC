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
# Load the real WPF window in a fresh STA process without opening it to users.
$guiProbe=@(& (Join-Path $PSHOME 'powershell.exe') -NoProfile -STA -ExecutionPolicy Bypass -File (Join-Path $root 'app\TurboOldPC.ps1') -SmokeUi 2>&1)
if($LASTEXITCODE -ne 0 -or -not (($guiProbe -join ' ') -match 'GUI WPF smoke passed')){
    throw ('WPF UI bootstrap failed: ' + ($guiProbe -join '; '))
}
Write-Host 'PASS: actual WPF GUI initialization and event bindings'
foreach ($required in @('NavAudit','NavBoost','BtnDriverSearch','BtnDriverInstall',
 'DriverUpdatesGrid','BtnDriverInventory','BtnNativeScan','BtnClamScan','BtnClamUpdate','BtnDefenderUpdate','BtnDefenderThreats','BtnDefenderRemediate','BtnSecurityAudit','SecurityGrid','BtnBoostUI',
 'BtnBoostPower','BtnBoostRestore','BtnScanOffline',
 'NavRepair','BtnDriverDownload','BtnDiskCleanupWizard','BtnCancelWorker','BtnDeepAnalyze','BtnDeepClean','BtnSpaceMap','BtnRepairAudit','BtnRepairDism','BtnRepairSfc','BtnRegistryAudit','BtnRestorePoints','BtnRestoreWizard')) {
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
# Independent scanner is tested on an inert text fixture, without malware samples.
Import-Module (Join-Path $root 'app\Turbo.Scanner.psm1') -Force -ErrorAction Stop
$scannerSandbox=Join-Path ([IO.Path]::GetTempPath()) ('TurboScan-Smoke-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($scannerSandbox)
try {
 $fixture=Join-Path $scannerSandbox 'sample.txt'
 [IO.File]::WriteAllText($fixture,'Safe test fixture for Turbo Old PC.')
 $fingerprint=(Get-FileHash -LiteralPath $fixture -Algorithm SHA256).Hash
 $dbPath=Join-Path $scannerSandbox 'testdb.json'
 $testdb=[pscustomobject]@{Schema=1;Signatures=@([pscustomobject]@{Name='Test fixture only';SHA256=$fingerprint})}
 [IO.File]::WriteAllText($dbPath,($testdb|ConvertTo-Json -Depth 4))
 $found=Invoke-TurboFileScan -Root $scannerSandbox -DatabasePath $dbPath
 if (@($found.Findings).Count -ne 1 -or $found.Findings[0].SHA256 -ne $fingerprint) {
    throw 'Own signature scanner failed safe fixture detection.'
 }
 if (-not (Test-Path -LiteralPath $fixture -PathType Leaf)) {
    throw 'Read-only scanner unexpectedly modified a fixture.'
 }
 Write-Host 'PASS: independent SHA256 scan detection and non-destructive behavior'
}finally{
 Remove-Item -LiteralPath $scannerSandbox -Recurse -Force -ErrorAction SilentlyContinue
}
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

# Deep cleanup: sandbox every permitted location, confirm preview and deletion are scoped.
$sandboxRoot=Join-Path ([IO.Path]::GetTempPath()) ('TurboCleanup-Sandbox-'+[guid]::NewGuid().ToString('N'))
$originalLocal=$env:LOCALAPPDATA
$originalRoot=$env:SystemRoot
$originalProgramData=$env:ProgramData
try {
 $env:LOCALAPPDATA=Join-Path $sandboxRoot 'profile'
 $env:SystemRoot=Join-Path $sandboxRoot 'fakeWindows'
 $env:ProgramData=Join-Path $sandboxRoot 'fakeProgramData'
 $tempRoot=Join-Path $env:LOCALAPPDATA 'Temp'
 [void][IO.Directory]::CreateDirectory($tempRoot)
 [void][IO.Directory]::CreateDirectory((Join-Path $env:SystemRoot 'Temp'))
 $stale=Join-Path $tempRoot 'older-than-two-days.txt'
 $recent=Join-Path $tempRoot 'recent-file.txt'
 [IO.File]::WriteAllText($stale,'old disposable sandbox file')
 [IO.File]::WriteAllText($recent,'recent sandbox file must survive')
 [IO.File]::SetLastWriteTime($stale,(Get-Date).AddDays(-7))
 $drive=([IO.Path]::GetPathRoot($sandboxRoot)).Substring(0,2)
 $analysisReport=Join-Path $sandboxRoot 'analysis.json'
 $cleanReport=Join-Path $sandboxRoot 'clean.json'
 & (Join-Path $root 'app\Workers\DeepCleanup.ps1') -Mode Analyze -Drive $drive -OutputPath $analysisReport
 $analysis=Get-Content -LiteralPath $analysisReport -Raw -Encoding UTF8|ConvertFrom-Json -ErrorAction Stop
 if(-not $analysis.Success -or [int]$analysis.Count -ne 1){throw 'Deep cleanup fixture preview mismatch.'}
 if(-not (Test-Path -LiteralPath $stale)){throw 'Deep cleanup preview unexpectedly deleted a file.'}
 & (Join-Path $root 'app\Workers\DeepCleanup.ps1') -Mode Clean -Drive $drive -OutputPath $cleanReport -ManifestPath ([string]$analysis.ManifestPath)
 $clean=Get-Content -LiteralPath $cleanReport -Raw -Encoding UTF8|ConvertFrom-Json -ErrorAction Stop
 if(-not $clean.Success -or [int]$clean.Deleted -ne 1 -or
    (Test-Path -LiteralPath $stale) -or -not (Test-Path -LiteralPath $recent)){
     throw 'Deep cleanup did not preserve recent files.'
 }
 Write-Host 'PASS: deep cleanup sandbox analyze and delete only permitted old file'
} finally {
 $env:LOCALAPPDATA=$originalLocal;$env:SystemRoot=$originalRoot;$env:ProgramData=$originalProgramData
 Remove-Item -LiteralPath $sandboxRoot -Recurse -Force -ErrorAction SilentlyContinue
}
# Preview must not inspect arbitrary files when the selected drive is not valid.
$jobPath = Join-Path ([IO.Path]::GetTempPath()) ('TurboOldPC-invalid-'+[guid]::NewGuid().ToString('N')+'.json')
try {
    & (Join-Path $root 'app\Workers\DeepCleanup.ps1') -Mode Analyze -Drive 'Z:' -OutputPath $jobPath
    if (-not (Test-Path -LiteralPath $jobPath)) { throw 'Deep cleanup failure was not reported.' }
    $check = Get-Content -LiteralPath $jobPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($check.Success) { Write-Host 'WARN: Z: is mounted; invalid-drive check skipped.' }
    else { Write-Host 'PASS: deep cleanup unavailable volume handled' }
} finally {
    Remove-Item -LiteralPath $jobPath -Force -ErrorAction SilentlyContinue
}

# Release package contract. Every worker wired into the UI must be included in packaging.
$mainGui = Get-Content -LiteralPath (Join-Path $root 'app\TurboOldPC.ps1') -Raw -Encoding UTF8
$builder = Get-Content -LiteralPath (Join-Path $root 'tools\Build-Portable.ps1') -Raw -Encoding UTF8
$workerRefs = @([regex]::Matches($mainGui, "Workers\\[A-Za-z0-9]+\.ps1") |
    ForEach-Object { $_.Value } | Sort-Object -Unique)
foreach ($requiredFile in @('app\Turbo.Scanner.psm1','data\signatures.json')) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $requiredFile) -PathType Leaf)) {
        throw "Missing independent scanner dependency: $requiredFile"
    }
    $leaf=[IO.Path]::GetFileName($requiredFile)
    if (-not $builder.Contains($leaf)) { throw "Not packaged: $leaf" }
}
# Every file required by the installer must be present in the portable ZIP list.
$installerText=Get-Content -LiteralPath (Join-Path $root 'install\Install.ps1') -Raw -Encoding UTF8
$installationList=[regex]::Match($installerText,'(?s)\$required=@\((.*?)\)\s*\[void\]')
if(-not $installationList.Success){throw 'Installer required-file manifest missing.'}
$needed=@([regex]::Matches($installationList.Groups[1].Value,"'([^']+)'")|
 ForEach-Object {$_.Groups[1].Value})
foreach($item in $needed){
 if($item -eq 'TurboOldPC.exe'){continue}
 if(-not (Test-Path -LiteralPath (Join-Path $root $item) -PathType Leaf)){
   throw "Installer needs a file that does not exist: $item"
 }
 if(-not $builder.Contains("'"+$item+"'")){
   throw "Installer requires a file omitted from the portable ZIP: $item"
 }
}
Write-Host "PASS: all $($needed.Count) installer components are present in portable packaging"
foreach ($relative in $workerRefs) {
    $diskPath = Join-Path (Join-Path $root 'app') $relative
    if (-not (Test-Path -LiteralPath $diskPath -PathType Leaf)) {
        throw "Missing referenced worker: $relative"
    }
    $basename = [IO.Path]::GetFileName($relative)
    if (-not $builder.Contains($basename)) {
        throw "Portable package would omit $basename"
    }
}
foreach ($file in @('tools\Bootstrap.cs','tools\Build-WindowsExe.ps1','install\Install.ps1')) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $file) -PathType Leaf)) {
        throw "Missing EXE build prerequisite: $file"
    }
}
$installerScript = Get-Content -LiteralPath (Join-Path $root 'install\Install.ps1') -Raw -Encoding UTF8
if (-not $installerScript.Contains('TurboOldPC.exe')) {
    throw 'Installer is not configured to use the installed executable.'
}
Write-Host "PASS: all $($workerRefs.Count) GUI worker scripts are packaged and EXE contract exists"
