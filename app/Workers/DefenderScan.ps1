param(
    [Parameter(Mandatory=$true)][string]$OutputPath,
    [ValidateSet('QuickScan','FullScan')][string]$ScanType = 'QuickScan'
)
$ErrorActionPreference = 'Stop'
$result = $null
try {
    if (-not (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue)) {
        throw 'Microsoft Defender недоступен. Пользуйтесь установленным антивирусом.'
    }
    $status = Get-MpComputerStatus -ErrorAction Stop
    if (-not $status.AntivirusEnabled) {
        throw 'Microsoft Defender сейчас не активен. Откройте центр безопасности или другой установленный антивирус.'
    }
    $updateMessage = 'Антивирусные базы обновлены.'
    try {
        Update-MpSignature -ErrorAction Stop
    } catch {
        $updateMessage = 'Базы не обновились: ' + $_.Exception.Message
    }
    $scanStartedAt = Get-Date
    Start-MpScan -ScanType $ScanType -ErrorAction Stop
    $detected = 'Угрозы смотрите в журнале безопасности Windows.'
    try {
        $recent = @(Get-MpThreatDetection -ErrorAction Stop |
            Where-Object { $_.InitialDetectionTime -ge $scanStartedAt })
        if ($recent.Count -gt 0) {
            $detected = "Найдено записей обнаружений с начала проверки: $($recent.Count). Откройте журнал защиты Windows для просмотра действий и статуса."
        } else {
            $detected = 'Новых записей обнаружений с начала проверки не получено. Это не гарантирует отсутствие угроз.'
        }
    } catch { }
    $message = if ($ScanType -eq 'FullScan') { 'Полная проверка Microsoft Defender завершила команду.' } else { 'Быстрая проверка Microsoft Defender завершила команду.' }
    $result = [pscustomobject]@{
        Success = $true
        Message = $message + ' ' + $detected + ' ' + $updateMessage
        ScanType = $ScanType
    }
} catch {
    $result = [pscustomobject]@{
        Success=$false
        Message=$_.Exception.Message
        ScanType=$ScanType
    }
}
try {
    $result | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $OutputPath -Encoding UTF8 -ErrorAction Stop
} catch { exit 2 }
if (-not $result.Success) { exit 1 }
