[CmdletBinding()]
param([string]$Version = '0.4.0', [string]$LauncherPath = '')
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$dist = Join-Path $root 'dist'
$destination = Join-Path $dist ("TurboOldPC-" + $Version + "-portable.zip")
$staging = Join-Path ([IO.Path]::GetTempPath()) ('TurboOldPC-package-' + [guid]::NewGuid().ToString('N'))
$files = @(
    'Start.cmd', 'Install.cmd', 'Turbo Old PC.vbs', 'README.md', 'AUDIT.md', 'LICENSE',
    'app\TurboOldPC.ps1', 'app\Turbo.Core.psm1',
    'app\Workers\Diagnostics.ps1', 'app\Workers\DefenderScan.ps1',
    'app\Workers\Cleanup.ps1', 'app\Workers\DriverUpdates.ps1',
    'app\Workers\SecurityAudit.ps1', 'app\Workers\Boost.ps1',
    'app\Workers\DeepCleanup.ps1', 'app\Workers\SystemRepair.ps1',
    'app\Workers\RegistryAudit.ps1', 'app\Workers\SpaceMap.ps1',
    'app\Workers\ThreatCenter.ps1', 'app\Workers\DriverInventory.ps1',
    'app\Workers\RestorePoints.ps1', 'app\Workers\NativeScan.ps1',
    'app\Turbo.Scanner.psm1', 'data\signatures.json',
    'app\Turbo.Security.psm1', 'install\Install.ps1', 'install\Uninstall.ps1',
    'tests\SmokeTest.ps1', 'assets\TurboOldPC.ico'
)
[void][IO.Directory]::CreateDirectory($dist)
[void][IO.Directory]::CreateDirectory($staging)
try {
    foreach ($relative in $files) {
        $source = Join-Path $root $relative
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
            throw "Missing package file: $relative"
        }
        $target = Join-Path $staging $relative
        $parent = Split-Path -Parent $target
        [void][IO.Directory]::CreateDirectory($parent)
        Copy-Item -LiteralPath $source -Destination $target -Force -ErrorAction Stop
    }
    if ($LauncherPath) {
        if (-not (Test-Path -LiteralPath $LauncherPath -PathType Leaf)) { throw 'Compiled application launcher missing.' }
        Copy-Item -LiteralPath $LauncherPath -Destination (Join-Path $staging 'TurboOldPC.exe') -Force -ErrorAction Stop
    }
    if (Test-Path -LiteralPath $destination) { Remove-Item -LiteralPath $destination -Force }
    Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $destination -CompressionLevel Optimal -Force
    Write-Host "Portable package created: $destination"
    $checksum = Get-FileHash -LiteralPath $destination -Algorithm SHA256
    Write-Host "SHA256: $($checksum.Hash)"
} finally {
    if (Test-Path -LiteralPath $staging) {
        Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
    }
}
