[CmdletBinding()]
param([switch]$NoDesktopShortcut)
$ErrorActionPreference = 'Stop'
$source = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$destination = Join-Path $env:LOCALAPPDATA 'Programs\TurboOldPC'
$destNorm = [IO.Path]::GetFullPath($destination).TrimEnd('\')
$sourceNorm = $source.TrimEnd('\')
if ($sourceNorm.Equals($destNorm, [StringComparison]::OrdinalIgnoreCase)) {
    Write-Host 'Program is already in the install directory.' -ForegroundColor Yellow
    exit 0
}
if (-not (Test-Path -LiteralPath (Join-Path $source 'Start.cmd') -PathType Leaf) -or
    -not (Test-Path -LiteralPath (Join-Path $source 'app\TurboOldPC.ps1') -PathType Leaf) -or
    -not (Test-Path -LiteralPath (Join-Path $source 'TurboOldPC.exe') -PathType Leaf) -or
    -not (Test-Path -LiteralPath (Join-Path $source 'app\Turbo.Core.psm1') -PathType Leaf)) {
    throw 'The installation package is incomplete. Extract the full ZIP before installation.'
}
$processes = @(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -and $_.CommandLine.Contains((Join-Path $destination 'app\TurboOldPC.ps1')) })
if ($processes.Count -gt 0) { throw 'Close Turbo Old PC before updating the installation.' }
[void][IO.Directory]::CreateDirectory($destination)
[void][IO.Directory]::CreateDirectory((Join-Path $destination 'app'))
[void][IO.Directory]::CreateDirectory((Join-Path $destination 'install'))
[void][IO.Directory]::CreateDirectory((Join-Path $destination 'app\Workers'))
[void][IO.Directory]::CreateDirectory((Join-Path $destination 'assets'))
foreach ($item in @('Start.cmd','Turbo Old PC.vbs','TurboOldPC.exe','README.md','AUDIT.md','LICENSE')) {
    $from = Join-Path $source $item
    if (Test-Path -LiteralPath $from -PathType Leaf) {
        Copy-Item -LiteralPath $from -Destination (Join-Path $destination $item) -Force -ErrorAction Stop
    }
}
foreach ($folder in @('app','app\Workers','install','assets')) {
    $original = Join-Path $source $folder
    $target = Join-Path $destination $folder
    foreach ($entry in @(Get-ChildItem -LiteralPath $original -File -ErrorAction Stop)) {
        Copy-Item -LiteralPath $entry.FullName -Destination (Join-Path $target $entry.Name) -Force -ErrorAction Stop
    }
}
$desktop = [Environment]::GetFolderPath('Desktop')
$programs = [Environment]::GetFolderPath('Programs')
if (-not [string]::IsNullOrWhiteSpace($programs)) {
    $startMenu = Join-Path $programs 'Turbo Old PC'
    [void][IO.Directory]::CreateDirectory($startMenu)
}
$shell = New-Object -ComObject WScript.Shell
function New-TurboShortcut {
    param([string]$ShortcutPath,[string]$TargetDir)
    $link = $shell.CreateShortcut($ShortcutPath)
    $link.TargetPath = Join-Path $TargetDir 'TurboOldPC.exe'
    $link.WorkingDirectory = $TargetDir
    $link.Description = 'Turbo Old PC — бесплатная диагностика, очистка и защита Windows'
    $link.IconLocation = Join-Path $TargetDir 'assets\TurboOldPC.ico'
    $link.Save()
}
if ($startMenu) { New-TurboShortcut -ShortcutPath (Join-Path $startMenu 'Turbo Old PC.lnk') -TargetDir $destination }
if (-not $NoDesktopShortcut -and -not [string]::IsNullOrWhiteSpace($desktop)) {
    New-TurboShortcut -ShortcutPath (Join-Path $desktop 'Turbo Old PC.lnk') -TargetDir $destination
}
$regPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\TurboOldPC'
[void](New-Item -Path $regPath -Force)
$uninstaller = Join-Path $destination 'install\Uninstall.ps1'
$uninstallCommand = '"' + (Join-Path $PSHOME 'powershell.exe') + '" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "' + $uninstaller + '"'
New-ItemProperty -Path $regPath -Name DisplayName -Value 'Turbo Old PC' -PropertyType String -Force | Out-Null
New-ItemProperty -Path $regPath -Name DisplayVersion -Value '0.4.0' -PropertyType String -Force | Out-Null
New-ItemProperty -Path $regPath -Name Publisher -Value 'Turbo Old PC Community' -PropertyType String -Force | Out-Null
New-ItemProperty -Path $regPath -Name InstallLocation -Value $destination -PropertyType String -Force | Out-Null
New-ItemProperty -Path $regPath -Name UninstallString -Value $uninstallCommand -PropertyType String -Force | Out-Null
New-ItemProperty -Path $regPath -Name NoModify -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $regPath -Name NoRepair -Value 1 -PropertyType DWord -Force | Out-Null
Write-Host 'Turbo Old PC installed successfully.' -ForegroundColor Green
Write-Host "Location: $destination"
Write-Host 'Open Turbo Old PC from the Start menu or desktop.'
Write-Host 'This is a per-user installation without administrator privileges or bundled software.'
