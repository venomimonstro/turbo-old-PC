[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][ValidateSet('Audit','DISM','SFC')][string]$Mode,
 [Parameter(Mandatory=$true)][string]$OutputPath
)
$ErrorActionPreference='Stop'
try{
 $identity=[Security.Principal.WindowsIdentity]::GetCurrent()
 $principal=New-Object Security.Principal.WindowsPrincipal($identity)
 if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Для обслуживания Windows необходимы права администратора.'}
 $logDir=Join-Path $env:LOCALAPPDATA 'TurboOldPC\RepairLogs'
 [void][IO.Directory]::CreateDirectory($logDir)
 $logPath=Join-Path $logDir ('repair-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.txt')
 switch($Mode){
  'Audit' {$command='DISM.exe';$arguments=@('/Online','/Cleanup-Image','/ScanHealth')}
  'DISM' {$command='DISM.exe';$arguments=@('/Online','/Cleanup-Image','/RestoreHealth')}
  'SFC' {$command='sfc.exe';$arguments=@('/scannow')}
 }
 $output=@(& $command @arguments 2>&1|ForEach-Object{[string]$_})
 $exitCode=$LASTEXITCODE
 $output|Set-Content -LiteralPath $logPath -Encoding UTF8
 $result=[pscustomobject]@{
   Success=($exitCode -eq 0);Mode=$Mode;ExitCode=$exitCode;LogPath=$logPath
   Message="Проверка завершена, код $exitCode. Подробный журнал: $logPath. DISM и SFC могут потребовать перезагрузку."
 }
}catch{$result=[pscustomobject]@{Success=$false;Mode=$Mode;Message=$_.Exception.Message}}
try{$result|ConvertTo-Json -Depth 4|Set-Content -LiteralPath $OutputPath -Encoding UTF8 -ErrorAction Stop}catch{exit 2}
if(-not $result.Success){exit 1}
