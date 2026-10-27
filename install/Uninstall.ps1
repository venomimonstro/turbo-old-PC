[CmdletBinding()]
param([switch]$KeepData = $true)
$ErrorActionPreference = 'Stop'
$destination = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'Programs\TurboOldPC')).TrimEnd('\')
$allowed = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'Programs\TurboOldPC')).TrimEnd('\')
if (-not $destination.Equals($allowed,[StringComparison]::OrdinalIgnoreCase)) {
    throw 'Invalid uninstall location.'
}
Write-Host 'Uninstalling Turbo Old PC...' -ForegroundColor Cyan
$desktop = [Environment]::GetFolderPath('Desktop')
$programs = [Environment]::GetFolderPath('Programs')
if (-not [string]::IsNullOrWhiteSpace($desktop)) {
    $link = Join-Path $desktop 'Turbo Old PC.lnk'
    if (Test-Path -LiteralPath $link) { Remove-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue }
}
if (-not [string]::IsNullOrWhiteSpace($programs)) {
    $menu = Join-Path $programs 'Turbo Old PC'
    if (Test-Path -LiteralPath $menu) { Remove-Item -LiteralPath $menu -Recurse -Force -ErrorAction SilentlyContinue }
}
$regPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\TurboOldPC'
if (Test-Path -LiteralPath $regPath) { Remove-Item -LiteralPath $regPath -Recurse -Force -ErrorAction SilentlyContinue }
Set-Location -LiteralPath $env:TEMP
if (Test-Path -LiteralPath $destination -PathType Container) {
    Remove-Item -LiteralPath $destination -Recurse -Force -ErrorAction Stop
}
Write-Host 'Turbo Old PC uninstalled. Reports in LocalAppData\TurboOldPC are kept.' -ForegroundColor Green
