[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$OutputPath)
$ErrorActionPreference='Stop'
try{
    $points=@(Get-ComputerRestorePoint -ErrorAction Stop|
        Sort-Object SequenceNumber -Descending|
        Select-Object -First 35|
        ForEach-Object {
            [pscustomobject]@{
                Sequence=[string]$_.SequenceNumber
                Description=[string]$_.Description
                Created=[string]$_.CreationTime
                Type=[string]$_.RestorePointType
            }
        })
    $result=[pscustomobject]@{
        Success=$true;Points=$points;
        Message="Доступных точек восстановления: $($points.Count). Для запуска восстановления используйте штатный мастер Windows, он предупредит о последствиях."
    }
}catch{
    $result=[pscustomobject]@{
        Success=$false;
        Message='Не удалось прочитать точки восстановления. Защита системы может быть отключена или права ограничены: '+$_.Exception.Message
    }
}
try{$result|ConvertTo-Json -Depth 6|Set-Content -LiteralPath $OutputPath -Encoding UTF8 -ErrorAction Stop}catch{exit 2}
if(-not $result.Success){exit 1}
