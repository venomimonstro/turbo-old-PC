[CmdletBinding()]
param([ValidatePattern('^\d+\.\d+\.\d+$')][string]$Version = '0.4.0')
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$dist = Join-Path $root 'dist'
$build = Join-Path ([IO.Path]::GetTempPath()) ('TurboBuild-' + [guid]::NewGuid().ToString('N'))
$src = Join-Path $root 'tools\Bootstrap.cs'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe'
if (-not [Environment]::OSVersion.Platform.ToString().StartsWith('Win')) {
    throw 'Windows is required to compile EXE executables.'
}
if (-not (Test-Path -LiteralPath $compiler)) { throw "Built-in .NET Framework compiler not available: $compiler" }
if (-not (Test-Path -LiteralPath $src -PathType Leaf)) { throw 'Bootstrap source missing.' }
[void][IO.Directory]::CreateDirectory($dist)
[void][IO.Directory]::CreateDirectory($build)
try {
    # Compile the regular installed-app executable before packaging.
    $appExe = Join-Path $dist 'TurboOldPC.exe'
    $commonArgs = @('/nologo','/target:winexe','/platform:anycpu','/optimize+',
        '/define:INSTALLED','/reference:System.Windows.Forms.dll',
        '/reference:System.IO.Compression.dll','/reference:System.IO.Compression.FileSystem.dll',
        ('/out:' + $appExe),$src)
    & $compiler @commonArgs
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $appExe)) {
        throw 'Could not compile installed TurboOldPC.exe.'
    }
    $smoke = Join-Path $root 'tests\SmokeTest.ps1'
    & (Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe') -NoProfile -ExecutionPolicy Bypass -File $smoke
    if ($LASTEXITCODE -ne 0) { throw 'Smoke tests failed; EXE packaging cancelled.' }
    $package = Join-Path $dist "TurboOldPC-$Version-portable.zip"
    & (Join-Path $root 'tools\Build-Portable.ps1') -Version $Version -LauncherPath $appExe
    if (-not (Test-Path -LiteralPath $package)) { throw 'ZIP build failed.' }
    # Fresh payload from the same source tree for installer AND portable EXEs.
    $references = @(
        '/reference:System.Windows.Forms.dll',
        '/reference:System.IO.Compression.dll',
        '/reference:System.IO.Compression.FileSystem.dll'
    )
    $results = @(
        [pscustomobject]@{Name="TurboOldPC-$Version-Portable.exe";Flags=@()},
        [pscustomobject]@{Name="TurboOldPC-$Version-Setup.exe";Flags=@('/define:INSTALLER')}
    )
    foreach ($target in $results) {
        $exe = Join-Path $dist $target.Name
        if (Test-Path -LiteralPath $exe) { Remove-Item -LiteralPath $exe -Force }
        $args = @('/nologo','/target:winexe','/platform:anycpu','/optimize+')
        $args += $references
        $args += $target.Flags
        $args += '/out:' + $exe
        $args += '/resource:' + $package + ',turbo_payload.zip'
        $args += $src
        & $compiler @args
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $exe)) {
            throw "Compiler failed for $($target.Name)."
        }
        Write-Host "BUILT: $exe" -ForegroundColor Green
        $hash = Get-FileHash -LiteralPath $exe -Algorithm SHA256
        Write-Host "SHA256: $($hash.Hash)"
    }
    & (Join-Path $root 'tests\ReleaseGate.ps1') -Version $Version
    if ($LASTEXITCODE -ne 0) { throw 'Release validation failed.' }
    Write-Host 'Release files are not code-signed. Test on Win10 and Win11 before public release.' -ForegroundColor Yellow
} finally {
    if (Test-Path -LiteralPath $build) { Remove-Item -LiteralPath $build -Recurse -Force -ErrorAction SilentlyContinue }
}
