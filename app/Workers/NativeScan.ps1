[CmdletBinding()]
param([Parameter(Mandatory=$true)][ValidateSet('Scan','Quarantine')][string]$Mode,
[Parameter(Mandatory=$true)][string]$OutputPath,
[string]$ScanRoot,[string]$FindingPath,[string]$ExpectedHash)
$ErrorActionPreference='Stop'
try{
 Import-Module (Join-Path $PSScriptRoot '..\Turbo.Scanner.psm1') -Force -ErrorAction Stop
 $db=Join-Path $PSScriptRoot '..\..\data\signatures.json'
 if($Mode -eq 'Scan'){
  if(-not $ScanRoot){throw 'Выберите папку для проверки.'}
  $scan=Invoke-TurboFileScan -Root $ScanRoot -DatabasePath $db
  $result=[pscustomobject]@{Success=$true;Mode=$Mode;Scan=$scan;Message="Проверено файлов: $($scan.Scanned). Сигнатур: $($scan.Signatures). Совпадений: $(@($scan.Findings).Count). Сканер экспериментальный, проверяет только точные хеши; отсутствие совпадений НЕ означает безопасность."}
 }else{
  if($ExpectedHash -notmatch '^[A-Fa-f0-9]{64}$' -or -not $FindingPath){throw 'Недействительное подтверждение обнаружения.'}
  $allowed=Get-TurboSignatureDatabase -DatabasePath $db
  $expected=$ExpectedHash.ToUpperInvariant()
  if(-not $allowed.ContainsKey($expected)){throw 'Этот хеш отсутствует в проверенной базе. Карантин отменён.'}
  $source=[IO.Path]::GetFullPath($FindingPath)
  $item=Get-Item -LiteralPath $source -Force -ErrorAction Stop
  if($item.PSIsContainer -or (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)){throw 'Нельзя помещать ссылки или каталоги в карантин.'}
  if($source -match '(?i)\\Windows\\|\\Program Files( \(x86\))?\\'){throw 'Системные каталоги запрещены для автоматического карантина.'}
  $observed=(Get-FileHash -LiteralPath $source -Algorithm SHA256 -ErrorAction Stop).Hash
  if($observed -ne $expected){throw 'Файл изменился с момента сканирования. Повторите проверку.'}
  $store=Join-Path $env:LOCALAPPDATA 'TurboOldPC\Quarantine'
  [void][IO.Directory]::CreateDirectory($store)
  $id=[guid]::NewGuid().ToString('N')
  $destination=Join-Path $store ($id+'.bin')
  Move-Item -LiteralPath $source -Destination $destination -ErrorAction Stop
  try{
   $manifest=[pscustomobject]@{Id=$id;OriginalPath=$source;Hash=$expected;DetectedName=$allowed[$expected];Created=(Get-Date).ToString('o');StoredFile=$destination}
   [IO.File]::WriteAllText((Join-Path $store ($id+'.json')),($manifest|ConvertTo-Json -Depth 4),(New-Object Text.UTF8Encoding($true)))
  }catch{
   Move-Item -LiteralPath $destination -Destination $source -ErrorAction SilentlyContinue
   throw
  }
  $result=[pscustomobject]@{Success=$true;Mode=$Mode;Message="Файл помещён в карантин Turbo Old PC: $id. Карантин не является полноценной изоляцией; исключите папку из общего доступа и проверьте встроенным Defender."}
 }
}catch{$result=[pscustomobject]@{Success=$false;Mode=$Mode;Message=$_.Exception.Message}}
try{$result|ConvertTo-Json -Depth 6|Set-Content -LiteralPath $OutputPath -Encoding UTF8 -ErrorAction Stop}catch{exit 2}
if(-not $result.Success){exit 1}
