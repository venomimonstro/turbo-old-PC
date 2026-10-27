[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidateSet('ApplyUI','ApplyPower','Restore','History')][string]$Mode,
    [Parameter(Mandatory=$true)][string]$OutputPath
)
$ErrorActionPreference = 'Stop'
$backupDir = Join-Path $env:LOCALAPPDATA 'TurboOldPC\Backups'
[void][IO.Directory]::CreateDirectory($backupDir)
$allowed = @(
    [pscustomobject]@{Path='HKCU:\Control Panel\Desktop\WindowMetrics';Name='MinAnimate';Type='String';Value='0'},
    [pscustomobject]@{Path='HKCU:\Control Panel\Desktop';Name='MenuShowDelay';Type='String';Value='100'},
    [pscustomobject]@{Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced';Name='TaskbarAnimations';Type='DWord';Value=0},
    [pscustomobject]@{Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced';Name='ListviewAlphaSelect';Type='DWord';Value=0},
    [pscustomobject]@{Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced';Name='ListviewShadow';Type='DWord';Value=0}
)
function Save-Journal($journal,[string]$path) {
    $json = $journal | ConvertTo-Json -Depth 9
    $temp = $path + '.tmp'
    [IO.File]::WriteAllText($temp, [string]$json, (New-Object System.Text.UTF8Encoding($true)))
    Move-Item -LiteralPath $temp -Destination $path -Force -ErrorAction Stop
}
function New-Backup([string]$profile) {
    $record = [pscustomobject]@{
        Version=1;Created=(Get-Date).ToString('o');Status='Pending'
        Profile=$profile;Registry=@();PowerScheme='';RestoredAt=''
    }
    if ($profile -eq 'ApplyUI') {
        $entries = New-Object 'System.Collections.Generic.List[object]'
        foreach ($item in $allowed) {
            $key = Get-Item -LiteralPath $item.Path -ErrorAction Stop
            $exists = ($null -ne $key.GetValue($item.Name,$null))
            $original = if ($exists) { $key.GetValue($item.Name,$null) } else { $null }
            $entries.Add([pscustomobject]@{
                Path=$item.Path;Name=$item.Name;Type=$item.Type
                Existed=[bool]$exists;OldValue=$original
            })
        }
        $record.Registry = @($entries.ToArray())
    } elseif ($profile -eq 'ApplyPower') {
        $output = @(& powercfg.exe /GETACTIVESCHEME 2>&1 | ForEach-Object { [string]$_ }) -join ' '
        if ($LASTEXITCODE -ne 0) { throw "Не удалось определить план питания: $output" }
        $hit = [regex]::Match($output,'[a-fA-F0-9]{8}-(?:[a-fA-F0-9]{4}-){3}[a-fA-F0-9]{12}')
        if (-not $hit.Success) { throw 'Windows не сообщила GUID активного плана питания.' }
        $record.PowerScheme = $hit.Value
    }
    return $record
}
function Restore-Backup($record) {
    if ([int]$record.Version -ne 1) { throw 'Неизвестный формат резервной записи.' }
    switch ([string]$record.Profile) {
        'ApplyUI' {
            foreach ($entry in @($record.Registry)) {
                $rule = @($allowed | Where-Object { $_.Path -eq $entry.Path -and $_.Name -eq $entry.Name })
                if ($rule.Count -ne 1) { throw 'Журнал содержит недопустимый параметр. Восстановление остановлено.' }
                if ($entry.Existed) {
                    Set-ItemProperty -LiteralPath $entry.Path -Name $entry.Name -Value $entry.OldValue -ErrorAction Stop
                } else {
                    Remove-ItemProperty -LiteralPath $entry.Path -Name $entry.Name -ErrorAction SilentlyContinue
                }
            }
        }
        'ApplyPower' {
            $guid = [string]$record.PowerScheme
            if ($guid -notmatch '^[a-fA-F0-9]{8}-(?:[a-fA-F0-9]{4}-){3}[a-fA-F0-9]{12}$') {
                throw 'Недействительный GUID схемы в журнале.'
            }
            $log = @(& powercfg.exe /SETACTIVE $guid 2>&1)
            if ($LASTEXITCODE -ne 0) { throw ('Windows отклонила восстановление: ' + ($log -join ' ')) }
        }
        default { throw 'Неизвестный профиль в журнале.' }
    }
}
try {
    if ($Mode -eq 'History') {
        $history = @(Get-ChildItem -LiteralPath $backupDir -Filter 'boost-*.json' -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 100 |
            ForEach-Object {
                try {
                    $a = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
                    [pscustomobject]@{Date=[string]$a.Created;Profile=[string]$a.Profile;Status=[string]$a.Status}
                } catch { }
            })
        $result = [pscustomobject]@{Success=$true;History=$history;Message="Записей истории: $($history.Count)"}
    } elseif ($Mode -eq 'Restore') {
        $target = $null
        foreach ($file in @(Get-ChildItem -LiteralPath $backupDir -Filter 'boost-*.json' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)) {
            try {
                $a = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
                if ($a.Status -in @('Applied','Pending','RestoreFailed')) {
                    $target = [pscustomobject]@{Path=$file.FullName;Journal=$a};break
                }
            } catch { }
        }
        if ($null -eq $target) { throw 'Нет невосстановленных изменений Turbo Old PC.' }
        try {
            Restore-Backup $target.Journal
            $target.Journal.Status = 'Restored'
            $target.Journal.RestoredAt = (Get-Date).ToString('o')
            Save-Journal $target.Journal $target.Path
        } catch {
            $target.Journal.Status = 'RestoreFailed'
            Save-Journal $target.Journal $target.Path
            throw
        }
        $result = [pscustomobject]@{Success=$true;Message="Восстановлен профиль $($target.Journal.Profile) от $($target.Journal.Created). Некоторые визуальные эффекты обновятся после нового входа в Windows."}
    } else {
        $journal = New-Backup $Mode
        $file = Join-Path $backupDir ('boost-' + (Get-Date -Format 'yyyyMMddHHmmssfff') + '-' + ([guid]::NewGuid().ToString('N')) + '.json')
        Save-Journal $journal $file
        try {
            if ($Mode -eq 'ApplyUI') {
                foreach ($item in $allowed) {
                    $value = $item.Value
                    if ($item.Type -eq 'DWord') { $value=[int]$value }
                    New-ItemProperty -LiteralPath $item.Path -Name $item.Name -Value $value -PropertyType $item.Type -Force -ErrorAction Stop | Out-Null
                }
            } elseif ($Mode -eq 'ApplyPower') {
                $log = @(& powercfg.exe /SETACTIVE '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c' 2>&1)
                if ($LASTEXITCODE -ne 0) { throw ('План Высокая производительность недоступен: '+($log -join ' ')) }
            }
            $journal.Status = 'Applied'
            Save-Journal $journal $file
        } catch {
            $originalError = $_.Exception.Message
            try {
                Restore-Backup $journal
                $journal.Status = 'Restored'
            } catch {
                $journal.Status = 'RestoreFailed'
                $originalError += '; автоматический откат не завершён: ' + $_.Exception.Message
            }
            Save-Journal $journal $file
            throw $originalError
        }
        $explanation = if ($Mode -eq 'ApplyUI') {
            'Отключены некоторые эффекты анимации текущего пользователя; часть применится после повторного входа.'
        } else {
            'Активирована схема высокой производительности. Возможны нагрев, шум и снижение автономности.'
        }
        $result = [pscustomobject]@{Success=$true;Message=$explanation + ' Предыдущее состояние записано, можно нажать «Отменить последний буст».'}
    }
} catch {
    $result = [pscustomobject]@{Success=$false;Message=$_.Exception.Message}
}
try {$result|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $OutputPath -Encoding UTF8 -ErrorAction Stop} catch {exit 2}
if (-not $result.Success) {exit 1}
