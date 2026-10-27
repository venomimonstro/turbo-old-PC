[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidateSet('List','Download','Install')][string]$Mode,
    [Parameter(Mandatory=$true)][string]$OutputPath,
    [ValidatePattern('^[a-fA-F0-9-]{36}$')][string]$UpdateId,
    [int]$Revision = -1
)
$ErrorActionPreference = 'Stop'
function New-WuaSession {
    return New-Object -ComObject 'Microsoft.Update.Session'
}
function Find-DriverUpdates {
    $session = New-WuaSession
    $searcher = $session.CreateUpdateSearcher()
    $res = $searcher.Search("IsInstalled=0 and Type='Driver' and IsHidden=0")
    if ([int]$res.ResultCode -ne 2) {
        throw "Поиск через Windows Update завершился с кодом $($res.ResultCode)."
    }
    return [pscustomobject]@{Session=$session;Updates=$res.Updates}
}
try {
    $found = Find-DriverUpdates
    $items = New-Object 'System.Collections.Generic.List[object]'
    for ($i=0; $i -lt $found.Updates.Count; $i++) {
        $update = $found.Updates.Item($i)
        $id = [string]$update.Identity.UpdateID
        if ($id -notmatch '^[a-fA-F0-9-]{36}$') { continue }
        $items.Add([pscustomobject]@{
            Title = [string]$update.Title
            UpdateId = $id
            Revision = [int]$update.Identity.RevisionNumber
            Reboot = [bool]$update.RebootRequired
            Downloaded = [bool]$update.IsDownloaded
        })
    }
    if ($Mode -eq 'List') {
        $result = [pscustomobject]@{
            Success=$true; Mode=$Mode; Updates=@($items.ToArray())
            Message="Найдено обновлений драйверов: $($items.Count). Источник — Windows Update Agent с текущей системной политикой."
        }
    } else {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            throw 'Для установки драйвера требуются права администратора.'
        }
        if ([string]::IsNullOrWhiteSpace($UpdateId)) { throw 'Не указан идентификатор выбранного обновления.' }
        $chosen = $null
        for ($i=0; $i -lt $found.Updates.Count; $i++) {
            $u = $found.Updates.Item($i)
            if ([string]$u.Identity.UpdateID -eq $UpdateId) { $chosen=$u;break }
        }
        if ($null -eq $chosen) { throw 'Выбранное обновление больше не предлагается Windows Update. Повторите поиск.' }
        if ($Revision -ge 0 -and [int]$chosen.Identity.RevisionNumber -ne $Revision) {
            throw 'Ревизия обновления изменилась. Обновите список и подтвердите заново.'
        }
        if ([string]$chosen.Type -ne '2' -and [string]$chosen.Type -ne 'Driver') {
            throw 'Обновление не является драйвером.'
        }
        if ([bool]$chosen.IsInstalled -or [bool]$chosen.IsHidden) { throw 'Обновление уже установлено или скрыто.' }
        if ($Mode -eq 'Install') {
        # Fail closed: both creation and verification of a NEW restore point are required.
        try {
            $beforePoints = @(Get-ComputerRestorePoint -ErrorAction Stop | Sort-Object SequenceNumber -Descending | Select-Object -First 1)
            $beforeSeq = if ($beforePoints.Count -gt 0) { [int64]$beforePoints[0].SequenceNumber } else { [int64]-1 }
            Checkpoint-Computer -Description ('TurboOldPC driver '+$UpdateId) -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
            $afterPoints = @(Get-ComputerRestorePoint -ErrorAction Stop | Sort-Object SequenceNumber -Descending | Select-Object -First 1)
            if ($afterPoints.Count -eq 0 -or [int64]$afterPoints[0].SequenceNumber -le $beforeSeq) {
                throw 'Новая контрольная точка не подтверждена системой.'
            }
        } catch {
            throw 'Не удалось создать и подтвердить НОВУЮ точку восстановления. Установка отменена. Проверьте защиту системы; Windows может ограничивать частоту создания точек. Причина: ' + $_.Exception.Message
        }
        }
        if (-not $chosen.EulaAccepted) { $chosen.AcceptEula() }
        $collection = New-Object -ComObject 'Microsoft.Update.UpdateColl'
        [void]$collection.Add($chosen)
        if (-not $chosen.IsDownloaded) {
            $downloader = $found.Session.CreateUpdateDownloader()
            $downloader.Updates = $collection
            $dl = $downloader.Download()
            if ([int]$dl.ResultCode -ne 2 -or [int]$dl.GetUpdateResult(0).ResultCode -ne 2 -or -not $chosen.IsDownloaded) {
                throw "Windows Update не смог загрузить драйвер. Код: $($dl.ResultCode)."
            }
        }
        if ($Mode -eq 'Download') {
            $result = [pscustomobject]@{
                Success=$true;Mode='Download';DownloadedTitle=[string]$chosen.Title
                Message='Драйвер загружен в системный кэш Windows Update. Файл остаётся под управлением Windows и не выдаётся как отдельный OEM-установщик. Нажмите «Установить выбранный», чтобы запустить установку.'
            }
        } else {
        $installer = $found.Session.CreateUpdateInstaller()
        $installer.Updates = $collection
        $installation = $installer.Install()
        $installCode = [int]$installation.ResultCode
        $perUpdateCode = [int]$installation.GetUpdateResult(0).ResultCode
        $result = [pscustomobject]@{
            Success=($installCode -eq 2 -and $perUpdateCode -eq 2); Mode='Install'; InstalledTitle=[string]$chosen.Title
            ResultCode=$installCode; IndividualResultCode=$perUpdateCode; RebootRequired=[bool]$installation.RebootRequired
            Message="Результат Windows Update: общий код $installCode, код обновления $perUpdateCode. Перезагрузка необходима: $($installation.RebootRequired). Создана точка восстановления перед установкой. Управление восстановлением — через Windows."
        }
        }
    }
} catch {
    $result = [pscustomobject]@{Success=$false;Mode=$Mode;Message=$_.Exception.Message}
}
try {
    $result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding UTF8 -ErrorAction Stop
} catch { exit 2 }
if (-not $result.Success) { exit 1 }
