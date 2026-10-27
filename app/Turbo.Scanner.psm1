Set-StrictMode -Version 2.0
# Independent, on-demand, read-only file scanner; NOT real-time antivirus protection.
function Get-TurboSignatureDatabase {
 param([Parameter(Mandatory=$true)][string]$DatabasePath)
 if(-not (Test-Path -LiteralPath $DatabasePath -PathType Leaf)){throw 'База сигнатур отсутствует.'}
 $raw=Get-Content -LiteralPath $DatabasePath -Raw -Encoding UTF8|ConvertFrom-Json -ErrorAction Stop
 if([int]$raw.Schema -ne 1){throw 'Версия базы сигнатур не поддерживается.'}
 $db=@{}
 foreach($rule in @($raw.Signatures)){
  $hash=[string]$rule.SHA256
  if($hash -notmatch '^[A-Fa-f0-9]{64}$'){throw 'Недопустимый SHA256 в базе.'}
  $db[$hash.ToUpperInvariant()]=[string]$rule.Name
 }
 return $db
}
function Invoke-TurboFileScan {
 [CmdletBinding()]
 param(
   [Parameter(Mandatory=$true)][string]$Root,
   [Parameter(Mandatory=$true)][string]$DatabasePath,
   [ValidateRange(1,100000)][int]$FileLimit=20000,
   [ValidateRange(1,1024)][int]$MaxFileMB=64
 )
 $directory=[IO.Path]::GetFullPath($Root).TrimEnd('\')
 if(-not (Test-Path -LiteralPath $directory -PathType Container)){throw 'Каталог сканирования не существует.'}
 $rootInfo=Get-Item -LiteralPath $directory -Force -ErrorAction Stop
 if(($rootInfo.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'Корневой каталог является ссылкой.'}
 $db=Get-TurboSignatureDatabase -DatabasePath $DatabasePath
 $stack=New-Object System.Collections.Stack
 $stack.Push($directory)
 $findings=New-Object 'System.Collections.Generic.List[object]'
 $scanned=0;$skipped=0;$errors=0
 $cutoff=[int64]$MaxFileMB*1MB
 while($stack.Count -gt 0 -and $scanned -lt $FileLimit){
  $folder=[string]$stack.Pop()
  try{$children=@(Get-ChildItem -LiteralPath $folder -Force -ErrorAction Stop)}
  catch{$errors++;continue}
  foreach($entry in $children){
   if(($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){$skipped++;continue}
   if($entry.PSIsContainer){$stack.Push($entry.FullName);continue}
   if([int64]$entry.Length -gt $cutoff){$skipped++;continue}
   $scanned++
   try{
    $hash=(Get-FileHash -LiteralPath $entry.FullName -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()
    if($db.ContainsKey($hash)){
     $findings.Add([pscustomobject]@{Path=$entry.FullName;SHA256=$hash;Kind='Signature';Name=$db[$hash];Confidence='ConfirmedHash'})
    }
   }catch{$errors++}
   if($scanned -ge $FileLimit){break}
  }
 }
 [pscustomobject]@{
  Root=$directory;Scanned=$scanned;Skipped=$skipped;Errors=$errors
  Truncated=($stack.Count -gt 0 -or $scanned -ge $FileLimit)
  Findings=@($findings.ToArray());Signatures=$db.Count
 }
}
Export-ModuleMember -Function Get-TurboSignatureDatabase,Invoke-TurboFileScan
