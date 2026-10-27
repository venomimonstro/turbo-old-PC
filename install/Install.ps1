[CmdletBinding()]
param([switch]$NoDesktopShortcut)
$ErrorActionPreference = 'Stop'
# Per-user transactional install: no admin requirement; never overwrite a live install in place.
$source = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd('\')
$programsRoot = Join-Path $env:LOCALAPPDATA 'Programs'
$destination = [IO.Path]::GetFullPath((Join-Path $programsRoot 'TurboOldPC')).TrimEnd('\')
$stage = Join-Path $programsRoot ('TurboOldPC-stage-' + [guid]::NewGuid().ToString('N'))
$backup = Join-Path $programsRoot ('TurboOldPC-backup-' + [guid]::NewGuid().ToString('N'))
$regPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\TurboOldPC'
$hadPrevious = $false
$activated = $false
$startMenu = ''
$shortcutDesktop = ''
function Assert-OrdinaryDirectory([string]$path) {
 if(Test-Path -LiteralPath $path) {
  $item=Get-Item -LiteralPath $path -Force -ErrorAction Stop
  if(-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
   throw "Unsafe or redirected directory: $path"
  }
 }
}
function Copy-Required([string]$relative) {
 $from=Join-Path $source $relative
 $to=Join-Path $stage $relative
 $inputFile=Get-Item -LiteralPath $from -Force -ErrorAction Stop
 if($inputFile.PSIsContainer -or ($inputFile.Attributes -band [IO.FileAttributes]::ReparsePoint)){
  throw "Invalid package file: $relative"
 }
 [void][IO.Directory]::CreateDirectory((Split-Path -Parent $to))
 Copy-Item -LiteralPath $inputFile.FullName -Destination $to -ErrorAction Stop
}
if($source.Equals($destination,[StringComparison]::OrdinalIgnoreCase)){
 Write-Host 'Already running from the installed directory; no update performed.'
 exit 0
}
if(-not (Test-Path -LiteralPath $env:LOCALAPPDATA -PathType Container)){throw 'LocalAppData unavailable.'}
Assert-OrdinaryDirectory $programsRoot
Assert-OrdinaryDirectory $destination
$running=@(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
 Where-Object { $_.CommandLine -and $_.CommandLine.Contains((Join-Path $destination 'app\TurboOldPC.ps1')) })
if($running.Count){throw 'Close Turbo Old PC before reinstalling or updating.'}
$required=@(
 'TurboOldPC.exe','Start.cmd','Turbo Old PC.vbs','README.md','AUDIT.md','LICENSE',
 'app\TurboOldPC.ps1','app\Turbo.Core.psm1','app\Turbo.Security.psm1',
 'app\Turbo.Scanner.psm1','data\signatures.json','assets\TurboOldPC.ico',
 'install\Install.ps1','install\Uninstall.ps1',
 'app\Workers\Diagnostics.ps1','app\Workers\Cleanup.ps1',
 'app\Workers\DefenderScan.ps1','app\Workers\DeepCleanup.ps1',
 'app\Workers\SystemRepair.ps1','app\Workers\RegistryAudit.ps1',
 'app\Workers\SpaceMap.ps1','app\Workers\DriverUpdates.ps1',
 'app\Workers\DriverInventory.ps1','app\Workers\ThreatCenter.ps1',
 'app\Workers\NativeScan.ps1','app\Workers\ClamAvScan.ps1',
 'app\Workers\Boost.ps1','app\Workers\SecurityAudit.ps1',
 'app\Workers\RestorePoints.ps1'
)
[void][IO.Directory]::CreateDirectory($programsRoot)
[void][IO.Directory]::CreateDirectory($stage)
try {
 foreach($relative in $required){Copy-Required $relative}
 # Reject packaging of scripts that cannot be parsed by PowerShell 5.1.
 foreach($relative in @($required|Where-Object{$_ -like '*.ps1' -or $_ -like '*.psm1'})){
  $tokens=$null;$errors=$null
  [void][Management.Automation.Language.Parser]::ParseFile(
   (Join-Path $stage $relative),[ref]$tokens,[ref]$errors)
  if(@($errors).Count){throw "Broken PowerShell file: $relative : $($errors[0].Message)"}
 }
 $db=Get-Content -LiteralPath (Join-Path $stage 'data\signatures.json') -Raw -Encoding UTF8|ConvertFrom-Json
 if([int]$db.Schema -ne 1){throw 'Invalid scan signature database.'}
 if(Test-Path -LiteralPath $destination -PathType Container){
  Move-Item -LiteralPath $destination -Destination $backup -ErrorAction Stop
  $hadPrevious=$true
 }
 Move-Item -LiteralPath $stage -Destination $destination -ErrorAction Stop
 $activated=$true
 $menuFolder=[Environment]::GetFolderPath('Programs')
 if($menuFolder){
  $startMenu=Join-Path $menuFolder 'Turbo Old PC'
  [void][IO.Directory]::CreateDirectory($startMenu)
 }
 $desktop=[Environment]::GetFolderPath('Desktop')
 if($desktop -and -not $NoDesktopShortcut){$shortcutDesktop=Join-Path $desktop 'Turbo Old PC.lnk'}
 $shell=New-Object -ComObject WScript.Shell
 function New-TurboShortcut([string]$path){
  $shortcut=$shell.CreateShortcut($path)
  $shortcut.TargetPath=Join-Path $destination 'TurboOldPC.exe'
  $shortcut.WorkingDirectory=$destination
  $shortcut.Description='Turbo Old PC — диагностика, очистка и защита Windows'
  $shortcut.IconLocation=Join-Path $destination 'assets\TurboOldPC.ico'
  $shortcut.Save()
 }
 if($startMenu){New-TurboShortcut (Join-Path $startMenu 'Turbo Old PC.lnk')}
 if($shortcutDesktop){New-TurboShortcut $shortcutDesktop}
 [void](New-Item -Path $regPath -Force -ErrorAction Stop)
 $uninstaller=Join-Path $destination 'install\Uninstall.ps1'
 $uninstallCommand='"'+(Join-Path $PSHOME 'powershell.exe')+'" -NoProfile -ExecutionPolicy Bypass -File "'+$uninstaller+'"'
 $props=@{
  DisplayName='Turbo Old PC';DisplayVersion='0.4.0'
  Publisher='Turbo Old PC Community';InstallLocation=$destination
  UninstallString=$uninstallCommand
 }
 foreach($name in $props.Keys){
  New-ItemProperty -Path $regPath -Name $name -Value $props[$name] -PropertyType String -Force -ErrorAction Stop|Out-Null
 }
 foreach($name in @('NoModify','NoRepair')){
  New-ItemProperty -Path $regPath -Name $name -Value 1 -PropertyType DWord -Force -ErrorAction Stop|Out-Null
 }
 if($hadPrevious -and (Test-Path -LiteralPath $backup)){
  Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction Stop
 }
 Write-Host "Installed successfully: $destination"
} catch {
 $errorMessage=$_.Exception.Message
 if($activated -and (Test-Path -LiteralPath $destination)){
  try{Remove-Item -LiteralPath $destination -Force -Recurse -ErrorAction Stop}
  catch{$errorMessage+='; failed to remove partial installation: '+$_.Exception.Message}
 }
 if($hadPrevious -and (Test-Path -LiteralPath $backup)){
  try{Move-Item -LiteralPath $backup -Destination $destination -ErrorAction Stop}
  catch{$errorMessage+='; previous version recovery failed: '+$_.Exception.Message}
 }else{
  if($startMenu -and (Test-Path -LiteralPath $startMenu)){
   Remove-Item -LiteralPath (Join-Path $startMenu 'Turbo Old PC.lnk') -Force -ErrorAction SilentlyContinue
  }
  if($shortcutDesktop){Remove-Item -LiteralPath $shortcutDesktop -Force -ErrorAction SilentlyContinue}
  Remove-Item -LiteralPath $regPath -Recurse -Force -ErrorAction SilentlyContinue
 }
 throw $errorMessage
} finally {
 if(Test-Path -LiteralPath $stage){Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue}
}
