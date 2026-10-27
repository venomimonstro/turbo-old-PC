[CmdletBinding()]
param([Parameter(Mandatory=$true)][ValidateSet('Status','Scan')][string]$Mode,
[Parameter(Mandatory=$true)][string]$OutputPath,[string]$ScanRoot)
$ErrorActionPreference='Stop'
try {
 $options=@(
  (Join-Path $env:ProgramFiles 'ClamAV\clamscan.exe'),
  (Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) 'ClamAV\clamscan.exe')
 )
 $available=@($options|Where-Object{$_ -and (Test-Path -LiteralPath $_ -PathType Leaf)})
 if($available.Count -eq 0){
  $cmd=Get-Command clamscan.exe -ErrorAction SilentlyContinue
  if($cmd){$available=@($cmd.Source)}
 }
 if($available.Count -eq 0){throw 'ClamAV не установлен. Скачайте официальный Windows-дистрибутив на clamav.net/download, настройте freshclam.conf и обновите сигнатуры.'}
 $bin=[string]$available[0]
 if($Mode -eq 'Status'){
   $lines=@(& $bin '--version' 2>&1|ForEach-Object{[string]$_})
   $code=$LASTEXITCODE
   if($code -ne 0){throw 'ClamAV не отвечает: '+($lines-join '; ')}
   $result=[pscustomobject]@{Success=$true;Mode=$Mode;Message='Найден ClamAV: '+($lines-join ' ')}
 }else{
   if(-not $ScanRoot -or -not (Test-Path -LiteralPath $ScanRoot -PathType Container)){throw 'Папка для проверки не существует.'}
   $root=[IO.Path]::GetFullPath($ScanRoot)
   if(((Get-Item -LiteralPath $root -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'Каталог-ссылка не допускается.'}
   $logDir=Join-Path $env:LOCALAPPDATA 'TurboOldPC\ScanLogs'
   [void][IO.Directory]::CreateDirectory($logDir)
   $log=Join-Path $logDir ('clamav-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.txt')
   # Never use --remove or --move; on-demand mode is read-only.
   $lines=@(& $bin '--recursive' '--infected' '--no-summary' '--max-filesize=64M' '--max-scansize=256M' '--' $root 2>&1|ForEach-Object{[string]$_})
   $code=$LASTEXITCODE
   $lines|Set-Content -LiteralPath $log -Encoding UTF8
   if($code -notin @(0,1)){throw "ClamAV завершился с ошибкой $code. Журнал: $log"}
   $result=[pscustomobject]@{
    Success=$true;Mode=$Mode;DetectionFound=($code -eq 1);LogPath=$log
    Message="ClamAV: обнаружения $($code -eq 1). Журнал: $log. Отсутствие обнаружений не гарантирует отсутствие угроз; не удаляйте файлы без анализа."
   }
 }
}catch{$result=[pscustomobject]@{Success=$false;Mode=$Mode;Message=$_.Exception.Message}}
try{$result|ConvertTo-Json -Depth 5|Set-Content -LiteralPath $OutputPath -Encoding UTF8 -ErrorAction Stop}catch{exit 2}
if(-not $result.Success){exit 1}
