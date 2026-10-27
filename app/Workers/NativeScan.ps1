[CmdletBinding()]
param([Parameter(Mandatory=$true)][ValidateSet('Scan')][string]$Mode,
[Parameter(Mandatory=$true)][string]$OutputPath,
[string]$ScanRoot)
$ErrorActionPreference='Stop'
try{
 Import-Module (Join-Path $PSScriptRoot '..\Turbo.Scanner.psm1') -Force -ErrorAction Stop
 $db=Join-Path $PSScriptRoot '..\..\data\signatures.json'
 if(-not $ScanRoot){throw 'Выберите папку для проверки.'}
 $scan=Invoke-TurboFileScan -Root $ScanRoot -DatabasePath $db
 $limitText=if($scan.Truncated){' Проверка прервана лимитами времени, числа файлов или общего объёма. Часть объектов не исследована.'}else{''}
 $result=[pscustomobject]@{
   Success=$true;Mode=$Mode;Scan=$scan
   Message="Проверено файлов: $($scan.Scanned), $([math]::Round([double]$scan.HashedBytes/1MB,1)) МБ за $($scan.ElapsedSeconds) с. Ошибок чтения: $($scan.Errors). Сигнатур: $($scan.Signatures). Совпадений: $(@($scan.Findings).Count).$limitText Отсутствие совпадений НЕ означает безопасность; подтверждение и карантин — через Microsoft Defender."
 }
}catch{$result=[pscustomobject]@{Success=$false;Mode=$Mode;Message=$_.Exception.Message}}
try{$result|ConvertTo-Json -Depth 6|Set-Content -LiteralPath $OutputPath -Encoding UTF8 -ErrorAction Stop}catch{exit 2}
if(-not $result.Success){exit 1}
