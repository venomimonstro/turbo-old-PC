[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][ValidateSet('Status','Update','Threats','Remediate')][string]$Mode,
 [Parameter(Mandatory=$true)][string]$OutputPath
)
$ErrorActionPreference='Stop'
try {
 if(-not (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue)){throw 'Microsoft Defender недоступен.'}
 $status=Get-MpComputerStatus -ErrorAction Stop
 if(-not $status.AntivirusEnabled){throw 'Defender отключён или находится в пассивном режиме. Проверьте установленный антивирус.'}
 switch($Mode){
  'Update' {
   Update-MpSignature -ErrorAction Stop
   $status=Get-MpComputerStatus -ErrorAction Stop
  }
  'Remediate' {
   $id=[Security.Principal.WindowsIdentity]::GetCurrent()
   $principal=New-Object Security.Principal.WindowsPrincipal($id)
   if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
    throw 'Удаление обнаруженных активных угроз требует прав администратора.'
   }
   Remove-MpThreat -ErrorAction Stop
  }
 }
 $detections=@()
 if($Mode -in @('Threats','Remediate')){
  $detections=@(Get-MpThreatDetection -ErrorAction Stop |
    Sort-Object InitialDetectionTime -Descending | Select-Object -First 60 |
    ForEach-Object {
      [pscustomobject]@{
       ThreatID=[string]$_.ThreatID
       Time=[string]$_.InitialDetectionTime
       ActionSuccess=[string]$_.ActionSuccess
       Resources=(@($_.Resources|Select-Object -First 3)-join '; ')
      }
    })
 }
 $result=[pscustomobject]@{
  Success=$true;Mode=$Mode;SignatureVersion=[string]$status.AntivirusSignatureVersion
  SignatureUpdated=[string]$status.AntivirusSignatureLastUpdated
  EngineVersion=[string]$status.AMEngineVersion;Realtime=[bool]$status.RealTimeProtectionEnabled
  Detections=$detections
  Message="Microsoft Defender: базы $($status.AntivirusSignatureVersion), обновлены $($status.AntivirusSignatureLastUpdated), движок $($status.AMEngineVersion). Обнаружений в истории: $($detections.Count)."
 }
}catch{$result=[pscustomobject]@{Success=$false;Mode=$Mode;Message=$_.Exception.Message}}
try{$result|ConvertTo-Json -Depth 7|Set-Content -LiteralPath $OutputPath -Encoding UTF8 -ErrorAction Stop}catch{exit 2}
if(-not $result.Success){exit 1}
