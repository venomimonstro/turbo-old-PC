[CmdletBinding()]
param([switch]$KeepData = $true)
$ErrorActionPreference = 'Stop'
# Only uninstall the standard per-user location. Reports and rollback history are retained.
$programs=Join-Path $env:LOCALAPPDATA 'Programs'
$destination=[IO.Path]::GetFullPath((Join-Path $programs 'TurboOldPC')).TrimEnd('\')
function Assert-OrdinaryFolder([string]$p) {
 if(Test-Path -LiteralPath $p) {
  $item=Get-Item -LiteralPath $p -Force -ErrorAction Stop
  if(-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)){
   throw "Unsafe uninstall path (redirection/reparse point): $p"
  }
 }
}
Assert-OrdinaryFolder $env:LOCALAPPDATA
Assert-OrdinaryFolder $programs
Assert-OrdinaryFolder $destination
if(Test-Path -LiteralPath $destination -PathType Container){
 # Never let a recursive deletion traverse a directory junction created after installation.
 $stack=New-Object System.Collections.Stack;$stack.Push($destination);$count=0
 while($stack.Count -gt 0){
  $folder=[string]$stack.Pop()
  foreach($entry in @(Get-ChildItem -LiteralPath $folder -Force -ErrorAction Stop)){
   $count++
   if($count -gt 20000){throw 'Too many entries: uninstall stopped for safety.'}
   if(($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){
    throw "Unsafe symlink/junction in installation: $($entry.FullName)"
   }
   if($entry.PSIsContainer){$stack.Push($entry.FullName)}
  }
 }
 $active=@(Get-CimInstance Win32_Process -Filter "Name='powershell.exe' OR Name='TurboOldPC.exe'" -ErrorAction SilentlyContinue |
  Where-Object{ $_.CommandLine -and ($_.CommandLine.Contains((Join-Path $destination 'app\TurboOldPC.ps1')) -or
     ($_.ExecutablePath -and $_.ExecutablePath.Equals((Join-Path $destination 'TurboOldPC.exe'),[StringComparison]::OrdinalIgnoreCase)))})
 if($active.Count -gt 0){throw 'Close all Turbo Old PC windows before uninstalling.'}
 Set-Location -LiteralPath $env:TEMP
 Remove-Item -LiteralPath $destination -Recurse -Force -ErrorAction Stop
}
function Remove-OwnedShortcut([string]$path){
 if(-not $path -or -not (Test-Path -LiteralPath $path -PathType Leaf)){return}
 try {
  $shell=New-Object -ComObject WScript.Shell
  $shortcut=$shell.CreateShortcut($path)
  $target=[IO.Path]::GetFullPath([string]$shortcut.TargetPath)
  $expected=Join-Path $destination 'TurboOldPC.exe'
  if($target.Equals($expected,[StringComparison]::OrdinalIgnoreCase)){
   Remove-Item -LiteralPath $path -Force -ErrorAction Stop
  }
 }catch{Write-Warning "Could not remove shortcut $path : $($_.Exception.Message)"}
}
$desktop=[Environment]::GetFolderPath('Desktop')
if($desktop){Remove-OwnedShortcut (Join-Path $desktop 'Turbo Old PC.lnk')}
$menu=[Environment]::GetFolderPath('Programs')
if($menu){
 $folder=Join-Path $menu 'Turbo Old PC'
 Remove-OwnedShortcut (Join-Path $folder 'Turbo Old PC.lnk')
 if(Test-Path -LiteralPath $folder -PathType Container){
  if(@(Get-ChildItem -LiteralPath $folder -Force -ErrorAction SilentlyContinue).Count -eq 0){
   Remove-Item -LiteralPath $folder -Force -ErrorAction SilentlyContinue
  }
 }
}
$reg='HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\TurboOldPC'
if(Test-Path -LiteralPath $reg){
 $current=Get-ItemProperty -LiteralPath $reg -Name InstallLocation -ErrorAction SilentlyContinue
 if($current -and [string]$current.InstallLocation -and
    ([IO.Path]::GetFullPath([string]$current.InstallLocation).TrimEnd('\')).Equals($destination,[StringComparison]::OrdinalIgnoreCase)){
  Remove-Item -LiteralPath $reg -Recurse -Force -ErrorAction Stop
 }
}
Write-Host 'Turbo Old PC removed. User reports, quarantine metadata and restore history remain in LocalAppData\TurboOldPC.' -ForegroundColor Green
