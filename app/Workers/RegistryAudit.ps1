param([Parameter(Mandatory=$true)][string]$OutputPath)
$ErrorActionPreference='Stop'
try{
 $rows=New-Object 'System.Collections.Generic.List[object]'
 $keys=@(
 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run',
 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'
 )
 foreach($key in $keys){
  if(-not (Test-Path -LiteralPath $key)){continue}
  $reg=Get-Item -LiteralPath $key -ErrorAction SilentlyContinue
  if($null -eq $reg){continue}
  foreach($name in @($reg.GetValueNames())){
   $command=[string]$reg.GetValue($name)
   $status='Требует ручной проверки'
   $path=''
   if($command -match '^\s*"([^"]+)"'){$path=$matches[1]}
   elseif($command -match '^\s*([A-Za-z]:\\[^\s]+\.exe)'){$path=$matches[1]}
   if($path -and -not (Test-Path -LiteralPath $path -PathType Leaf)){$status='Файл не найден; проверьте назначение записи'}
   elseif($path){$status='Целевой файл существует'}
   $rows.Add([pscustomobject]@{Key=$key;Name=$name;Status=$status;Command=$command})
  }
 }
 $result=[pscustomobject]@{Success=$true;Entries=@($rows.ToArray());Message='Аудит автозапуска завершён. Никакие записи реестра не удалены; удаление вслепую может повредить приложения.'}
}catch{$result=[pscustomobject]@{Success=$false;Message=$_.Exception.Message}}
try{$result|ConvertTo-Json -Depth 6|Set-Content -LiteralPath $OutputPath -Encoding UTF8 -ErrorAction Stop}catch{exit 2}
if(-not $result.Success){exit 1}
