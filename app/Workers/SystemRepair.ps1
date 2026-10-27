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
 if($Mode -ne 'Audit'){
  try{
   $previous=@(Get-ComputerRestorePoint -ErrorAction Stop|Sort-Object SequenceNumber -Descending|Select-Object -First 1)
   $previousSeq=if($previous.Count -gt 0){[int64]$previous[0].SequenceNumber}else{[int64]-1}
   Checkpoint-Computer -Description ('TurboOldPC pre-repair '+$Mode) -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
   $current=@(Get-ComputerRestorePoint -ErrorAction Stop|Sort-Object SequenceNumber -Descending|Select-Object -First 1)
   if($current.Count -eq 0 -or [int64]$current[0].SequenceNumber -le $previousSeq){
    throw 'Не подтверждено создание новой точки восстановления.'
   }
  }catch{
   throw 'Восстановление отменено: невозможно создать и подтвердить новую точку восстановления Windows. Причина: '+$_.Exception.Message
  }
 }
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
