Set-StrictMode -Version 2.0
# Read-only checks. Never interpret these findings as proof that malware is absent.
function Get-TurboSecurityAudit {
    $findings = New-Object 'System.Collections.Generic.List[object]'
    function Add-Finding([string]$area,[string]$status,[string]$detail,[string]$action) {
        $findings.Add([pscustomobject]@{Area=$area;Status=$status;Detail=$detail;Action=$action})
    }
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        if ([string]$os.Caption -match 'Windows 10') {
            Add-Finding 'Поддержка ОС' 'Внимание' 'Стандартная поддержка Windows 10 закончилась 14.10.2025; статус ESU не определён.' 'Проверьте участие в ESU или поддержку ОС.'
        } else {
            Add-Finding 'Поддержка ОС' 'Информация' ([string]$os.Caption) 'Проверяйте обновления в Windows Update.'
        }
    } catch { Add-Finding 'Поддержка ОС' 'Неизвестно' $_.Exception.Message 'Проверьте версию Windows.' }
    try {
        $profiles = @(Get-NetFirewallProfile -ErrorAction Stop)
        foreach ($p in $profiles) {
            Add-Finding ('Брандмауэр: '+$p.Name) $(if($p.Enabled){'ОК'}else{'Внимание'}) $(if($p.Enabled){'Включён'}else{'Отключён'}) 'Проверьте параметры брандмауэра Windows.'
        }
    } catch { Add-Finding 'Брандмауэр' 'Неизвестно' $_.Exception.Message 'Откройте Защиту Windows.' }
    try {
        $status = Get-MpComputerStatus -ErrorAction Stop
        Add-Finding 'Microsoft Defender' $(if($status.AntivirusEnabled -and $status.RealTimeProtectionEnabled){'ОК'}else{'Проверить'}) (
            "Антивирус: $($status.AntivirusEnabled); защита реального времени: $($status.RealTimeProtectionEnabled); сигнатуры: $($status.AntivirusSignatureLastUpdated)"
        ) 'Проверьте активный антивирус. Другой продукт может отключать Defender.'
    } catch { Add-Finding 'Microsoft Defender' 'Неизвестно' 'Статус недоступен или используется другой антивирус.' 'Откройте Безопасность Windows.' }
    try {
        $pref = Get-MpPreference -ErrorAction Stop
        $cfa = [string]$pref.EnableControlledFolderAccess
        $network = [string]$pref.EnableNetworkProtection
        Add-Finding 'Защита от вымогателей' $(if($cfa -match '^(Enabled|1)$'){'ОК'}else{'Проверить'}) (
            "Контролируемый доступ к папкам: $cfa"
        ) 'Откройте защиту от программ-вымогателей; включение может блокировать законные приложения.'
        Add-Finding 'Сетевая защита Defender' $(if($network -match '^(Enabled|1)$'){'ОК'}else{'Информация'}) (
            "Настройка сетевой защиты: $network"
        ) 'Настраивается отдельно; доступность зависит от выпуска Windows и политик.'
    } catch { Add-Finding 'Defender: усиленная защита' 'Неизвестно' 'Политики защиты не прочитаны.' 'Проверьте настройки Defender.' }
    try {
        $uac = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA -ErrorAction Stop
        Add-Finding 'Контроль учётных записей (UAC)' $(if($uac.EnableLUA -eq 1){'ОК'}else{'Критично'}) (
            "EnableLUA = $($uac.EnableLUA)"
        ) 'Не отключайте контроль учётных записей.'
    } catch { Add-Finding 'UAC' 'Неизвестно' 'Не удалось прочитать настройку.' 'Откройте настройки UAC.' }
    try {
        $smb = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction Stop
        Add-Finding 'Устаревший SMBv1' $(if($smb.State -eq 'Enabled'){'Внимание'}else{'ОК'}) (
            "Состояние компонента: $($smb.State)"
        ) 'При необходимости отключайте в компонентах Windows; старые сетевые устройства могут перестать работать.'
    } catch { Add-Finding 'Устаревший SMBv1' 'Неизвестно' 'Состояние недоступно без повышения прав или компонент отсутствует.' 'Проверьте компоненты Windows.' }
    try {
        $rdp = Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -ErrorAction Stop
        Add-Finding 'Удалённый рабочий стол' $(if($rdp.fDenyTSConnections -eq 1){'ОК'}else{'Проверить'}) (
            $(if($rdp.fDenyTSConnections -eq 1){'Входящие RDP-подключения запрещены.'}else{'RDP разрешён. Не обязательно уязвимость, но проверьте необходимость и правила доступа.'})
        ) 'Не открывайте RDP в интернет; используйте MFA/VPN и обновления.'
    } catch { Add-Finding 'Удалённый рабочий стол' 'Неизвестно' 'Состояние не прочитано.' 'Проверьте системные настройки.' }
    try {
        $ua = Get-CimInstance Win32_Service -Filter "Name='wuauserv'" -ErrorAction Stop
        if ($null -ne $ua) {
            Add-Finding 'Служба Windows Update' $(if($ua.StartMode -eq 'Disabled'){'Внимание'}else{'ОК'}) (
                "Запуск: $($ua.StartMode), состояние: $($ua.State)"
            ) 'Проверьте Windows Update. Остановка службы в данный момент не равна отключению обновлений.'
        }
    } catch { Add-Finding 'Windows Update' 'Неизвестно' 'Не удалось получить статус.' 'Откройте Центр обновления Windows.' }
    try {
        $hotfixes = @(Get-HotFix -ErrorAction Stop |
            Where-Object { $null -ne $_.InstalledOn } | Sort-Object InstalledOn -Descending |
            Select-Object -First 1)
        if ($hotfixes.Count -gt 0) {
            Add-Finding 'Последний учтённый патч' 'Информация' (
                "$($hotfixes[0].HotFixID): $($hotfixes[0].InstalledOn)"
            ) 'Список Get-HotFix неполный; реальное наличие обновлений проверьте в Windows Update.'
        }
    } catch { }
    return @($findings.ToArray())
}
Export-ModuleMember -Function Get-TurboSecurityAudit
