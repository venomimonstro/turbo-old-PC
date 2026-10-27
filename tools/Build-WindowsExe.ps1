[CmdletBinding()]
param(
 [ValidatePattern('^\d+\.\d+\.\d+$')][string]$Version = '0.4.0',
 [switch]$Release,
 [string]$CertificateThumbprint = '',
 [string]$TimestampServer = ''
)
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
$signingCertificate=$null
if($Release){
 if($CertificateThumbprint -notmatch '^[A-Fa-f0-9]{40}$' -or -not $TimestampServer.StartsWith('https://')){
    throw 'Production release requires a certificate SHA-1 thumbprint and HTTPS timestamp server.'
 }
 $candidates=@(Get-ChildItem Cert:\CurrentUser\My,Cert:\LocalMachine\My -ErrorAction Stop |
    Where-Object { $_.Thumbprint -eq $CertificateThumbprint -and $_.HasPrivateKey -and
      $_.NotBefore -le (Get-Date) -and $_.NotAfter -gt (Get-Date) } | Select-Object -First 1)
 if($candidates.Count -ne 1){throw 'Valid code-signing certificate with private key not found.'}
 $signingCertificate=$candidates[0]
}
function Sign-TurboReleaseFile([string]$file){
 if(-not $Release){return}
 $signed=Set-AuthenticodeSignature -FilePath $file -Certificate $signingCertificate -HashAlgorithm SHA256 -TimestampServer $TimestampServer -ErrorAction Stop
 if($signed.Status -ne 'Valid'){
    throw "Code signature invalid for $file : $($signed.Status) ($($signed.StatusMessage))"
 }
}
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
    Sign-TurboReleaseFile $appExe
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
        Sign-TurboReleaseFile $exe
        Write-Host "BUILT: $exe" -ForegroundColor Green
        $hash = Get-FileHash -LiteralPath $exe -Algorithm SHA256
        Write-Host "SHA256: $($hash.Hash)"
    }
    & (Join-Path $root 'tests\ReleaseGate.ps1') -Version $Version -RequireSignature:$Release
    if ($LASTEXITCODE -ne 0) { throw 'Release validation failed.' }
    if($Release){
       Write-Host 'SIGNED package generated. Windows 10/11 integration tests are still mandatory.' -ForegroundColor Green
    } else {
       Write-Host 'PREVIEW: unsigned. Never distribute as an official production release.' -ForegroundColor Yellow
    }
} finally {
    if (Test-Path -LiteralPath $build) { Remove-Item -LiteralPath $build -Recurse -Force -ErrorAction SilentlyContinue }
}
