[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][ValidatePattern('^[A-Za-z]:$')][string]$Drive,
 [Parameter(Mandatory=$true)][string]$OutputPath
)
$ErrorActionPreference='Stop'
try{
 $root=$Drive.ToUpperInvariant()+'\'
 if(-not (Test-Path -LiteralPath $root -PathType Container)){throw 'Диск не найден.'}
 $stack=New-Object System.Collections.Stack
 $stack.Push([pscustomobject]@{Path=$root;Depth=0})
 $top=New-Object 'System.Collections.Generic.List[object]'
 $directories=@{}
 $count=0;$skipped=0;$bytes=[int64]0
 $limit=180000;$maxDepth=24
 while($stack.Count -gt 0 -and $count -lt $limit){
  $current=$stack.Pop()
  try {$items=@(Get-ChildItem -LiteralPath $current.Path -Force -ErrorAction Stop)}
  catch {$skipped++;continue}
  foreach($item in $items){
   if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){$skipped++;continue}
   if($item.PSIsContainer){
    if($current.Depth -lt $maxDepth){$stack.Push([pscustomobject]@{Path=$item.FullName;Depth=$current.Depth+1})}
    else{$skipped++}
    continue
   }
   $count++
   $size=[int64]$item.Length;$bytes+=$size
   $full=[IO.Path]::GetFullPath($item.FullName)
   if(-not $full.StartsWith($root,[StringComparison]::OrdinalIgnoreCase)){continue}
   $relative=$full.Substring($root.Length)
   $part=$relative.Split('\')[0]
   if([string]::IsNullOrWhiteSpace($part)){$part='(корень)'}
   if(-not $directories.ContainsKey($part)){$directories[$part]=[int64]0}
   $directories[$part]=[int64]$directories[$part]+$size
   if($size -ge 100MB){
    $top.Add([pscustomobject]@{Path=$full;SizeBytes=$size})
   }
   if($count -ge $limit){break}
  }
 }
 $largest=@($top.ToArray()|Sort-Object SizeBytes -Descending|Select-Object -First 60)
 $groups=@($directories.GetEnumerator()|Sort-Object Value -Descending|Select-Object -First 35|ForEach-Object{
  [pscustomobject]@{Name=[string]$_.Key;Bytes=[int64]$_.Value}
 })
 $result=[pscustomobject]@{
  Success=$true;Largest=$largest;Folders=$groups;ScannedFiles=$count;ScannedBytes=$bytes
  SkippedFolders=$skipped;Truncated=($count -ge $limit)
  Message='Карта диска — только чтение. Данные приблизительные: системные блокировки и лимит обхода могут скрыть часть файлов. Удаление не производится.'
 }
}catch{$result=[pscustomobject]@{Success=$false;Message=$_.Exception.Message}}
try{$result|ConvertTo-Json -Depth 6|Set-Content -LiteralPath $OutputPath -Encoding UTF8 -ErrorAction Stop}catch{exit 2}
if(-not $result.Success){exit 1}
