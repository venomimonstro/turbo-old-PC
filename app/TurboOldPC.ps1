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
 Title="Turbo Old PC — бесплатная защита и ускорение" Width="1120" Height="755"
 MinWidth="920" MinHeight="590" WindowStartupLocation="CenterScreen"
 Background="#F4F7F8" FontFamily="Segoe UI" FontSize="14" Foreground="#1D3344">
 <Window.Resources>
  <Style TargetType="Button" x:Key="ActionButton">
   <Setter Property="Background" Value="#08A878"/>
   <Setter Property="Foreground" Value="White"/>
   <Setter Property="FontWeight" Value="SemiBold"/>
   <Setter Property="BorderThickness" Value="0"/>
   <Setter Property="Padding" Value="17,10"/>
   <Setter Property="Margin" Value="0,0,9,8"/>
   <Setter Property="MinHeight" Value="41"/>
   <Setter Property="Cursor" Value="Hand"/>
   <Setter Property="Template">
    <Setter.Value>
     <ControlTemplate TargetType="Button">
      <Border x:Name="BtnBorder" Background="{TemplateBinding Background}" CornerRadius="8" Padding="{TemplateBinding Padding}">
       <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
      </Border>
      <ControlTemplate.Triggers>
       <Trigger Property="IsMouseOver" Value="True">
        <Setter TargetName="BtnBorder" Property="Background" Value="#058D67"/>
       </Trigger>
       <Trigger Property="IsEnabled" Value="False">
        <Setter TargetName="BtnBorder" Property="Background" Value="#9EACB1"/>
       </Trigger>
      </ControlTemplate.Triggers>
     </ControlTemplate>
    </Setter.Value>
   </Setter>
  </Style>
  <Style TargetType="Button" x:Key="SideButton">
   <Setter Property="Background" Value="Transparent"/>
   <Setter Property="Foreground" Value="#D9ECE8"/>
   <Setter Property="BorderThickness" Value="0"/>
   <Setter Property="HorizontalContentAlignment" Value="Left"/>
   <Setter Property="Padding" Value="17,13"/>
   <Setter Property="Margin" Value="10,2"/>
   <Setter Property="Cursor" Value="Hand"/>
   <Setter Property="FontSize" Value="14"/>
   <Setter Property="Template">
    <Setter.Value>
     <ControlTemplate TargetType="Button">
      <Border x:Name="SideBorder" Background="{TemplateBinding Background}" CornerRadius="8" Padding="{TemplateBinding Padding}">
       <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}"/>
      </Border>
      <ControlTemplate.Triggers>
       <Trigger Property="IsMouseOver" Value="True">
        <Setter TargetName="SideBorder" Property="Background" Value="#244F4D"/>
       </Trigger>
      </ControlTemplate.Triggers>
     </ControlTemplate>
    </Setter.Value>
   </Setter>
  </Style>
  <Style TargetType="Border" x:Key="PanelBorder">
   <Setter Property="Background" Value="White"/>
   <Setter Property="CornerRadius" Value="12"/>
   <Setter Property="Padding" Value="18"/>
  </Style>
  <Style TargetType="DataGrid">
   <Setter Property="Background" Value="White"/>
   <Setter Property="BorderThickness" Value="0"/>
   <Setter Property="IsReadOnly" Value="True"/>
   <Setter Property="AutoGenerateColumns" Value="True"/>
   <Setter Property="CanUserAddRows" Value="False"/>
   <Setter Property="CanUserDeleteRows" Value="False"/>
   <Setter Property="EnableRowVirtualization" Value="True"/>
   <Setter Property="HeadersVisibility" Value="Column"/>
   <Setter Property="GridLinesVisibility" Value="Horizontal"/>
  </Style>
  <Style TargetType="TextBox">
   <Setter Property="BorderBrush" Value="#DEE6E8"/>
   <Setter Property="BorderThickness" Value="1"/>
   <Setter Property="Padding" Value="12"/>
  </Style>
 </Window.Resources>
 <Grid>
  <Grid.ColumnDefinitions>
   <ColumnDefinition Width="225"/>
   <ColumnDefinition Width="*"/>
  </Grid.ColumnDefinitions>
  <Border Grid.Column="0" Background="#173B3E">
   <Grid>
    <Grid.RowDefinitions>
     <RowDefinition Height="Auto"/>
     <RowDefinition Height="*"/>
     <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>
    <StackPanel Grid.Row="0" Margin="24,27,12,31">
     <StackPanel Orientation="Horizontal">
      <Border Width="44" Height="44" CornerRadius="13" Background="#07B587" Margin="0,0,11,0">
       <TextBlock Text="T" FontWeight="Bold" Foreground="White" FontSize="27" VerticalAlignment="Center" HorizontalAlignment="Center"/>
      </Border>
      <StackPanel VerticalAlignment="Center">
       <TextBlock Text="TURBO" FontSize="21" FontWeight="Bold" Foreground="White"/>
       <TextBlock Text="OLD PC" FontSize="12" FontWeight="SemiBold" Foreground="#87D6C6"/>
      </StackPanel>
     </StackPanel>
     <TextBlock Text="Бесплатный помощник для Windows" TextWrapping="Wrap"
      Foreground="#BED5D2" FontSize="11" Margin="0,15,0,0"/>
    </StackPanel>
    <StackPanel Grid.Row="1">
     <Button x:Name="NavHome" Style="{StaticResource SideButton}" Content="⌂   Главная"/>
     <Button x:Name="NavSecurity" Style="{StaticResource SideButton}" Content="✚   Антивирус"/>
     <Button x:Name="NavCleanup" Style="{StaticResource SideButton}" Content="◈   Очистка"/>
     <Button x:Name="NavStartup" Style="{StaticResource SideButton}" Content="↗   Автозагрузка"/>
     <Button x:Name="NavPerformance" Style="{StaticResource SideButton}" Content="▤   Производительность"/>
     <Button x:Name="NavDrivers" Style="{StaticResource SideButton}" Content="⚙   Драйверы"/>
     <Button x:Name="NavApps" Style="{StaticResource SideButton}" Content="▦   Программы"/>
     <Button x:Name="NavAudit" Style="{StaticResource SideButton}" Content="◉   Уязвимости"/>
     <Button x:Name="NavBoost" Style="{StaticResource SideButton}" Content="⚡   Турбо-режим"/>
     <Button x:Name="NavRepair" Style="{StaticResource SideButton}" Content="✚   Починка Windows"/>
    </StackPanel>
    <StackPanel Grid.Row="2" Margin="22,0,15,22">
     <Border Height="1" Background="#3A6765" Margin="0,0,0,15"/>
     <TextBlock Text="0.4.0  •  Без рекламы" Foreground="#B4D8CF" FontSize="12"/>
     <TextBlock Text="Личные файлы не передаются" Foreground="#84AFA6" FontSize="11" Margin="0,6,0,0"/>
    </StackPanel>
   </Grid>
  </Border>
  <Grid Grid.Column="1" Margin="24,23,24,18">
   <Grid.RowDefinitions>
    <RowDefinition Height="Auto"/>
    <RowDefinition Height="*"/>
    <RowDefinition Height="Auto"/>
   </Grid.RowDefinitions>
   <Grid Grid.Row="0" Margin="0,0,0,18">
    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
    <StackPanel>
     <TextBlock Text="Центр обслуживания компьютера" FontSize="20" FontWeight="Bold"/>
     <TextBlock Text="Проверяйте, очищайте и исправляйте только то, что действительно нужно"
      Foreground="#607784" Margin="0,5,0,0" FontSize="12"/>
    </StackPanel>
    <Button x:Name="BtnAnalyze" Grid.Column="1" Style="{StaticResource ActionButton}"
     Content="Проверить ПК" VerticalAlignment="Center" Margin="12,0,0,0"/>
   </Grid>
   <TabControl x:Name="MainTabs" Grid.Row="1" BorderThickness="0" Background="Transparent">
    <TabControl.Template>
     <ControlTemplate TargetType="{x:Type TabControl}">
      <ContentPresenter ContentSource="SelectedContent"/>
     </ControlTemplate>
    </TabControl.Template>
    <TabItem Header="Главная">
     <Grid>
      <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
      <Border Background="#E3F6EF" CornerRadius="14" Padding="21" Margin="0,0,0,14">
       <Grid>
        <Grid.ColumnDefinitions><ColumnDefinition Width="95"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
        <Border Width="78" Height="78" CornerRadius="40" Background="#12B888" HorizontalAlignment="Left" VerticalAlignment="Center">
         <TextBlock x:Name="HealthGlyph" Text="?" Foreground="White" FontWeight="Bold" FontSize="34" HorizontalAlignment="Center" VerticalAlignment="Center"/>
        </Border>
        <StackPanel Grid.Column="1" VerticalAlignment="Center">
         <TextBlock x:Name="HealthLabel" Text="Ожидание диагностики" FontSize="23" FontWeight="Bold" Foreground="#14614E"/>
         <TextBlock x:Name="HealthNote" Text="Нажмите «Проверить ПК», чтобы увидеть причины медленной работы."
          TextWrapping="Wrap" Foreground="#406D61" Margin="0,7,0,0"/>
        </StackPanel>
       </Grid>
      </Border>
      <Border Grid.Row="1" Style="{StaticResource PanelBorder}">
       <Grid>
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <TextBlock Text="Подробный анализ компьютера" FontSize="17" FontWeight="SemiBold" Margin="0,0,0,13"/>
        <TextBox x:Name="OverviewText" Grid.Row="1" IsReadOnly="True" Background="#FAFCFC"
         TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" FontSize="13" FontFamily="Consolas"
         Text="Идёт подготовка диагностического отчёта..."/>
        <WrapPanel Grid.Row="2" Margin="0,12,0,0">
         <Button x:Name="BtnReport" Style="{StaticResource ActionButton}" Content="Сохранить отчёт"/>
         <Button x:Name="BtnReportsFolder" Style="{StaticResource ActionButton}" Content="Папка отчётов"/>
        </WrapPanel>
       </Grid>
      </Border>
     </Grid>
    </TabItem>
    <TabItem Header="Антивирус">
     <Border Style="{StaticResource PanelBorder}">
      <Grid>
       <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
       <TextBlock Text="Антивирусная проверка Windows" FontSize="22" FontWeight="Bold"/>
       <TextBlock Grid.Row="1" Margin="0,12,0,16" TextWrapping="Wrap" Foreground="#5A6F7C"
        Text="Используется Microsoft Defender с его официальными антивирусными базами. Это не отдельный антивирусный движок. Полная проверка может быть долгой на HDD."/>
       <WrapPanel Grid.Row="2">
        <Button x:Name="BtnScan" Style="{StaticResource ActionButton}" Content="Быстрая проверка"/>
        <Button x:Name="BtnScanFull" Style="{StaticResource ActionButton}" Content="Полная проверка"/>
        <Button x:Name="BtnScanOffline" Style="{StaticResource ActionButton}" Content="Офлайн-проверка"/>
        <Button x:Name="BtnSecondOpinion" Style="{StaticResource ActionButton}" Content="Вторая проверка Microsoft"/>
        <Button x:Name="BtnNativeScan" Style="{StaticResource ActionButton}" Content="Независимая проверка папки"/>
        <Button x:Name="BtnDefenderUpdate" Style="{StaticResource ActionButton}" Content="Обновить базу вирусов"/>
        <Button x:Name="BtnDefenderThreats" Style="{StaticResource ActionButton}" Content="Обнаружения"/>
        <Button x:Name="BtnDefenderRemediate" Style="{StaticResource ActionButton}" Content="Обработать активные угрозы"/>
        <Button x:Name="BtnWindowsSecurity" Style="{StaticResource ActionButton}" Content="Журнал защиты Windows"/>
       </WrapPanel>
       <TextBox x:Name="SecurityText" Grid.Row="3" IsReadOnly="True" Background="#FAFCFC" Margin="0,15,0,0"
        TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"
        Text="Результаты обнаружения и карантин доступны в приложении «Безопасность Windows»."/>
      </Grid>
     </Border>
    </TabItem>
    <TabItem Header="Очистка">
     <Border Style="{StaticResource PanelBorder}">
      <Grid>
       <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
       <TextBlock Text="Очистка ненужных файлов" FontSize="22" FontWeight="Bold"/>
       <TextBlock Grid.Row="1" Margin="0,12,0,16" TextWrapping="Wrap" Foreground="#5A6F7C"
        Text="Только временные файлы старше 48 часов в AppData\Local\Temp текущего пользователя. Не удаляем личные данные, пароли браузеров, драйверы или системные папки. Удаление необратимо."/>
       <WrapPanel Grid.Row="2">
        <Button x:Name="BtnTempPreview" Style="{StaticResource ActionButton}" Content="Посчитать мусор"/>
        <Button x:Name="BtnTempClean" Style="{StaticResource ActionButton}" Content="Очистить с подтверждением" IsEnabled="False"/>
        <Button x:Name="BtnDeepAnalyze" Style="{StaticResource ActionButton}" Content="Глубокий анализ диска"/>
        <Button x:Name="BtnSpaceMap" Style="{StaticResource ActionButton}" Content="Куда ушло место?"/>
        <Button x:Name="BtnDeepClean" Style="{StaticResource ActionButton}" Content="Удалить найденное" IsEnabled="False"/>
        <Button x:Name="BtnStorageSense" Style="{StaticResource ActionButton}" Content="Очистка Windows"/>
       </WrapPanel>
       <TextBox x:Name="CleanupText" Grid.Row="3" IsReadOnly="True" Background="#FAFCFC" Margin="0,15,0,0"
        TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" Text="Пока ничего не удалено. Сначала посчитайте объём."/>
      </Grid>
     </Border>
    </TabItem>
    <TabItem Header="Автозагрузка">
     <Border Style="{StaticResource PanelBorder}">
      <Grid>
       <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
       <TextBlock Text="Что запускается вместе с Windows" FontSize="22" FontWeight="Bold"/>
       <TextBlock Grid.Row="1" TextWrapping="Wrap" Foreground="#5A6F7C" Margin="0,10,0,14"
        Text="Отключение неизвестной программы может нарушить работу оборудования. Отключайте только необязательные приложения."/>
       <DataGrid x:Name="StartupGrid" Grid.Row="2"/>
       <Button x:Name="BtnStartupSettings" Grid.Row="3" Style="{StaticResource ActionButton}" HorizontalAlignment="Left" Margin="0,12,0,0"
        Content="Управление автозагрузкой Windows"/>
      </Grid>
     </Border>
    </TabItem>
    <TabItem Header="Производительность">
     <Border Style="{StaticResource PanelBorder}">
      <Grid>
       <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="2*"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
       <TextBlock Text="Кто расходует оперативную память" FontSize="22" FontWeight="Bold"/>
       <TextBlock Grid.Row="1" TextWrapping="Wrap" Foreground="#5A6F7C" Margin="0,10,0,11"
        Text="Процессы по занимаемой RAM. CPU — накопленное время, не мгновенная загрузка."/>
       <DataGrid x:Name="ProcessesGrid" Grid.Row="2"/>
       <TextBlock Grid.Row="3" Margin="0,14,0,10" FontSize="16" FontWeight="SemiBold"
        Text="Дополнительные службы для ручной оценки"/>
       <DataGrid x:Name="ServiceGrid" Grid.Row="4"/>
       <WrapPanel Grid.Row="5" Margin="0,12,0,0">
        <Button x:Name="BtnServices" Style="{StaticResource ActionButton}" Content="Службы Windows"/>
        <Button x:Name="BtnVisualEffects" Style="{StaticResource ActionButton}" Content="Визуальные эффекты"/>
        <Button x:Name="BtnPowerPlan" Style="{StaticResource ActionButton}" Content="Электропитание"/>
       </WrapPanel>
      </Grid>
     </Border>
    </TabItem>
    <TabItem Header="Драйверы">
     <Border Style="{StaticResource PanelBorder}">
      <Grid>
       <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
       <TextBlock Text="Проверка драйверов и оборудования" FontSize="22" FontWeight="Bold"/>
       <TextBlock Grid.Row="1" TextWrapping="Wrap" Foreground="#5A6F7C" Margin="0,10,0,14"
        Text="Windows показывает устройства с ошибками. Обновляйте драйверы только через Windows Update или официальную поддержку производителя по точной модели."/>
       <Grid Grid.Row="2">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/><RowDefinition Height="2*"/></Grid.RowDefinitions>
        <TextBlock Grid.Row="0" Margin="0,0,0,6" FontWeight="SemiBold" Text="Устройства с ошибками Windows"/>
        <DataGrid x:Name="DriversGrid" Grid.Row="1"/>
        <TextBlock Grid.Row="2" Margin="0,12,0,6" FontWeight="SemiBold" Text="Доступные обновления драйверов Windows Update — выберите один"/>
        <DataGrid x:Name="DriverUpdatesGrid" Grid.Row="3" SelectionMode="Single"/>
       </Grid>
       <WrapPanel Grid.Row="3" Margin="0,12,0,0">
        <Button x:Name="BtnDriverInventory" Style="{StaticResource ActionButton}" Content="Установленные драйверы"/>
        <Button x:Name="BtnDriverSearch" Style="{StaticResource ActionButton}" Content="Найти драйверы"/>
        <Button x:Name="BtnDriverDownload" Style="{StaticResource ActionButton}" Content="Скачать выбранный" IsEnabled="False"/>
        <Button x:Name="BtnDriverInstall" Style="{StaticResource ActionButton}" Content="Установить выбранный" IsEnabled="False"/>
        <Button x:Name="BtnDriversUpdate" Style="{StaticResource ActionButton}" Content="Windows Update"/>
        <Button x:Name="BtnOemSupport" Style="{StaticResource ActionButton}" Content="Сайт производителя"/>
        <Button x:Name="BtnDeviceManager" Style="{StaticResource ActionButton}" Content="Диспетчер устройств"/>
       </WrapPanel>
      </Grid>
     </Border>
    </TabItem>
    <TabItem Header="Программы">
     <Border Style="{StaticResource PanelBorder}">
      <Grid>
       <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
       <TextBlock Text="Установленные программы" FontSize="22" FontWeight="Bold"/>
       <TextBlock Grid.Row="1" TextWrapping="Wrap" Foreground="#5A6F7C" Margin="0,10,0,14"
        Text="Список установленного ПО. Неизвестное название не означает, что программа вредоносная. Удаление только через Windows."/>
       <DataGrid x:Name="SoftwareGrid" Grid.Row="2"/>
       <Button x:Name="BtnAppsSettings" Grid.Row="3" Style="{StaticResource ActionButton}" HorizontalAlignment="Left" Margin="0,12,0,0"
        Content="Открыть удаление программ"/>
      </Grid>
     </Border>
    </TabItem>
    <TabItem Header="Уязвимости">
     <Border Style="{StaticResource PanelBorder}">
      <Grid>
       <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
       <TextBlock Text="Аудит безопасности и защиты от вымогателей" FontSize="21" FontWeight="Bold"/>
       <TextBlock Grid.Row="1" Margin="0,10,0,14" Foreground="#5A6F7C" TextWrapping="Wrap"
        Text="Проверка антивируса, брандмауэра, UAC, SMBv1, RDP и контроля папок. Не является полноценным сканером CVE и не доказывает отсутствие вредоносного ПО."/>
       <WrapPanel Grid.Row="2">
        <Button x:Name="BtnSecurityAudit" Style="{StaticResource ActionButton}" Content="Проверить безопасность"/>
        <Button x:Name="BtnRansomware" Style="{StaticResource ActionButton}" Content="Защита от вымогателей"/>
        <Button x:Name="BtnSecurityUpdates" Style="{StaticResource ActionButton}" Content="Обновления безопасности"/>
       </WrapPanel>
       <DataGrid x:Name="SecurityGrid" Grid.Row="3" Margin="0,12,0,0"/>
      </Grid>
     </Border>
    </TabItem>
    <TabItem Header="Турбо-режим">
     <Border Style="{StaticResource PanelBorder}">
      <Grid>
       <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
       <TextBlock Text="Обратимые профили ускорения" FontSize="22" FontWeight="Bold"/>
       <TextBlock Grid.Row="1" Margin="0,11,0,18" Foreground="#5A6F7C" TextWrapping="Wrap"
        Text="Экспертные режимы включаются по отдельности. Каждый записывает старые значения для отката. Настройки антивируса, обновлений и критичных служб не затрагиваются. Возможна перезагрузка сеанса."/>
       <WrapPanel Grid.Row="2">
        <Button x:Name="BtnBoostUI" Style="{StaticResource ActionButton}" Content="Убрать анимации"/>
        <Button x:Name="BtnBoostPower" Style="{StaticResource ActionButton}" Content="Высокая производительность"/>
        <Button x:Name="BtnBoostRestore" Style="{StaticResource ActionButton}" Content="Отменить последний буст"/>
        <Button x:Name="BtnBoostHistory" Style="{StaticResource ActionButton}" Content="История"/>
       </WrapPanel>
       <TextBox x:Name="BoostText" Grid.Row="3" Margin="0,12,0,0" Background="#FAFCFC"
        IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"
        Text="Ни один режим не применён. Выбирайте только те изменения, эффект которых понимаете."/>
      </Grid>
     </Border>
    </TabItem>
    <TabItem Header="Починка Windows">
     <Border Style="{StaticResource PanelBorder}">
      <Grid>
       <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
       <TextBlock Text="Восстановление системных компонентов" FontSize="21" FontWeight="Bold"/>
       <TextBlock Grid.Row="1" Margin="0,10,0,14" Foreground="#5A6F7C" TextWrapping="Wrap"
         Text="Используются только штатные DISM и SFC. Требуются права администратора. Исправление может занять длительное время и потребовать перезапуска."/>
       <WrapPanel Grid.Row="2">
        <Button x:Name="BtnRepairAudit" Style="{StaticResource ActionButton}" Content="Проверить хранилище компонентов"/>
        <Button x:Name="BtnRepairDism" Style="{StaticResource ActionButton}" Content="Восстановить через DISM"/>
        <Button x:Name="BtnRepairSfc" Style="{StaticResource ActionButton}" Content="Проверить и исправить SFC"/>
       </WrapPanel>
       <WrapPanel Grid.Row="3" Margin="0,14,0,12"><Button x:Name="BtnRegistryAudit" Style="{StaticResource ActionButton}" Content="Аудит автозапуска в реестре"/><Button x:Name="BtnRestorePoints" Style="{StaticResource ActionButton}" Content="Точки восстановления"/><Button x:Name="BtnRestoreWizard" Style="{StaticResource ActionButton}" Content="Мастер отката Windows"/></WrapPanel>
       <TextBox x:Name="RepairText" Grid.Row="4" IsReadOnly="True" Background="#FAFCFC" VerticalScrollBarVisibility="Auto"
        TextWrapping="Wrap" Text="Выберите проверку. Результаты сохраняются локально."/>
      </Grid>
     </Border>
    </TabItem>
   </TabControl>
   <Grid Grid.Row="2" Margin="0,13,0,0">
    <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
    <ProgressBar x:Name="WorkProgress" Grid.Row="0" Height="4" IsIndeterminate="False" Visibility="Collapsed"
     Foreground="#08A878" Background="#E2ECEB" Margin="0,0,0,8"/>
    <Border Grid.Row="1" Background="#EAF0F1" CornerRadius="8" Padding="11,9">
     <TextBlock x:Name="StatusText" Text="Подготовка" FontSize="12" TextWrapping="Wrap" Foreground="#4E6573"/>
    </Border>
   </Grid>
  </Grid>
 </Grid>
</Window>
'@
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms
$reader = New-Object System.Xml.XmlNodeReader $xaml
$script:window = [Windows.Markup.XamlReader]::Load($reader)
$iconPath = Join-Path $PSScriptRoot '..\assets\TurboOldPC.ico'
if (Test-Path -LiteralPath $iconPath -PathType Leaf) {
    try { $script:window.Icon = [Windows.Media.Imaging.BitmapFrame]::Create([Uri]$iconPath) } catch { }
}
$script:ui = @{}
foreach ($name in @('BtnAnalyze','OverviewText','BtnReport','BtnReportsFolder','StartupGrid',
    'BtnStartupSettings','DriversGrid','BtnDriversUpdate','BtnOemSupport','BtnDeviceManager',
    'SoftwareGrid','BtnAppsSettings','ProcessesGrid','ServiceGrid','BtnServices','BtnVisualEffects','BtnPowerPlan','BtnTempPreview','BtnStorageSense','BtnTempClean','CleanupText',
    'BtnScan','BtnScanFull','BtnScanOffline','BtnSecondOpinion','BtnNativeScan','BtnDefenderUpdate','BtnDefenderThreats','BtnDefenderRemediate','BtnWindowsSecurity','SecurityText','StatusText','HealthGlyph','HealthLabel','HealthNote','WorkProgress','MainTabs','NavHome','NavSecurity','NavCleanup','NavStartup','NavPerformance','NavDrivers','NavApps','NavAudit','NavBoost','NavRepair','BtnRepairAudit','BtnRepairDism','BtnRepairSfc','BtnRegistryAudit','BtnRestorePoints','BtnRestoreWizard','RepairText','BtnDeepAnalyze','BtnDeepClean','BtnSpaceMap','BtnSecurityAudit','BtnRansomware','BtnSecurityUpdates','SecurityGrid','BtnBoostUI','BtnBoostPower','BtnBoostRestore','BtnBoostHistory','BoostText','DriverUpdatesGrid','BtnDriverSearch','BtnDriverInventory','BtnDriverDownload','BtnDriverInstall')) {
    $script:ui[$name] = $script:window.FindName($name)
    if ($null -eq $script:ui[$name]) { throw "Не найден элемент окна: $name" }
}
$script:lastSnapshot = $null
$script:activeProcess = $null
$script:activeOp = ''
$script:activeResultPath = ''
$script:tempPreviewDone = $false
$script:deepManifest = ''
$script:selectedDisk = [string]$env:SystemDrive
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
        $lines.Add('CPU: ' + $h.CPU + '; ядра: ' + $h.Cores + '; нагрузка во время проверки: ' + $h.CpuLoadPercent + '%')
        $lines.Add('RAM: ' + $h.MemoryGb + ' ГБ; свободно при проверке: ' + $h.FreeMemoryGb + ' ГБ')
        $lines.Add('ОС: ' + $h.Windows + ' ' + $h.Version)
        $lines.Add('Системный накопитель: ' + $h.Disk + ' / ' + $h.DiskType + ' / ' + $h.DiskBus)
        $lines.Add('Здоровье диска по Windows (ориентировочно): ' + $h.DiskHealth)
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
    $lines.Add('САМЫЕ КРУПНЫЕ ПРОЦЕССЫ ПО RAM (CPU — накопленное время):')
    foreach ($x in @($snap.Processes)) { $lines.Add("$($x.Name) | RAM $($x.RamMb) МБ | CPU $($x.CpuTotalSeconds) с") }
    $lines.Add('')
    $lines.Add('СТОРОННИЕ АВТОМАТИЧЕСКИЕ СЛУЖБЫ, ТОЛЬКО ДЛЯ АНАЛИЗА:')
    foreach ($x in @($snap.ServiceAudit)) { $lines.Add("$($x.DisplayName) | $($x.Name) | $($x.Executable)") }
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
    if ($null -eq $snap.Hardware) {
        $script:ui['HealthGlyph'].Text = '!'
        $script:ui['HealthLabel'].Text = 'Не удалось определить характеристики'
        $script:ui['HealthNote'].Text = 'Проверьте подробный отчёт и повторите диагностику.'
    } else {
        $h = $snap.Hardware
        $issues = @($snap.Recommendations)
        $script:ui['HealthGlyph'].Text = '✓'
        $script:ui['HealthLabel'].Text = 'Анализ компьютера готов'
        $script:ui['HealthNote'].Text = "Модель: $($h.Manufacturer) $($h.Model). RAM: $($h.MemoryGb) ГБ. Диск: $($h.DiskType) ($($h.DiskHealth)). Рекомендаций: $($issues.Count). Они приведены ниже."
    }
    $script:ui['StartupGrid'].ItemsSource = @($snap.Startup)
    $script:ui['DriversGrid'].ItemsSource = @($snap.DriverProblems)
    $script:ui['SoftwareGrid'].ItemsSource = @($snap.Software)
    $script:ui['ProcessesGrid'].ItemsSource = @($snap.Processes)
    $script:ui['ServiceGrid'].ItemsSource = @($snap.ServiceAudit)
}
function Start-TurboWorker([string]$operation, [string]$relativeFile, [string]$extraParams = '', [bool]$elevated = $false) {
    if ($null -ne $script:activeProcess) {
        Show-TurboError 'Дождитесь завершения текущей операции.'
        return
    }
    try {
        $file = Join-Path $PSScriptRoot $relativeFile
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Нет рабочего скрипта: $file" }
        $output = Join-Path $script:jobsDir (([guid]::NewGuid().ToString('N')) + '.json')
        $command = "& '" + $file.Replace("'","''") + "' -OutputPath '" + $output.Replace("'","''") + "' " + $extraParams
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
        $args = @('-NoLogo','-NoProfile','-NonInteractive','-EncodedCommand',$encoded)
        if ($elevated) {
            $script:activeProcess = Start-Process -FilePath (Join-Path $PSHOME 'powershell.exe') -ArgumentList $args -Verb RunAs -PassThru -ErrorAction Stop
        } else {
            $script:activeProcess = Start-Process -FilePath (Join-Path $PSHOME 'powershell.exe') -ArgumentList $args -WindowStyle Hidden -PassThru -ErrorAction Stop
        }
        $script:activeOp = $operation
        $script:activeResultPath = $output
        Set-TurboStatus ("Выполняется: $operation. Окно остаётся доступным.")
        $script:ui['WorkProgress'].Visibility = 'Visible'
        $script:ui['WorkProgress'].IsIndeterminate = $true
        $script:timer.Start()
    } catch { Show-TurboError "Не удалось запустить: $($_.Exception.Message)" }
}
$script:timer = New-Object System.Windows.Threading.DispatcherTimer
$script:timer.Interval = [TimeSpan]::FromMilliseconds(800)
$script:timer.Add_Tick({
    if ($null -eq $script:activeProcess -or -not $script:activeProcess.HasExited) { return }
    $script:timer.Stop()
    $script:ui['WorkProgress'].Visibility = 'Collapsed'
    $script:ui['WorkProgress'].IsIndeterminate = $false
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
            'Собственный сканер' {
                $lines=New-Object 'System.Collections.Generic.List[string]'
                $scan=$result.Scan
                $lines.Add([string]$result.Message)
                foreach($finding in @($scan.Findings)){
                    $lines.Add("Совпадение: $($finding.Name); SHA256: $($finding.SHA256); файл: $($finding.Path)")
                }
                $lines.Add('Совпадение сигнатуры — повод проверить Defender. Встроенный сканер проверяет только хеши, не имеет защиты в реальном времени и не заменяет антивирус.')
                $script:ui['SecurityText'].Text=$lines -join [Environment]::NewLine
                Set-TurboStatus ([string]$result.Message)
            }
            'Центр угроз' {
                $lines=New-Object 'System.Collections.Generic.List[string]'
                $lines.Add([string]$result.Message)
                foreach($d in @($result.Detections)) {
                    $lines.Add("$($d.Time) | ID $($d.ThreatID) | Действие: $($d.ActionSuccess) | $($d.Resources)")
                }
                $lines.Add('Проверяйте историю обработки и карантин через Безопасность Windows. Обнаружения могут относиться к уже устранённым угрозам.')
                $script:ui['SecurityText'].Text=$lines -join [Environment]::NewLine
                Set-TurboStatus ([string]$result.Message)
            }
            'Антивирус' {
                $script:ui['SecurityText'].Text = [string]$result.Message
                Set-TurboStatus 'Команда Defender выполнена. Проверьте журнал Защиты Windows.'
            }
            'Аудит защиты' {
                $script:ui['SecurityGrid'].ItemsSource = @($result.Checks)
                Set-TurboStatus ([string]$result.Message)
            }
            'Инвентаризация драйверов' {
                $script:ui['DriversGrid'].ItemsSource = @($result.Drivers)
                Set-TurboStatus ([string]$result.Message)
            }
            'Поиск драйверов' {
                $script:ui['DriverUpdatesGrid'].ItemsSource = @($result.Updates)
                $script:ui['BtnDriverInstall'].IsEnabled = $false
                Set-TurboStatus ([string]$result.Message)
            }
            'Скачивание драйвера' {
                Set-TurboStatus ([string]$result.Message)
            }
            'Установка драйвера' {
                $script:ui['BtnDriverInstall'].IsEnabled = $false
                $script:ui['DriverUpdatesGrid'].ItemsSource = $null
                Show-TurboError ([string]$result.Message + ' Обновите список после возможной перезагрузки.')
                Set-TurboStatus ([string]$result.Message)
            }
            'Буст' {
                $script:ui['BoostText'].Text = [string]$result.Message
                Set-TurboStatus ([string]$result.Message)
            }
            'Глубокий анализ' {
                $script:deepManifest = [string]$result.ManifestPath
                $mb = [math]::Round(([double]$result.Bytes / 1MB),1)
                $categories = @($result.Groups | ForEach-Object { "$($_.Category): $([math]::Round(([double]$_.Bytes/1MB),1)) МБ ($($_.Files) файлов)" })
                $script:ui['CleanupText'].Text = "Выбран диск: $($result.Drive). Найдено: $mb МБ." + [Environment]::NewLine + ($categories -join [Environment]::NewLine)
                $script:ui['BtnDeepClean'].IsEnabled = ($result.Count -gt 0)
                Set-TurboStatus ([string]$result.Message)
            }
            'Карта диска' {
                $rows=New-Object 'System.Collections.Generic.List[string]'
                $rows.Add("Просмотрено файлов: $($result.ScannedFiles). Пропущено каталогов: $($result.SkippedFolders).")
                if ($result.Truncated) { $rows.Add('Достигнут предел анализа. Результаты неполные.') }
                $rows.Add('КРУПНЕЙШИЕ ПАПКИ В КОРНЕ:')
                foreach($folder in @($result.Folders)) {
                    $rows.Add(('{0}: {1} ГБ' -f $folder.Name,[math]::Round(([double]$folder.Bytes/1GB),2)))
                }
                $rows.Add('ФАЙЛЫ ОТ 100 МБ:')
                foreach($f in @($result.Largest)){
                    $rows.Add(('{0} ГБ — {1}' -f [math]::Round(([double]$f.SizeBytes/1GB),2),$f.Path))
                }
                $rows.Add('Никакие файлы не удалены. Проверяйте назначение крупных файлов перед любым ручным удалением.')
                $script:ui['CleanupText'].Text = $rows -join [Environment]::NewLine
                Set-TurboStatus ([string]$result.Message)
            }
            'Глубокая очистка' {
                $mb = [math]::Round(([double]$result.Bytes / 1MB),1)
                $script:ui['CleanupText'].Text = "Удалено $($result.Deleted) файлов. Пропущено: $($result.Skipped). Освобождено около $mb МБ."
                $script:deepManifest = ''
                $script:ui['BtnDeepClean'].IsEnabled = $false
                Set-TurboStatus ([string]$result.Message)
            }
            'Точки восстановления' {
                $items=@($result.Points|ForEach-Object{ "$($_.Sequence) — $($_.Created) — $($_.Description)" })
                if($items.Count -eq 0){$items=@('Точек восстановления нет. Проверьте защиту системы.')}
                $script:ui['RepairText'].Text=$items -join [Environment]::NewLine
                Set-TurboStatus ([string]$result.Message)
            }
            'Аудит реестра' {
                $lines = @($result.Entries | ForEach-Object { "$($_.Status): $($_.Name) — $($_.Command)" })
                $script:ui['RepairText'].Text = $lines -join [Environment]::NewLine
                Set-TurboStatus ([string]$result.Message)
            }
            'Починка Windows' {
                $script:ui['RepairText'].Text = [string]$result.Message
                Set-TurboStatus ([string]$result.Message)
            }
            'История бустов' {
                $items = @($result.History | ForEach-Object { "$($_.Date): $($_.Profile) — $($_.Status)" })
                $script:ui['BoostText'].Text = ($items -join [Environment]::NewLine)
                if ($items.Count -eq 0) { $script:ui['BoostText'].Text = 'История изменений пуста.' }
                Set-TurboStatus 'Журнал профилей прочитан.'
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
$navigation = @(
    @('NavHome',0), @('NavSecurity',1), @('NavCleanup',2),
    @('NavStartup',3), @('NavPerformance',4), @('NavDrivers',5), @('NavApps',6),
    @('NavAudit',7), @('NavBoost',8), @('NavRepair',9)
)
foreach ($pair in $navigation) {
    $item = $pair
    $button = $script:ui[[string]$item[0]]
    $tabIndex = [int]$item[1]
    $button.Tag = $tabIndex
    $button.Add_Click({
        param($sender,$args)
        $script:ui['MainTabs'].SelectedIndex = [int]$sender.Tag
    })
}
$script:ui['MainTabs'].SelectedIndex = 0
$script:ui['BtnScan'].Add_Click({
    $script:ui['SecurityText'].Text = 'Запущена проверка. На старом HDD это может занять длительное время.'
    Start-TurboWorker 'Антивирус' 'Workers\DefenderScan.ps1'
})
$script:ui['BtnScanFull'].Add_Click({
    $answer = [System.Windows.MessageBox]::Show($script:window,
        'Полная проверка Microsoft Defender может занять часы на старом HDD. Запустить?',
        'Полная антивирусная проверка', 'YesNo', 'Question')
    if ($answer -eq [System.Windows.MessageBoxResult]::Yes) {
        $script:ui['SecurityText'].Text = 'Запущена полная проверка Microsoft Defender. Ждите завершения фоновой операции.'
        Start-TurboWorker 'Антивирус' 'Workers\DefenderScan.ps1' '-ScanType FullScan'
    }
})
$script:ui['BtnNativeScan'].Add_Click({
    $picker=New-Object System.Windows.Forms.FolderBrowserDialog
    $picker.Description='Выберите папку для независимого сигнатурного сканирования'
    $picker.ShowNewFolderButton=$false
    try {
        if($picker.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $path=$picker.SelectedPath.Replace("'","''")
            Start-TurboWorker 'Собственный сканер' 'Workers\NativeScan.ps1' ("-Mode Scan -ScanRoot '"+$path+"'")
        }
    } finally { $picker.Dispose() }
})
$script:ui['BtnDefenderUpdate'].Add_Click({ Start-TurboWorker 'Центр угроз' 'Workers\ThreatCenter.ps1' '-Mode Update' })
$script:ui['BtnDefenderThreats'].Add_Click({ Start-TurboWorker 'Центр угроз' 'Workers\ThreatCenter.ps1' '-Mode Threats' })
$script:ui['BtnDefenderRemediate'].Add_Click({
    $answer=[Windows.MessageBox]::Show($script:window,
        'Microsoft Defender попытается устранить ВСЕ обнаруженные активные угрозы. Это может затронуть подозрительные файлы, включая ложные срабатывания. Продолжить с повышением прав?',
        'Удаление угроз','YesNo','Warning')
    if($answer -eq 'Yes'){Start-TurboWorker 'Центр угроз' 'Workers\ThreatCenter.ps1' '-Mode Remediate' $true}
})
$script:ui['BtnScanOffline'].Add_Click({
    [void][Windows.MessageBox]::Show($script:window,
        'Автономная проверка Microsoft Defender может сразу перезагрузить компьютер. Сохраните документы, проверьте наличие ключа восстановления BitLocker и состояние WinRE. В открывшемся окне: Защита от вирусов и угроз → Параметры сканирования → Автономная проверка.',
        'Офлайн-проверка с перезапуском','OK','Warning')
    Open-TurboShell 'windowsdefender:' 'ms-settings:windowsdefender'
})
$script:ui['BtnSecondOpinion'].Add_Click({
    Open-TurboShell 'https://learn.microsoft.com/en-us/defender-endpoint/safety-scanner-download'
})
$script:ui['BtnRestorePoints'].Add_Click({ Start-TurboWorker 'Точки восстановления' 'Workers\RestorePoints.ps1' })
$script:ui['BtnRestoreWizard'].Add_Click({ Open-TurboShell 'rstrui.exe' })
$script:ui['BtnRegistryAudit'].Add_Click({ Start-TurboWorker 'Аудит реестра' 'Workers\RegistryAudit.ps1' })
$script:ui['BtnSpaceMap'].Add_Click({
    $drive=[Microsoft.VisualBasic.Interaction]::InputBox('Буква диска для карты занятого места:','Карта диска',$script:selectedDisk)
    if($drive -notmatch '^[A-Za-z]:$'){Show-TurboError 'Введите букву диска, например C:';return}
    $script:selectedDisk=$drive.ToUpperInvariant()
    Start-TurboWorker 'Карта диска' 'Workers\SpaceMap.ps1' ('-Drive '+$script:selectedDisk)
})
$script:ui['BtnDeepAnalyze'].Add_Click({
    $choice = [Microsoft.VisualBasic.Interaction]::InputBox('Буква диска для анализа (например C:):','Глубокая очистка',$script:selectedDisk)
    if ($choice -notmatch '^[A-Za-z]:$') { Show-TurboError 'Введите только букву диска: C: или D:'; return }
    $script:selectedDisk = $choice.ToUpperInvariant()
    $script:deepManifest = ''
    $script:ui['BtnDeepClean'].IsEnabled = $false
    Start-TurboWorker 'Глубокий анализ' 'Workers\DeepCleanup.ps1' ("-Mode Analyze -Drive " + $script:selectedDisk)
})
$script:ui['BtnDeepClean'].Add_Click({
    if (-not $script:deepManifest) {return}
    $answer = [Windows.MessageBox]::Show($script:window,'Удалить найденные старые кэши и временные файлы на выбранном диске? Это необратимо; работающие файлы будут пропущены.','Глубокая очистка','YesNo','Warning')
    if ($answer -eq 'Yes') {
        $safePath = $script:deepManifest.Replace("'","''")
        Start-TurboWorker 'Глубокая очистка' 'Workers\DeepCleanup.ps1' ("-Mode Clean -Drive " + $script:selectedDisk + " -ManifestPath '" + $safePath + "'")
    }
})
foreach ($task in @(@('BtnRepairAudit','Audit'),@('BtnRepairDism','DISM'),@('BtnRepairSfc','SFC'))) {
    $button=$script:ui[[string]$task[0]]
    $button.Tag=[string]$task[1]
    $button.Add_Click({
        param($sender,$eventArgs)
        $mode=[string]$sender.Tag
        $answer=[Windows.MessageBox]::Show($script:window,
            "Запустить системную операцию $mode с правами администратора? Перед восстановлением сохраните важные данные.",
            'Системное обслуживание','YesNo','Warning')
        if($answer -eq 'Yes'){Start-TurboWorker 'Починка Windows' 'Workers\SystemRepair.ps1' ("-Mode "+$mode) $true}
    })
}
$script:ui['BtnStartupSettings'].Add_Click({ Open-TurboShell 'ms-settings:startupapps' 'taskmgr.exe' })
$script:ui['BtnAppsSettings'].Add_Click({ Open-TurboShell 'ms-settings:appsfeatures' 'appwiz.cpl' })
$script:ui['BtnServices'].Add_Click({ Open-TurboShell 'services.msc' })
$script:ui['BtnVisualEffects'].Add_Click({ Open-TurboShell 'SystemPropertiesPerformance.exe' })
$script:ui['BtnPowerPlan'].Add_Click({ Open-TurboShell 'powercfg.cpl' })
$script:ui['BtnStorageSense'].Add_Click({ Open-TurboShell 'ms-settings:storagepolicies' 'cleanmgr.exe' })
$script:ui['BtnDriversUpdate'].Add_Click({ Open-TurboShell 'ms-settings:windowsupdate-optionalupdates' 'ms-settings:windowsupdate' })
$script:ui['BtnSecurityAudit'].Add_Click({ Start-TurboWorker 'Аудит защиты' 'Workers\SecurityAudit.ps1' })
$script:ui['BtnRansomware'].Add_Click({ Open-TurboShell 'windowsdefender:' 'ms-settings:windowsdefender' })
$script:ui['BtnSecurityUpdates'].Add_Click({ Open-TurboShell 'ms-settings:windowsupdate' })
$script:ui['BtnDriverInventory'].Add_Click({ Start-TurboWorker 'Инвентаризация драйверов' 'Workers\DriverInventory.ps1' })
$script:ui['BtnDriverSearch'].Add_Click({
    $script:ui['DriverUpdatesGrid'].ItemsSource = $null
    $script:ui['BtnDriverInstall'].IsEnabled = $false
    Start-TurboWorker 'Поиск драйверов' 'Workers\DriverUpdates.ps1' '-Mode List'
})
$script:ui['DriverUpdatesGrid'].Add_SelectionChanged({
    $entry = $script:ui['DriverUpdatesGrid'].SelectedItem
    $script:ui['BtnDriverInstall'].IsEnabled = ($null -ne $entry -and $null -eq $script:activeProcess)
    $script:ui['BtnDriverDownload'].IsEnabled = ($null -ne $entry -and $null -eq $script:activeProcess)
})
$script:ui['BtnDriverDownload'].Add_Click({
    $entry=$script:ui['DriverUpdatesGrid'].SelectedItem
    if ($null -eq $entry) { Show-TurboError 'Сначала выберите драйвер';return }
    $id=[string]$entry.UpdateId
    if ($id -notmatch '^[a-fA-F0-9-]{36}$') { Show-TurboError 'Неверный идентификатор драйвера';return }
    Start-TurboWorker 'Скачивание драйвера' 'Workers\DriverUpdates.ps1' ("-Mode Download -UpdateId " + $id + " -Revision " + [int]$entry.Revision) $true
})
$script:ui['BtnDriverInstall'].Add_Click({
    $entry = $script:ui['DriverUpdatesGrid'].SelectedItem
    if ($null -eq $entry) { Show-TurboError 'Сначала выберите драйвер в списке.'; return }
    $id = [string]$entry.UpdateId
    if ($id -notmatch '^[a-fA-F0-9-]{36}$') { Show-TurboError 'Некорректный идентификатор обновления.'; return }
    $response = [Windows.MessageBox]::Show($script:window,
        "Установить через Windows Update: $($entry.Title)? Будет запрошен UAC. Сначала должна быть успешно создана точка восстановления. Согласны?",
        'Установка драйвера', 'YesNo', 'Warning')
    if ($response -eq 'Yes') {
        Start-TurboWorker 'Установка драйвера' 'Workers\DriverUpdates.ps1' ("-Mode Install -UpdateId " + $id + " -Revision " + [int]$entry.Revision) $true
    }
})
$script:ui['BtnBoostUI'].Add_Click({
    $response = [Windows.MessageBox]::Show($script:window,
        'Уменьшить визуальные эффекты в текущем профиле Windows? Старые значения будут сохранены для отката.',
        'Турбо: интерфейс', 'YesNo', 'Question')
    if ($response -eq 'Yes') { Start-TurboWorker 'Буст' 'Workers\Boost.ps1' '-Mode ApplyUI' }
})
$script:ui['BtnBoostPower'].Add_Click({
    $response = [Windows.MessageBox]::Show($script:window,
        'Включить план Высокая производительность? Это может увеличивать нагрев, шум и энергопотребление. Старый план питания сохраняется.',
        'Турбо: производительность', 'YesNo', 'Warning')
    if ($response -eq 'Yes') { Start-TurboWorker 'Буст' 'Workers\Boost.ps1' '-Mode ApplyPower' }
})
$script:ui['BtnBoostRestore'].Add_Click({
    $response = [Windows.MessageBox]::Show($script:window,
        'Восстановить настройки из последнего невосстановленного журнала Turbo Old PC?',
        'Откат настроек', 'YesNo', 'Question')
    if ($response -eq 'Yes') { Start-TurboWorker 'Буст' 'Workers\Boost.ps1' '-Mode Restore' }
})
$script:ui['BtnBoostHistory'].Add_Click({ Start-TurboWorker 'История бустов' 'Workers\Boost.ps1' '-Mode History' })

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
