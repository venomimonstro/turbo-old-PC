[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][ValidateSet('Analyze','Clean')][string]$Mode,
 [Parameter(Mandatory=$true)][ValidatePattern('^[A-Za-z]:$')][string]$Drive,
 [Parameter(Mandatory=$true)][string]$OutputPath,
 [string]$ManifestPath
)
$ErrorActionPreference='Stop'
function Full([string]$p) { [IO.Path]::GetFullPath($p).TrimEnd('\') }
function Inside([string]$p,[string]$root) {
 $path=Full $p; $base=Full $root
 return $path.StartsWith(($base+'\'),[StringComparison]::OrdinalIgnoreCase)
}
function NoLinks([string]$p,[string]$root) {
 if(-not (Inside $p $root)){return $false}
 $dir=[IO.Path]::GetDirectoryName((Full $p))
 while($dir -and (Inside $dir $root -or $dir.Equals((Full $root),[StringComparison]::OrdinalIgnoreCase))){
  $info=Get-Item -LiteralPath $dir -Force -ErrorAction Stop
  if(($info.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){return $false}
  if($dir.Equals((Full $root),[StringComparison]::OrdinalIgnoreCase)){break}
  $dir=[IO.Path]::GetDirectoryName($dir)
 }
 return $true
}
function Get-Categories([string]$letter) {
 $roots=New-Object 'System.Collections.Generic.List[object]'
 function Add-Root([string]$label,[string]$path,[int]$age) {
  if(-not $path){return}
  try{
   $actual=Full $path
   if(-not $actual.StartsWith(($letter+'\'),[StringComparison]::OrdinalIgnoreCase)){return}
   if(-not (Test-Path -LiteralPath $actual -PathType Container)){return}
   $item=Get-Item -LiteralPath $actual -Force -ErrorAction Stop
   if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){return}
   $roots.Add([pscustomobject]@{Category=$label;Root=$actual;AgeDays=$age})
  }catch{}
 }
 Add-Root 'Временные файлы пользователя' (Join-Path $env:LOCALAPPDATA 'Temp') 2
 Add-Root 'Кэш отчётов об ошибках пользователя' (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\WER\ReportArchive') 14
 Add-Root 'Кэш очереди отчётов об ошибках' (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\WER\ReportQueue') 14
 Add-Root 'Временные файлы Windows' (Join-Path $env:SystemRoot 'Temp') 7
 Add-Root 'Отчёты ошибок Windows' (Join-Path $env:ProgramData 'Microsoft\Windows\WER\ReportArchive') 14
 Add-Root 'Очередь ошибок Windows' (Join-Path $env:ProgramData 'Microsoft\Windows\WER\ReportQueue') 14
 return @($roots.ToArray())
}
function Enumerate($category) {
 $cutoff=(Get-Date).AddDays(-[int]$category.AgeDays)
 $stack=New-Object System.Collections.Stack
 $stack.Push($category.Root)
 $list=New-Object 'System.Collections.Generic.List[object]'
 $visited=0
 while($stack.Count -gt 0 -and $visited -lt 30000){
  $folder=$stack.Pop()
  foreach($e in @(Get-ChildItem -LiteralPath $folder -Force -ErrorAction SilentlyContinue)){
   $visited++
   if($visited -gt 30000){break}
   if(($e.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){continue}
   if($e.PSIsContainer){$stack.Push($e.FullName);continue}
   if($e.LastWriteTime -gt $cutoff){continue}
   if(-not (Inside $e.FullName $category.Root)){continue}
   $list.Add([pscustomobject]@{
     Path=$e.FullName;Root=$category.Root;Category=$category.Category
     AgeDays=$category.AgeDays;Length=[int64]$e.Length
   })
   if($list.Count -ge 15000){return @($list.ToArray())}
  }
 }
 return @($list.ToArray())
}
function Save-Manifest([string]$path,$value){
 $json=$value|ConvertTo-Json -Depth 6
 [IO.File]::WriteAllText($path,$json,(New-Object Text.UTF8Encoding($true)))
}
try {
 $driveRoot=$Drive.ToUpperInvariant()+'\'
 if(-not (Test-Path -LiteralPath $driveRoot -PathType Container)){throw 'Указанный диск не найден.'}
 $categories=@(Get-Categories $Drive.ToUpperInvariant())
 if($Mode -eq 'Analyze'){
  $items=New-Object 'System.Collections.Generic.List[object]'
  $truncated=$false
  foreach($category in $categories){
   foreach($file in @(Enumerate $category)){
    if($items.Count -ge 30000){$truncated=$true;break}
    $items.Add($file)
   }
   if($truncated){break}
  }
  $summary=@($items.ToArray()|Group-Object Category|ForEach-Object{
    [pscustomobject]@{Category=$_.Name;Files=$_.Count;Bytes=[int64](($_.Group|Measure-Object Length -Sum).Sum)}
  })
  $manifestDir=Join-Path $env:LOCALAPPDATA 'TurboOldPC\Manifests'
  [void][IO.Directory]::CreateDirectory($manifestDir)
  $manifest=Join-Path $manifestDir (([guid]::NewGuid().ToString('N'))+'.json')
  Save-Manifest $manifest ([pscustomobject]@{Drive=$Drive.ToUpperInvariant();Created=(Get-Date).ToString('o');Files=@($items.ToArray())})
  $result=[pscustomobject]@{
   Success=$true;Mode=$Mode;Drive=$Drive.ToUpperInvariant();Groups=$summary
   Count=$items.Count;Truncated=$truncated;Bytes=[int64](($items.ToArray()|Measure-Object Length -Sum).Sum)
   ManifestPath=$manifest
   Message='Найдены только проверенные категории очистки. Если лимит 30 000 файлов достигнут, анализ неполный. Другие крупные файлы на диске не удаляются автоматически.'
  }
 }else{
  $manifestRoot=Full (Join-Path $env:LOCALAPPDATA 'TurboOldPC\Manifests')
  if(-not $ManifestPath -or -not (Inside $ManifestPath $manifestRoot) -or -not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)){throw 'Сначала выполните анализ диска.'}
  $manifest=Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
  if($manifest.Drive -ne $Drive.ToUpperInvariant()){throw 'Диск в манифесте отличается от выбранного.'}
  if(((Get-Date)-[datetime]$manifest.Created).TotalMinutes -gt 30){throw 'Анализ устарел. Повторите поиск мусора.'}
  $allow=@(Get-Categories $Drive.ToUpperInvariant())
  $deleted=0;$failed=0;$bytes=[int64]0
  foreach($file in @($manifest.Files)){
   $matched=@($allow|Where-Object{$_.Root -eq $file.Root -and $_.Category -eq $file.Category -and $_.AgeDays -eq $file.AgeDays})
   if($matched.Count -ne 1 -or -not (Inside $file.Path $matched[0].Root)){$failed++;continue}
   try{
    if(-not (NoLinks $file.Path $matched[0].Root)){$failed++;continue}
    $current=Get-Item -LiteralPath $file.Path -Force -ErrorAction Stop
    if($current.PSIsContainer -or (($current.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)){$failed++;continue}
    if($current.LastWriteTime -gt (Get-Date).AddDays(-[int]$matched[0].AgeDays)){$failed++;continue}
    if([int64]$current.Length -ne [int64]$file.Length){$failed++;continue}
    $size=[int64]$current.Length
    Remove-Item -LiteralPath $current.FullName -Force -ErrorAction Stop
    $deleted++;$bytes+=$size
   }catch{$failed++}
  }
  Remove-Item -LiteralPath $ManifestPath -Force -ErrorAction SilentlyContinue
  $result=[pscustomobject]@{Success=$true;Mode=$Mode;Deleted=$deleted;Skipped=$failed;Bytes=$bytes;Message='Очистка завершена. Другие файлы не затрагивались.'}
 }
}catch{$result=[pscustomobject]@{Success=$false;Mode=$Mode;Message=$_.Exception.Message}}
try{$result|ConvertTo-Json -Depth 7|Set-Content -LiteralPath $OutputPath -Encoding UTF8 -ErrorAction Stop}catch{exit 2}
if(-not $result.Success){exit 1}
