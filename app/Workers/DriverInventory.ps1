[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$OutputPath)
$ErrorActionPreference='Stop'
try {
 $items=@(Get-CimInstance Win32_PnPSignedDriver -ErrorAction Stop |
  Where-Object { -not [string]::IsNullOrWhiteSpace($_.DeviceName) } |
  Sort-Object DeviceName |
  Select-Object -First 500 |
  ForEach-Object {
   [pscustomobject]@{
    Name=[string]$_.DeviceName
    Provider=[string]$_.DriverProviderName
    Version=[string]$_.DriverVersion
    Date=[string]$_.DriverDate
    Signed=[bool]$_.IsSigned
    DeviceID=[string]$_.DeviceID
    InfName=[string]$_.InfName
   }
  })
 $result=[pscustomobject]@{Success=$true;Drivers=$items;Message="Установленных драйверов: $($items.Count). Срок выпуска сам по себе не означает уязвимость."}
}catch{$result=[pscustomobject]@{Success=$false;Message=$_.Exception.Message}}
try{$result|ConvertTo-Json -Depth 7|Set-Content -LiteralPath $OutputPath -Encoding UTF8 -ErrorAction Stop}catch{exit 2}
if(-not $result.Success){exit 1}
