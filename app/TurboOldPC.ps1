$ErrorActionPreference = 'Stop'
if ([Threading.Thread]::CurrentThread.GetApartmentState() -ne [Threading.ApartmentState]::STA) {
    throw 'Запускайте через Start.cmd (режим STA).'
}
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
 xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
 Title="Turbo Old PC — диагностика и ускорение" Width="1010" Height="720"
 MinWidth="780" MinHeight="570" WindowStartupLocation="CenterScreen"
 Background="#F6F8FC" FontFamily="Segoe UI" FontSize="14" Foreground="#203044">
 <Window.Resources>
  <Style TargetType="Button">
   <Setter Property="Background" Value="#205FCC"/>
   <Setter Property="Foreground" Value="White"/>
   <Setter Property="BorderThickness" Value="0"/>
   <Setter Property="Padding" Value="14,9"/>
   <Setter Property="Margin" Value="0,0,8,0"/>
   <Setter Property="MinHeight" Value="37"/>
   <Setter Property="Cursor" Value="Hand"/>
   <Style.Triggers>
    <Trigger Property="IsMouseOver" Value="True">
     <Setter Property="Background" Value="#174B9E"/>
    </Trigger>
    <Trigger Property="IsEnabled" Value="False">
     <Setter Property="Background" Value="#9BAAC0"/>
    </Trigger>
   </Style.Triggers>
  </Style>
  <Style TargetType="TabItem">
   <Setter Property="Padding" Value="13,9"/>
  </Style>
  <Style TargetType="DataGrid">
   <Setter Property="Background" Value="White"/>
   <Setter Property="IsReadOnly" Value="True"/>
   <Setter Property="AutoGenerateColumns" Value="True"/>
   <Setter Property="CanUserAddRows" Value="False"/>
   <Setter Property="EnableRowVirtualization" Value="True"/>
  </Style>
 </Window.Resources>
 <Grid Margin="18">
  <Grid.RowDefinitions>
   <RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/>
  </Grid.RowDefinitions>
  <Border Background="#142C53" CornerRadius="12" Padding="20,16" Margin="0,0,0,14">
   <Grid>
    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
    <StackPanel>
     <TextBlock Text="TURBO OLD PC" Foreground="White" FontWeight="Bold" FontSize="26"/>
     <TextBlock Text="Причины торможения, безопасная очистка и официальные драйверы"
                Foreground="#D5E4FF" Margin="0,4,0,0"/>
    </StackPanel>
    <Button x:Name="BtnAnalyze" Grid.Column="1" VerticalAlignment="Center" Content="Проверить компьютер"/>
   </Grid>
  </Border>
  <TabControl Grid.Row="1">
   <TabItem Header="Обзор">
    <Grid Margin="13">
     <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
     <TextBlock FontWeight="SemiBold" Margin="0,0,0,9" Text="Характеристики, загрузка Windows и рекомендации"/>
     <TextBox x:Name="OverviewText" Grid.Row="1" Background="White" IsReadOnly="True"
         Padding="13" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" FontSize="13"/>
     <WrapPanel Grid.Row="2" Margin="0,11,0,0">
      <Button x:Name="BtnReport" Content="Сохранить отчёт"/>
      <Button x:Name="BtnReportsFolder" Content="Папка отчётов"/>
     </WrapPanel>
    </Grid>
   </TabItem>
   <TabItem Header="Автозагрузка">
    <Grid Margin="13">
     <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
     <TextBlock TextWrapping="Wrap" Margin="0,0,0,9"
                Text="Просмотрите элементы автозапуска. Отключайте только известные вам необязательные приложения."/>
     <DataGrid x:Name="StartupGrid" Grid.Row="1"/>
     <Button x:Name="BtnStartupSettings" Grid.Row="2" HorizontalAlignment="Left" Margin="0,11,0,0"
             Content="Настройки автозагрузки Windows"/>
    </Grid>
   </TabItem>
   <TabItem Header="Драйверы">
    <Grid Margin="13">
     <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
     <TextBlock TextWrapping="Wrap" Margin="0,0,0,9"
                Text="Показаны устройства с кодами ошибок Windows. Для проверки актуальности драйверов используйте Windows Update или производителя."/>
     <DataGrid x:Name="DriversGrid" Grid.Row="1"/>
     <WrapPanel Grid.Row="2" Margin="0,11,0,0">
      <Button x:Name="BtnDriversUpdate" Content="Windows Update"/>
      <Button x:Name="BtnOemSupport" Content="Сайт производителя"/>
      <Button x:Name="BtnDeviceManager" Content="Диспетчер устройств"/>
     </WrapPanel>
    </Grid>
   </TabItem>
   <TabItem Header="Программы">
    <Grid Margin="13">
     <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
     <TextBlock TextWrapping="Wrap" Margin="0,0,0,9"
                Text="Установленные программы. Утилита не удаляет подозрительное ПО по названию: так можно ошибочно удалить нужное."/>
     <DataGrid x:Name="SoftwareGrid" Grid.Row="1"/>
     <Button x:Name="BtnAppsSettings" Grid.Row="2" Margin="0,11,0,0" HorizontalAlignment="Left"
             Content="Удаление приложений Windows"/>
    </Grid>
   </TabItem>
   <TabItem Header="Очистка">
    <StackPanel Margin="17">
     <TextBlock Text="Временные файлы пользователя" FontSize="19" FontWeight="SemiBold"/>
     <TextBlock TextWrapping="Wrap" Margin="0,11,0,14"
                Text="Только файлы старше 48 часов в AppData\Local\Temp. Не трогаем системные папки, документы, браузеры и реестр. Удаление необратимо."/>
     <WrapPanel>
      <Button x:Name="BtnTempPreview" Content="1. Оценить объём"/>
      <Button x:Name="BtnTempClean" Content="2. Удалить после подтверждения" IsEnabled="False"/>
     </WrapPanel>
     <TextBox x:Name="CleanupText" IsReadOnly="True" Background="White" Margin="0,15,0,0"
         MinHeight="180" Padding="13" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"
         Text="Сначала нажмите «Оценить объём». Ничего не удалено."/>
    </StackPanel>
   </TabItem>
   <TabItem Header="Антивирус">
    <StackPanel Margin="17">
     <TextBlock Text="Microsoft Defender" FontSize="19" FontWeight="SemiBold"/>
     <TextBlock TextWrapping="Wrap" Margin="0,11,0,14"
                Text="Используем официальный антивирус Windows. Если активна другая защита, проверьте компьютер через неё. Сканирование может временно нагружать слабый ноутбук."/>
     <WrapPanel>
      <Button x:Name="BtnScan" Content="Обновить базы и проверить"/>
      <Button x:Name="BtnWindowsSecurity" Content="Открыть Защиту Windows"/>
     </WrapPanel>
     <TextBox x:Name="SecurityText" IsReadOnly="True" Background="White" Margin="0,15,0,0"
         MinHeight="180" Padding="13" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"
         Text="Найденные угрозы и история лечения доступны в приложении «Безопасность Windows»."/>
    </StackPanel>
   </TabItem>
  </TabControl>
  <Border Grid.Row="2" Background="#E6EEF9" Padding="10,8" CornerRadius="7" Margin="0,13,0,0">
   <TextBlock x:Name="StatusText" Text="Начальная проверка готовится" FontSize="12" TextWrapping="Wrap"/>
  </Border>
 </Grid>
</Window>
'@
$reader = New-Object System.Xml.XmlNodeReader $xaml
$script:window = [Windows.Markup.XamlReader]::Load($reader)
$script:ui = @{}
foreach ($name in @('BtnAnalyze','OverviewText','BtnReport','BtnReportsFolder','StartupGrid',
    'BtnStartupSettings','DriversGrid','BtnDriversUpdate','BtnOemSupport','BtnDeviceManager',
    'SoftwareGrid','BtnAppsSettings','BtnTempPreview','BtnTempClean','CleanupText',
    'BtnScan','BtnWindowsSecurity','SecurityText','StatusText')) {
    $script:ui[$name] = $script:window.FindName($name)
    if ($null -eq $script:ui[$name]) { throw "Не найден элемент окна: $name" }
}
$script:lastSnapshot = $null
$script:activeProcess = $null
$script:activeOp = ''
$script:activeResultPath = ''
$script:tempPreviewDone = $false
$script:appDataDir = Join-Path $env:LOCALAPPDATA 'TurboOldPC'
$script:reportsDir = Join-Path $script:appDataDir 'Reports'
$script:jobsDir = Join-Path $script:appDataDir 'Jobs'
[void][IO.Directory]::CreateDirectory($script:reportsDir)
[void][IO.Directory]::CreateDirectory($script:jobsDir)

function Set-TurboStatus([string]$message) { $script:ui['StatusText'].Text = $message }
function Show-TurboError([string]$message) {
    [void][System.Windows.MessageBox]::Show($script:window, $message, 'Turbo Old PC', 'OK', 'Warning')
}
function Open-TurboShell([string]$target, [string]$fallback = '') {
    try { Start-Process -FilePath $target -ErrorAction Stop }
    catch {
        if ($fallback) {
            try { Start-Process -FilePath $fallback -ErrorAction Stop }
            catch { Show-TurboError "Не удалось открыть настройки: $($_.Exception.Message)" }
        } else { Show-TurboError "Не удалось открыть: $($_.Exception.Message)" }
    }
}
function Get-TurboOemUrl {
    if ($null -eq $script:lastSnapshot -or $null -eq $script:lastSnapshot.Hardware) { return '' }
    $maker = [string]$script:lastSnapshot.Hardware.Manufacturer
    switch -Regex ($maker) {
        'Acer' { return 'https://www.acer.com/support/drivers-and-manuals' }
        'Lenovo' { return 'https://pcsupport.lenovo.com/' }
        'Dell' { return 'https://www.dell.com/support/home/' }
        'HP|Hewlett' { return 'https://support.hp.com/drivers' }
        'ASUS|ASUSTeK' { return 'https://www.asus.com/support/Download-Center/' }
        'MSI|Micro-Star' { return 'https://www.msi.com/support' }
        default { return '' }
    }
}
function Format-TurboReport($snap) {
    $lines = New-Object 'System.Collections.Generic.List[string]'
    $lines.Add('TURBO OLD PC — ОТЧЁТ')
    $lines.Add('Дата: ' + [string]$snap.CollectedAt)
    $lines.Add(('=' * 50))
    if ($null -ne $snap.Hardware) {
        $h = $snap.Hardware
        $lines.Add('Ноутбук: ' + $h.Manufacturer + ' ' + $h.Model)
        $lines.Add('CPU: ' + $h.CPU + '; ядра: ' + $h.Cores)
        $lines.Add('RAM: ' + $h.MemoryGb + ' ГБ')
        $lines.Add('ОС: ' + $h.Windows + ' ' + $h.Version)
        $lines.Add('Системный накопитель: ' + $h.Disk + ' / ' + $h.DiskType + ' / ' + $h.DiskBus)
        $lines.Add('Свободно на ' + $h.SystemDrive + ': ' + $h.FreeGb + ' из ' + $h.TotalGb + ' ГБ')
    } else { $lines.Add('Характеристики недоступны: ' + $snap.Error) }
    $lines.Add('')
    $lines.Add('ПОСЛЕДНИЕ ЗАГРУЗКИ WINDOWS:')
    if (@($snap.Boot).Count -eq 0) { $lines.Add('Журнал событий не дал данных.') }
    foreach ($b in @($snap.Boot)) {
        $lines.Add(('{0}: {1} с; основной этап {2} с; после рабочего стола {3} с' -f
            $b.Date, $b.Seconds, $b.MainSeconds, $b.PostSeconds))
    }
    $lines.Add('')
    $lines.Add('MICROSOFT DEFENDER:')
    if ($null -ne $snap.Defender) {
        $mp = $snap.Defender
        $lines.Add("Доступен: $($mp.Available), включён: $($mp.Enabled), защита реального времени: $($mp.Realtime), базы: $($mp.Updated)")
    }
    $lines.Add('')
    $lines.Add('ЧТО СДЕЛАТЬ:')
    foreach ($x in @($snap.Recommendations)) { $lines.Add('• ' + [string]$x) }
    $lines.Add('')
    $lines.Add('АВТОЗАГРУЗКА:')
    foreach ($x in @($snap.Startup)) { $lines.Add("$($x.Name) | $($x.Command) | $($x.Location)") }
    $lines.Add('')
    $lines.Add('ОШИБКИ УСТРОЙСТВ:')
    foreach ($x in @($snap.DriverProblems)) { $lines.Add("$($x.Name) | код $($x.Code) | $($x.DeviceId)") }
    $lines.Add('')
    $lines.Add('УСТАНОВЛЕННОЕ ПО:')
    foreach ($x in @($snap.Software)) { $lines.Add("$($x.Name) | $($x.Publisher)") }
    $lines.Add('')
    $lines.Add('Отчёт хранится только локально и может содержать персональные пути и идентификаторы устройств.')
    return [string]::Join([Environment]::NewLine, $lines.ToArray())
}
function Show-TurboSnapshot($snap) {
    $script:lastSnapshot = $snap
    $script:ui['OverviewText'].Text = Format-TurboReport $snap
    $script:ui['StartupGrid'].ItemsSource = @($snap.Startup)
    $script:ui['DriversGrid'].ItemsSource = @($snap.DriverProblems)
    $script:ui['SoftwareGrid'].ItemsSource = @($snap.Software)
}
function Start-TurboWorker([string]$operation, [string]$relativeFile, [string]$extraParams = '') {
    if ($null -ne $script:activeProcess -and -not $script:activeProcess.HasExited) {
        Show-TurboError 'Дождитесь завершения текущей операции.'
        return
    }
    try {
        $file = Join-Path $PSScriptRoot $relativeFile
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Нет рабочего скрипта: $file" }
        $output = Join-Path $script:jobsDir (([guid]::NewGuid().ToString('N')) + '.json')
        $command = "& '" + $file.Replace("'","''") + "' -OutputPath '" + $output.Replace("'","''") + "' " + $extraParams
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
        $script:activeProcess = Start-Process -FilePath (Join-Path $PSHOME 'powershell.exe') -ArgumentList @(
            '-NoLogo','-NoProfile','-NonInteractive','-EncodedCommand',$encoded
        ) -WindowStyle Hidden -PassThru -ErrorAction Stop
        $script:activeOp = $operation
        $script:activeResultPath = $output
        Set-TurboStatus ("Выполняется: $operation. Окно остаётся доступным.")
        $script:timer.Start()
    } catch { Show-TurboError "Не удалось запустить: $($_.Exception.Message)" }
}
$script:timer = New-Object System.Windows.Threading.DispatcherTimer
$script:timer.Interval = [TimeSpan]::FromMilliseconds(800)
$script:timer.Add_Tick({
    if ($null -eq $script:activeProcess -or -not $script:activeProcess.HasExited) { return }
    $script:timer.Stop()
    $operation = $script:activeOp
    $resultPath = $script:activeResultPath
    $exitCode = $script:activeProcess.ExitCode
    $script:activeProcess.Dispose()
    $script:activeProcess = $null
    $script:activeOp = ''
    $script:activeResultPath = ''
    try {
        if (-not (Test-Path -LiteralPath $resultPath -PathType Leaf)) {
            throw "Процесс завершился с кодом $exitCode, но не создал результат."
        }
        $result = Get-Content -LiteralPath $resultPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        Remove-Item -LiteralPath $resultPath -Force -ErrorAction SilentlyContinue
        if (-not $result.Success) { throw ([string]$result.Message) }
        switch ($operation) {
            'Диагностика' {
                Show-TurboSnapshot $result.Snapshot
                Set-TurboStatus 'Диагностика завершена. Посмотрите рекомендации.'
            }
            'Оценка очистки' {
                $mb = [math]::Round(([double]$result.Bytes / 1MB),1)
                $note = if ($result.Truncated) { 'Достигнут предел 20 000 файлов, оценка неполная.' } else { '' }
                $script:ui['CleanupText'].Text = [string]::Join([Environment]::NewLine, @(
                    "Папка: $($result.Root)", "Подходящих файлов: $($result.Count)", "Объём: $mb МБ", $note
                ))
                $script:tempPreviewDone = ([int]$result.Count -gt 0)
                $script:ui['BtnTempClean'].IsEnabled = $script:tempPreviewDone
                Set-TurboStatus 'Оценка готова. Для удаления потребуется подтверждение.'
            }
            'Очистка' {
                $mb = [math]::Round(([double]$result.Bytes / 1MB),1)
                $script:ui['CleanupText'].Text = [string]::Join([Environment]::NewLine, @(
                    "Удалено файлов: $($result.Count)", "Пропущено: $($result.Failed)", "Освобождено: $mb МБ"
                ))
                $script:tempPreviewDone = $false
                $script:ui['BtnTempClean'].IsEnabled = $false
                Set-TurboStatus 'Очистка завершена.'
            }
            'Антивирус' {
                $script:ui['SecurityText'].Text = [string]$result.Message
                Set-TurboStatus 'Команда Defender выполнена. Проверьте журнал Защиты Windows.'
            }
        }
    } catch {
        $message = [string]$_.Exception.Message
        if ($operation -eq 'Антивирус') { $script:ui['SecurityText'].Text = $message }
        if ($operation -eq 'Оценка очистки') { $script:ui['BtnTempClean'].IsEnabled = $false }
        Set-TurboStatus ("Ошибка «$operation»: $message")
        Show-TurboError $message
    }
})
$script:ui['BtnAnalyze'].Add_Click({ Start-TurboWorker 'Диагностика' 'Workers\Diagnostics.ps1' })
$script:ui['BtnTempPreview'].Add_Click({
    $script:ui['BtnTempClean'].IsEnabled = $false
    Start-TurboWorker 'Оценка очистки' 'Workers\Cleanup.ps1' '-Mode Preview'
})
$script:ui['BtnTempClean'].Add_Click({
    if (-not $script:tempPreviewDone) { return }
    $choice = [System.Windows.MessageBox]::Show($script:window,
        'Удалить старые файлы из пользовательской папки Temp? Отменить удаление нельзя.',
        'Подтверждение', 'YesNo', 'Warning')
    if ($choice -eq [System.Windows.MessageBoxResult]::Yes) {
        Start-TurboWorker 'Очистка' 'Workers\Cleanup.ps1' '-Mode Cleanup'
    }
})
$script:ui['BtnScan'].Add_Click({
    $script:ui['SecurityText'].Text = 'Запущена проверка. На старом HDD это может занять длительное время.'
    Start-TurboWorker 'Антивирус' 'Workers\DefenderScan.ps1'
})
$script:ui['BtnStartupSettings'].Add_Click({ Open-TurboShell 'ms-settings:startupapps' 'taskmgr.exe' })
$script:ui['BtnAppsSettings'].Add_Click({ Open-TurboShell 'ms-settings:appsfeatures' 'appwiz.cpl' })
$script:ui['BtnDriversUpdate'].Add_Click({ Open-TurboShell 'ms-settings:windowsupdate-optionalupdates' 'ms-settings:windowsupdate' })
$script:ui['BtnDeviceManager'].Add_Click({ Open-TurboShell 'devmgmt.msc' })
$script:ui['BtnWindowsSecurity'].Add_Click({ Open-TurboShell 'windowsdefender:' 'ms-settings:windowsdefender' })
$script:ui['BtnOemSupport'].Add_Click({
    $link = Get-TurboOemUrl
    if (-not $link) { Show-TurboError 'Нет подтверждённой ссылки для этого производителя. Найдите драйверы по точной модели на его официальном сайте.' }
    else { Open-TurboShell $link }
})
$script:ui['BtnReport'].Add_Click({
    if ($null -eq $script:lastSnapshot) { Show-TurboError 'Сначала выполните диагностику.'; return }
    try {
        $path = Join-Path $script:reportsDir ('TurboOldPC-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.txt')
        [IO.File]::WriteAllText($path, (Format-TurboReport $script:lastSnapshot), (New-Object System.Text.UTF8Encoding($true)))
        Set-TurboStatus "Отчёт сохранён: $path"
        [void][System.Windows.MessageBox]::Show($script:window, "Отчёт сохранён: $path", 'Turbo Old PC')
    } catch { Show-TurboError "Не удалось сохранить отчёт: $($_.Exception.Message)" }
})
$script:ui['BtnReportsFolder'].Add_Click({ Open-TurboShell $script:reportsDir })
$script:window.Add_ContentRendered({ Start-TurboWorker 'Диагностика' 'Workers\Diagnostics.ps1' })
[void]$script:window.ShowDialog()
