[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidatePattern('^\d+\.\d+\.\d+$')][string]$Version,
    [switch]$RequireSignature
)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$dist = Join-Path $root 'dist'
$artifacts = @(
    (Join-Path $dist 'TurboOldPC.exe'),
    (Join-Path $dist "TurboOldPC-$Version-Portable.exe"),
    (Join-Path $dist "TurboOldPC-$Version-Setup.exe"),
    (Join-Path $dist "TurboOldPC-$Version-portable.zip")
)
$report = [ordered]@{
    Version=$Version
    GeneratedAt=(Get-Date).ToString('o')
    Tests=@()
    Files=@()
    Pass=$false
}
try {
    $smoke = Join-Path $root 'tests\SmokeTest.ps1'
    & (Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe') -NoProfile -File $smoke
    if ($LASTEXITCODE -ne 0) { throw 'Smoke tests failed.' }
    $report.Tests += 'Windows PowerShell smoke: PASS'
    foreach ($artifact in $artifacts) {
        if (-not (Test-Path -LiteralPath $artifact -PathType Leaf)) { throw "Missing artifact: $artifact" }
        $file=Get-Item -LiteralPath $artifact -ErrorAction Stop
        if ($file.Length -lt 1024) { throw "Suspiciously small artifact: $artifact" }
        $stream=[IO.File]::OpenRead($file.FullName)
        try {
            $a=$stream.ReadByte(); $b=$stream.ReadByte()
            $expected=if($file.Extension -eq '.exe'){'MZ'}else{'PK'}
            if ([string]([char]$a)+[string]([char]$b) -ne $expected) {
                throw "Not a valid $expected-header file: $artifact"
            }
        }finally{$stream.Dispose()}
        $hash=Get-FileHash -LiteralPath $artifact -Algorithm SHA256
        $signature='NotApplicable'
        if($file.Extension -eq '.exe'){
            $auth=Get-AuthenticodeSignature -LiteralPath $artifact -ErrorAction Stop
            $signature=[string]$auth.Status
            if($RequireSignature -and $auth.Status -ne 'Valid'){
                throw "Unsigned or invalidly signed artifact: $artifact ($signature)"
            }
        }
        $report.Files += [ordered]@{Name=$file.Name;Bytes=$file.Length;SHA256=$hash.Hash;Signature=$signature}
    }
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip=[IO.Compression.ZipFile]::OpenRead($artifacts[3])
    try {
        $names=@($zip.Entries | ForEach-Object {$_.FullName.Replace('\','/')})
        foreach($necessary in @('TurboOldPC.exe','app/TurboOldPC.ps1','app/Turbo.Core.psm1',
            'app/Workers/ThreatCenter.ps1','app/Workers/DriverUpdates.ps1',
            'app/Workers/DeepCleanup.ps1','app/Workers/Boost.ps1',
            'install/Install.ps1','install/Uninstall.ps1')){
            if($necessary -notin $names){throw "Incomplete embedded installer payload: $necessary"}
        }
        # Verify archive entries really match the reviewed source files, not stale builds.
        $checkFiles=@(
           'app\TurboOldPC.ps1','app\Turbo.Core.psm1','app\Turbo.Scanner.psm1',
           'app\Workers\NativeScan.ps1','app\Workers\DeepCleanup.ps1',
           'app\Workers\DriverUpdates.ps1','app\Workers\ThreatCenter.ps1',
           'data\signatures.json','install\Install.ps1','install\Uninstall.ps1',
           'TurboOldPC.exe'
        )
        foreach($relative in $checkFiles){
           $archiveEntry=$zip.GetEntry($relative.Replace('\','/'))
           if($null -eq $archiveEntry){throw "Missing archive entry: $relative"}
           $source=if($relative -eq 'TurboOldPC.exe'){$artifacts[0]}else{Join-Path $root $relative}
           $expected=(Get-FileHash -LiteralPath $source -Algorithm SHA256 -ErrorAction Stop).Hash
           $sha=[Security.Cryptography.SHA256]::Create()
           $stream=$archiveEntry.Open()
           try{
             $actual=([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-','')
           }finally{$stream.Dispose();$sha.Dispose()}
           if($actual -ne $expected){throw "Archive content changed or stale: $relative"}
        }
    }finally{$zip.Dispose()}
    $report.Tests+='Package content and source hashes: PASS'
    $report.Pass=$true
} catch {
    $report.Tests+=('FAILED: '+$_.Exception.Message)
    throw
} finally {
    $path=Join-Path $dist "TurboOldPC-$Version-release-validation.json"
    $report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $path -Encoding UTF8
    Write-Host "Release validation report: $path"
    if($report.Pass){Write-Host 'PASS: local release artifact validation' -ForegroundColor Green}
}
