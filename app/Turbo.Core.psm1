Set-StrictMode -Version 2.0

function Get-TurboHardware {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $pc = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
    $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1
    $driveLetter = $env:SystemDrive.TrimEnd('\').TrimEnd(':')
    $diskName = 'Не удалось определить'
    $diskMedia = 'Неизвестно'
    $diskBus = 'Неизвестно'
    try {
        $disk = Get-Partition -DriveLetter $driveLetter -ErrorAction Stop | Get-Disk -ErrorAction Stop | Select-Object -First 1
        if ($null -ne $disk) {
            $diskName = [string]$disk.FriendlyName
            $diskMedia = [string]$disk.MediaType
            $diskBus = [string]$disk.BusType
            if ([string]::IsNullOrWhiteSpace($diskMedia) -or $diskMedia -match 'Unspecified|Unknown') {
                try {
                    $physical = @(Get-PhysicalDisk -ErrorAction Stop)
                    $matched = @($physical | Where-Object {
                        ([string]$_.DeviceId -eq [string]$disk.Number) -or
                        ([string]$_.FriendlyName -eq [string]$disk.FriendlyName)
                    } | Select-Object -First 1)
                    if ($matched.Count -eq 0 -and $physical.Count -eq 1) { $matched = @($physical[0]) }
                    if ($matched.Count -gt 0 -and [string]$matched[0].MediaType -match '^(HDD|SSD)$') {
                        $diskMedia = [string]$matched[0].MediaType
                    }
                } catch { }
            }
            if ([string]::IsNullOrWhiteSpace($diskMedia)) { $diskMedia = 'Неизвестно' }
        }
    } catch {
        try {
            $fallback = Get-CimInstance Win32_DiskDrive -ErrorAction Stop | Select-Object -First 1
            if ($null -ne $fallback) { $diskName = [string]$fallback.Model }
        } catch { }
    }
    $freeGb = 0
    $totalGb = 0
    try {
        $logical = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$($env:SystemDrive)'" -ErrorAction Stop
        if ($null -ne $logical) {
            $freeGb = [math]::Round(([double]$logical.FreeSpace / 1GB), 1)
            $totalGb = [math]::Round(([double]$logical.Size / 1GB), 1)
        }
    } catch { }
    [pscustomobject]@{
        Manufacturer = [string]$pc.Manufacturer
        Model = [string]$pc.Model
        CPU = [string]$cpu.Name
        Cores = [int]$cpu.NumberOfCores
        MemoryGb = [math]::Round(([double]$pc.TotalPhysicalMemory / 1GB), 1)
        FreeMemoryGb = [math]::Round(([double]$os.FreePhysicalMemory / 1MB), 1)
        Windows = [string]$os.Caption
        Version = [string]$os.Version
        Architecture = [string]$os.OSArchitecture
        SystemDrive = [string]$env:SystemDrive
        Disk = $diskName
        DiskType = $diskMedia
        DiskBus = $diskBus
        FreeGb = $freeGb
        TotalGb = $totalGb
    }
}

function Get-TurboBootEvents {
    try {
        $records = @(Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-Diagnostics-Performance/Operational'; Id=100 } -MaxEvents 5 -ErrorAction Stop)
        foreach ($record in $records) {
            $dataMap = @{}
            try {
                [xml]$xml = $record.ToXml()
                foreach ($field in $xml.Event.EventData.Data) {
                    $dataMap[[string]$field.Name] = [string]$field.'#text'
                }
            } catch { }
            $duration = $null
            $main = $null
            $post = $null
            try {
                if ($dataMap.ContainsKey('BootDuration')) { $duration = [math]::Round(([double]$dataMap['BootDuration'] / 1000), 1) }
                if ($dataMap.ContainsKey('MainPathBootTime')) { $main = [math]::Round(([double]$dataMap['MainPathBootTime'] / 1000), 1) }
                if ($dataMap.ContainsKey('BootPostBootTime')) { $post = [math]::Round(([double]$dataMap['BootPostBootTime'] / 1000), 1) }
            } catch { }
            [pscustomobject]@{ Date=$record.TimeCreated.ToString('yyyy-MM-dd HH:mm'); Seconds=$duration; MainSeconds=$main; PostSeconds=$post }
        }
    } catch { @() }
}

function Get-TurboStartup {
    try {
        @(Get-CimInstance Win32_StartupCommand -ErrorAction Stop | Sort-Object Name | Select-Object -First 120 -Property @(
            @{ Name='Name'; Expression={ [string]$_.Name } },
            @{ Name='Command'; Expression={ [string]$_.Command } },
            @{ Name='Location'; Expression={ [string]$_.Location } }
        ))
    } catch { @() }
}

function Get-TurboDriverProblems {
    try {
        @(Get-CimInstance Win32_PnPEntity -ErrorAction Stop |
            Where-Object { $null -ne $_.ConfigManagerErrorCode -and [int]$_.ConfigManagerErrorCode -ne 0 } |
            Sort-Object Name | Select-Object -First 120 -Property @(
                @{ Name='Name'; Expression={ [string]$_.Name } },
                @{ Name='Code'; Expression={ [int]$_.ConfigManagerErrorCode } },
                @{ Name='DeviceId'; Expression={ [string]$_.PNPDeviceID } }
            ))
    } catch { @() }
}

function Get-TurboDefender {
    try {
        if (-not (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue)) {
            return [pscustomobject]@{ Available=$false; Enabled=$false; Realtime=$false; Updated='Неизвестно' }
        }
        $mp = Get-MpComputerStatus -ErrorAction Stop
        $updated = 'Неизвестно'
        if ($null -ne $mp.AntivirusSignatureLastUpdated) {
            $updated = ([datetime]$mp.AntivirusSignatureLastUpdated).ToString('yyyy-MM-dd HH:mm')
        }
        [pscustomobject]@{ Available=$true; Enabled=[bool]$mp.AntivirusEnabled; Realtime=[bool]$mp.RealTimeProtectionEnabled; Updated=$updated }
    } catch {
        [pscustomobject]@{ Available=$false; Enabled=$false; Realtime=$false; Updated='Нет данных' }
    }
}

function Get-TurboSoftware {
    $keys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $entries = foreach ($key in $keys) {
        try {
            Get-ItemProperty -Path $key -ErrorAction SilentlyContinue |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_.DisplayName) } |
                ForEach-Object { [pscustomobject]@{ Name=[string]$_.DisplayName; Publisher=[string]$_.Publisher } }
        } catch { }
    }
    @($entries | Sort-Object Name, Publisher -Unique | Select-Object -First 200)
}

function Get-TurboHeavyProcesses {
    try {
        @(Get-Process -ErrorAction Stop | Sort-Object WorkingSet64 -Descending |
            Select-Object -First 12 -Property @(
                @{ Name='Name'; Expression={ [string]$_.ProcessName } },
                @{ Name='RamMb'; Expression={ [math]::Round(([double]$_.WorkingSet64 / 1MB),1) } },
                @{ Name='CpuTotalSeconds'; Expression={
                    if ($null -ne $_.CPU) { [math]::Round(([double]$_.CPU),0) } else { 0 }
                } }
            ))
    } catch { @() }
}

function Get-TurboServiceAudit {
    try {
        @(Get-CimInstance Win32_Service -Filter "StartMode='Auto' AND State='Running'" -ErrorAction Stop |
            Where-Object {
                $_.PathName -and ([string]$_.PathName -notmatch 'Windows\\|SystemRoot|svchost.exe')
            } | Sort-Object DisplayName | Select-Object -First 70 -Property @(
                @{ Name='Name'; Expression={ [string]$_.Name } },
                @{ Name='DisplayName'; Expression={ [string]$_.DisplayName } },
                @{ Name='Executable'; Expression={ [string]$_.PathName } }
            ))
    } catch { @() }
}

function Get-TurboRecommendations {
    param([Parameter(Mandatory=$true)]$Snapshot)
    $result = New-Object 'System.Collections.Generic.List[string]'
    $h = $Snapshot.Hardware
    if ($null -ne $h) {
        if ([string]$h.DiskType -match '^HDD$') {
            $result.Add('ГЛАВНОЕ УЗКОЕ МЕСТО: системный HDD. Проверьте его состояние и возможность установки SSD.')
        } elseif ([string]$h.DiskType -notmatch '^SSD$') {
            $result.Add('Тип системного диска неизвестен. Уточните HDD/SSD по модели накопителя.')
        }
        if ([double]$h.MemoryGb -le 4) {
            $result.Add('ОЗУ 4 ГБ или меньше. Проверьте совместимость ноутбука с 8 ГБ ОЗУ.')
        }
        if ([double]$h.TotalGb -gt 0 -and (([double]$h.FreeGb -lt 15) -or ([double]$h.FreeGb / [double]$h.TotalGb -lt 0.10))) {
            $result.Add('На системном диске мало места. Освободите пространство без удаления личных данных.')
        }
        if ([string]$h.Windows -match 'Windows 10') {
            $result.Add('Обычная поддержка Windows 10 завершилась 14.10.2025. Проверьте доступные обновления безопасности и варианты ОС.')
        }
        if ([string]$h.CPU -match 'Celeron|Pentium|Atom') {
            $result.Add('Процессор начального уровня. Программная очистка не увеличит мощность CPU; уменьшите количество вкладок.')
        }
    }
    if (@($Snapshot.Boot).Count -gt 0 -and $null -ne $Snapshot.Boot[0].Seconds -and [double]$Snapshot.Boot[0].Seconds -ge 120) {
        $result.Add('Последняя зарегистрированная загрузка Windows дольше двух минут. Сравните этапы загрузки.')
    }
    if (@($Snapshot.Startup).Count -ge 10) {
        $result.Add('Много записей автозагрузки. Проверьте элементы через системные настройки Windows.')
    }
    if (@($Snapshot.DriverProblems).Count -gt 0) {
        $result.Add('Есть устройства с ошибками PnP. Проверьте драйверы через Windows Update и сайт производителя.')
    }
    if ($null -ne $Snapshot.Defender -and $Snapshot.Defender.Available -and -not $Snapshot.Defender.Realtime) {
        $result.Add('Defender в реальном времени выключен. Возможно, работает другой антивирус; проверьте Защиту Windows.')
    }
    if ($result.Count -eq 0) {
        $result.Add('Явной причины по данным Windows нет. Проверьте температуру, состояние диска и нагрузку на CPU/ОЗУ.')
    }
    @($result.ToArray())
}

function New-TurboSnapshot {
    $hw = $null
    $errorText = ''
    try { $hw = Get-TurboHardware } catch { $errorText = "Не удалось прочитать оборудование: $($_.Exception.Message)" }
    $snapshot = [pscustomobject]@{
        CollectedAt = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        Hardware = $hw
        Boot = @(Get-TurboBootEvents)
        Startup = @(Get-TurboStartup)
        DriverProblems = @(Get-TurboDriverProblems)
        Software = @(Get-TurboSoftware)
        Processes = @(Get-TurboHeavyProcesses)
        ServiceAudit = @(Get-TurboServiceAudit)
        Defender = (Get-TurboDefender)
        Recommendations = @()
        Error = $errorText
    }
    $snapshot.Recommendations = @(Get-TurboRecommendations -Snapshot $snapshot)
    return $snapshot
}

function Get-TurboTempCandidates {
    [CmdletBinding()]
    param([ValidateRange(24,720)][int]$MinimumAgeHours = 48, [ValidateRange(1,50000)][int]$Limit = 20000)
    if ([string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) { throw 'LOCALAPPDATA не задан.' }
    $userBase = [IO.Path]::GetFullPath($env:LOCALAPPDATA).TrimEnd('\')
    $root = [IO.Path]::GetFullPath((Join-Path $userBase 'Temp')).TrimEnd('\')
    if (-not $root.StartsWith(($userBase + '\'), [StringComparison]::OrdinalIgnoreCase)) { throw 'Небезопасный путь временного каталога.' }
    $list = New-Object 'System.Collections.Generic.List[object]'
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
        return [pscustomobject]@{ Root=$root; Files=@(); Count=0; Bytes=0; Truncated=$false }
    }
    $rootItem = Get-Item -LiteralPath $root -Force -ErrorAction Stop
    if (($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'Temp является ссылкой; очистка запрещена.' }
    $cutoff = (Get-Date).AddHours(-$MinimumAgeHours)
    $stack = New-Object System.Collections.Stack
    $stack.Push($rootItem)
    $total = [int64]0
    $truncated = $false
    while ($stack.Count -gt 0) {
        $folder = $stack.Pop()
        foreach ($entry in @(Get-ChildItem -LiteralPath $folder.FullName -Force -ErrorAction SilentlyContinue)) {
            if (($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { continue }
            if ($entry.PSIsContainer) { $stack.Push($entry); continue }
            if ($entry.LastWriteTime -ge $cutoff) { continue }
            if (-not $entry.FullName.StartsWith(($root + '\'), [StringComparison]::OrdinalIgnoreCase)) { continue }
            if ($list.Count -ge $Limit) { $truncated = $true; break }
            $list.Add([pscustomobject]@{ Path=[string]$entry.FullName; Bytes=[int64]$entry.Length })
            $total += [int64]$entry.Length
        }
        if ($truncated) { break }
    }
    [pscustomobject]@{ Root=$root; Files=@($list.ToArray()); Count=$list.Count; Bytes=$total; Truncated=$truncated }
}

function Clear-TurboTemp {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]$Preview)
    $root = [IO.Path]::GetFullPath([string]$Preview.Root).TrimEnd('\')
    $expected = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'Temp')).TrimEnd('\')
    if (-not $root.Equals($expected, [StringComparison]::OrdinalIgnoreCase)) { throw 'Папка очистки не соответствует разрешённой папке.' }
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
        return [pscustomobject]@{ Deleted=0; Failed=0; FreedBytes=[int64]0 }
    }
    if ((Get-Item -LiteralPath $root -Force -ErrorAction Stop).Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw 'Ссылка на каталог Temp: очистка запрещена.'
    }
    $deleted = 0
    $failed = 0
    $freed = [int64]0
    foreach ($entry in @($Preview.Files)) {
        $path = [IO.Path]::GetFullPath([string]$entry.Path)
        if (-not $path.StartsWith(($root + '\'), [StringComparison]::OrdinalIgnoreCase)) { $failed++; continue }
        try {
            $item = Get-Item -LiteralPath $path -Force -ErrorAction Stop
            if ($item.PSIsContainer -or (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) { $failed++; continue }
            if ($item.LastWriteTime -gt (Get-Date).AddHours(-48)) { $failed++; continue }
            Remove-Item -LiteralPath $path -Force -ErrorAction Stop
            $freed += [int64]$entry.Bytes
            $deleted++
        } catch { $failed++ }
    }
    [pscustomobject]@{ Deleted=$deleted; Failed=$failed; FreedBytes=$freed }
}

Export-ModuleMember -Function Get-TurboHardware,Get-TurboBootEvents,Get-TurboStartup,Get-TurboDriverProblems,Get-TurboDefender,Get-TurboSoftware,Get-TurboHeavyProcesses,Get-TurboServiceAudit,Get-TurboRecommendations,New-TurboSnapshot,Get-TurboTempCandidates,Clear-TurboTemp
