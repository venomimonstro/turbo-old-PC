param([Parameter(Mandatory=$true)][string]$OutputPath)
$ErrorActionPreference = 'Stop'
try {
    if (-not (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue)) {
        throw 'Модуль Microsoft Defender недоступен. Используйте установленный антивирус.'
    }
    $status = Get-MpComputerStatus -ErrorAction Stop
    if (-not $status.AntivirusEnabled) {
        throw 'Антивирус Microsoft Defender сейчас не активен. Откройте Защиту Windows или установленный антивирус.'
    }
    $updateMessage = 'Базы проверены.'
    try {
        Update-MpSignature -ErrorAction Stop
    } catch {
        $updateMessage = 'Не удалось обновить базы: ' + $_.Exception.Message
    }
    Start-MpScan -ScanType QuickScan -ErrorAction Stop
    $result = [pscustomobject]@{
        Success = $true
        Message = 'Команда быстрой проверки передана Microsoft Defender. Результаты и найденные угрозы смотрите в журнале Защиты Windows. ' + $updateMessage
    }
} catch {
    $result = [pscustomobject]@{ Success=$false; Message=$_.Exception.Message }
}
try {
    $result | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $OutputPath -Encoding UTF8 -ErrorAction Stop
} catch { exit 2 }
if (-not $result.Success) { exit 1 }
