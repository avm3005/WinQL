# Install-WinQL.ps1 - Taskbar-Integrated Setup for WinQL v5.1.0 (Media Deadlock Fix)

# --- 1. AUTOMATIC ADMINISTRATOR ELEVATION ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-Sta -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "      WinQL Utility Installer - v5.1.0         " -ForegroundColor White
Write-Host "=================================================" -ForegroundColor Cyan
Start-Sleep -Seconds 1

# --- 2. CLEANUP & PREVIOUS INSTALLATION DETECTION ---
$appDataFolder = "$env:APPDATA\Detaroxz\WinQL"
$settingsFile = "$appDataFolder\settings.json"

Write-Host "[*] Terminating existing background processes..." -ForegroundColor DarkGray
Get-CimInstance Win32_Process | Where-Object { ($_.CommandLine -match "WinQL.ps1" -or $_.Name -match "WinQL.exe") -and $_.ProcessId -ne $PID } | Invoke-CimMethod -MethodName Terminate | Out-Null

$installDir = "C:\Program Files\Detaroxz\WinQL"
$commonPrograms = [Environment]::GetFolderPath('CommonPrograms')

if (Test-Path $installDir) { Remove-Item -Path $installDir -Recurse -Force -ErrorAction SilentlyContinue }
$oldMenuDir = Join-Path $commonPrograms "WinQL"
if (Test-Path $oldMenuDir) { Remove-Item -Path $oldMenuDir -Recurse -Force -ErrorAction SilentlyContinue }
$mainShortcutPath = Join-Path $commonPrograms "WinQL.lnk"
if (Test-Path $mainShortcutPath) { Remove-Item $mainShortcutPath -Force -ErrorAction SilentlyContinue }

Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WinQL" -ErrorAction SilentlyContinue
$shortcutPath = Join-Path ([Environment]::GetFolderPath('Startup')) "WinQL.lnk"
if (Test-Path $shortcutPath) { Remove-Item $shortcutPath -Force -ErrorAction SilentlyContinue }
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WinQL" -Recurse -Force -ErrorAction SilentlyContinue

New-Item -Path $installDir -ItemType Directory -Force | Out-Null
if (-not (Test-Path $appDataFolder)) { New-Item -Path $appDataFolder -ItemType Directory -Force | Out-Null }

# --- 3. DYNAMICALLY GENERATE THE ICO NATIVELY ---
Write-Host "[*] Compiling UI Assets & Native Icon..." -ForegroundColor Cyan
Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap(256, 256)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)

$brush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#4CAF50"))
$path = New-Object System.Drawing.Drawing2D.GraphicsPath
$x = 12; $y = 12; $w = 232; $h = 232; $r = 40
$path.AddArc($x, $y, $r, $r, 180, 90); $path.AddArc($x+$w-$r, $y, $r, $r, 270, 90)
$path.AddArc($x+$w-$r, $y+$h-$r, $r, $r, 0, 90); $path.AddArc($x, $y+$h-$r, $r, $r, 90, 90)
$path.CloseFigure(); $g.FillPath($brush, $path)

$yellowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#FFC107"))
$g.FillEllipse($yellowBrush, 40, 108, 40, 40); $g.FillEllipse($yellowBrush, 90, 108, 40, 40)
$g.FillEllipse($yellowBrush, 140, 108, 40, 40); $g.FillEllipse($yellowBrush, 190, 108, 40, 40)

$ms = New-Object System.IO.MemoryStream
$bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
$pngBytes = $ms.ToArray()
$icoStream = New-Object System.IO.FileStream("$installDir\icon.ico", [System.IO.FileMode]::Create)
$bw = New-Object System.IO.BinaryWriter($icoStream)
$bw.Write([int16]0); $bw.Write([int16]1); $bw.Write([int16]1); $bw.Write([byte]0); $bw.Write([byte]0); $bw.Write([byte]0); $bw.Write([byte]0); $bw.Write([int16]1); $bw.Write([int16]32)
$bw.Write([int32]$pngBytes.Length); $bw.Write([int32]22); $bw.Write($pngBytes)
$bw.Flush(); $icoStream.Dispose(); $ms.Dispose(); $g.Dispose(); $bmp.Dispose()

# --- 4. BUILD THE INVISIBLE LAUNCHER ---
Write-Host "[*] Creating Native Background Wrapper & Silencer..." -ForegroundColor Cyan
Copy-Item "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" -Destination "$installDir\WinQL.exe" -Force

$launcherVbs = @'
Set ws = CreateObject("WScript.Shell")
ws.Run """C:\Program Files\Detaroxz\WinQL\WinQL.exe"" -Sta -ExecutionPolicy Bypass -WindowStyle Hidden -File ""C:\Program Files\Detaroxz\WinQL\WinQL.ps1""", 0, False
'@
Set-Content -Path "$installDir\Invisible.vbs" -Value $launcherVbs -Encoding Ascii

# --- 5. DEFINE THE MAIN SCRIPT PAYLOAD ---
Write-Host "[*] Writing Taskbar-Integrated Engine logic..." -ForegroundColor Cyan
$mainContent = @'
try {
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Windows.Forms

    # --- Deep Win32 API Interop ---
    $signature = @"
    using System;
    using System.Runtime.InteropServices;
    public class Native {
        [DllImport("user32.dll", SetLastError = true)] public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
        [DllImport("user32.dll", SetLastError = true)] public static extern IntPtr FindWindowEx(IntPtr hwndParent, IntPtr hwndChildAfter, string lpszClass, string lpszWindow);
        [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd, out RECT lpRect);
        [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hwnd, out RECT lpRect);
        [DllImport("user32.dll")] public static extern int MapWindowPoints(IntPtr hWndFrom, IntPtr hWndTo, ref RECT lpPoints, uint cPoints);
        [DllImport("user32.dll", SetLastError = true)] public static extern IntPtr SetParent(IntPtr hWndChild, IntPtr hWndNewParent);
        [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
        [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr hWnd, int nIndex);
        [DllImport("user32.dll")] public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);
        [DllImport("user32.dll")] public static extern uint RegisterWindowMessage(string lpString);
        [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, int dwExtraInfo);
        [DllImport("kernel32.dll")] public static extern bool SetProcessWorkingSetSize(IntPtr proc, int min, int max);

        [StructLayout(LayoutKind.Sequential)] public struct RECT { public int left, top, right, bottom; }
        [StructLayout(LayoutKind.Sequential)] public struct APPBARDATA { public int cbSize; public IntPtr hWnd; public int uCallbackMessage; public int uEdge; public RECT rc; public IntPtr lParam; }
        [DllImport("shell32.dll")] public static extern IntPtr SHAppBarMessage(int dwMessage, ref APPBARDATA pData);

        public static int GetTaskbarEdge() {
            APPBARDATA abd = new APPBARDATA();
            abd.cbSize = Marshal.SizeOf(abd);
            SHAppBarMessage(5, ref abd);
            return abd.uEdge; 
        }

        public static uint WM_TASKBARCREATED = RegisterWindowMessage("TaskbarCreated");

        public static IntPtr GetTrayHandle(IntPtr hTaskbar) {
            return FindWindowEx(hTaskbar, IntPtr.Zero, "TrayNotifyWnd", null);
        }

        public static void TrimMemory() {
            GC.Collect(); GC.WaitForPendingFinalizers(); GC.Collect();
            try { SetProcessWorkingSetSize(System.Diagnostics.Process.GetCurrentProcess().Handle, -1, -1); } catch {}
        }
    }
"@
    Add-Type -TypeDefinition $signature -Language CSharp

    # --- Robust MTA-Isolated UWP Media Handler (Fixes STA Deadlock Bug) ---
    try {
        $smtcSig = @"
        using System;
        using System.Threading.Tasks;
        using Windows.Media.Control;
        using Windows.Storage.Streams;

        public class WinMedia {
            public static string Title = "";
            public static string Artist = "";
            public static string AppId = "";
            public static byte[] ThumbBytes = null;
            public static bool IsPlaying = false;
            public static bool HasMedia = false;

            public static void Update() {
                try {
                    Task.Run(async () => {
                        var manager = await GlobalSystemMediaTransportControlsSessionManager.RequestAsync();
                        var session = manager.GetCurrentSession();
                        if (session == null) { HasMedia = false; return; }
                        
                        var info = await session.TryGetMediaPropertiesAsync();
                        Title = info.Title;
                        Artist = info.Artist;
                        AppId = session.SourceAppUserModelId;
                        
                        var playback = session.GetPlaybackInfo();
                        IsPlaying = playback.PlaybackStatus == GlobalSystemMediaTransportControlsSessionPlaybackStatus.Playing;

                        if (info.Thumbnail != null) {
                            using (var stream = await info.Thumbnail.OpenReadAsync()) {
                                var bytes = new byte[stream.Size];
                                using (var reader = new DataReader(stream)) {
                                    await reader.LoadAsync((uint)stream.Size);
                                    reader.ReadBytes(bytes);
                                    ThumbBytes = bytes;
                                }
                            }
                        } else {
                            ThumbBytes = null;
                        }
                        HasMedia = true;
                    }).Wait(400); // 400ms timeout strictly prevents the STA UI thread from permanently deadlocking
                } catch {
                    HasMedia = false;
                }
            }
            
            public static void PlayPause() { Task.Run(async () => { var m = await GlobalSystemMediaTransportControlsSessionManager.RequestAsync(); var s = m.GetCurrentSession(); if(s != null) await s.TryTogglePlayPauseAsync(); }); }
            public static void Next() { Task.Run(async () => { var m = await GlobalSystemMediaTransportControlsSessionManager.RequestAsync(); var s = m.GetCurrentSession(); if(s != null) await s.TrySkipNextAsync(); }); }
            public static void Prev() { Task.Run(async () => { var m = await GlobalSystemMediaTransportControlsSessionManager.RequestAsync(); var s = m.GetCurrentSession(); if(s != null) await s.TrySkipPreviousAsync(); }); }
        }
"@
        $winmdPath = "$env:windir\System32\WinMetadata"
        $refs = @("System", "System.Runtime", "System.Runtime.WindowsRuntime", "System.Threading.Tasks", "System.IO", "$winmdPath\Windows.Foundation.winmd", "$winmdPath\Windows.Media.winmd", "$winmdPath\Windows.Storage.winmd")
        Add-Type -TypeDefinition $smtcSig -Language CSharp -ReferencedAssemblies $refs
        $global:MediaAPIEnabled = $true
    } catch {
        $errMsg = "Media API Compilation Failed: $($_.Exception.Message)"
        $errMsg | Out-File "$env:APPDATA\Detaroxz\WinQL\media_error.log"
        $global:MediaAPIEnabled = $false
    }

    $mutexCreated = $false
    $script:appMutex = New-Object System.Threading.Mutex($true, "Global\WinQLDesktop_Mutex", [ref]$mutexCreated)
    if (-not $mutexCreated) { Exit }

    $appDataFolder = "$env:APPDATA\Detaroxz\WinQL"
    $settingsFile = "$appDataFolder\settings.json"

    function Get-ThemeColor {
        try {
            $reg = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -ErrorAction SilentlyContinue
            if ($reg -eq 1) { return "#000000" } else { return "#FFFFFF" }
        } catch { return "#FFFFFF" }
    }

    function Get-ComboText ($cmb) {
        if ($null -eq $cmb) { return "" }
        if ($null -ne $cmb.SelectedItem) {
            if ($cmb.SelectedItem -is [System.Windows.Controls.ComboBoxItem]) { return $cmb.SelectedItem.Content.ToString() }
            return $cmb.SelectedItem.ToString()
        }
        if ($null -ne $cmb.Text) { return $cmb.Text.ToString() }
        return ""
    }

    function Load-Settings {
        $loaded = $null
        if (Test-Path $settingsFile) { try { $loaded = Get-Content $settingsFile -Raw | ConvertFrom-Json } catch {} }
        if ($null -eq $loaded) { $loaded = New-Object PSObject }
        
        if ($null -eq $loaded.BtnCount) { $loaded | Add-Member -MemberType NoteProperty -Name "BtnCount" -Value 1 -Force }
        if ($null -eq $loaded.Alignment) { $loaded | Add-Member -MemberType NoteProperty -Name "Alignment" -Value "Center" -Force }
        if ($null -eq $loaded.LeftSpacing) { $loaded | Add-Member -MemberType NoteProperty -Name "LeftSpacing" -Value 10 -Force }
        if ($null -eq $loaded.RightSpacing) { $loaded | Add-Member -MemberType NoteProperty -Name "RightSpacing" -Value 10 -Force }
        if ($null -eq $loaded.Spacing) { $loaded | Add-Member -MemberType NoteProperty -Name "Spacing" -Value 15 -Force }
        if ($null -eq $loaded.ButtonSize) { $loaded | Add-Member -MemberType NoteProperty -Name "ButtonSize" -Value 40 -Force }
        if ($null -eq $loaded.Orientation) { $loaded | Add-Member -MemberType NoteProperty -Name "Orientation" -Value "Horizontal" -Force }
        if ($null -eq $loaded.FontColorMode) { $loaded | Add-Member -MemberType NoteProperty -Name "FontColorMode" -Value "Auto" -Force }
        if ($null -eq $loaded.CustomFontColor) { $loaded | Add-Member -MemberType NoteProperty -Name "CustomFontColor" -Value "#00FF00" -Force }
        if ($null -eq $loaded.Startup) { $loaded | Add-Member -MemberType NoteProperty -Name "Startup" -Value $true -Force }
        if ($null -eq $loaded.ShowBorders) { $loaded | Add-Member -MemberType NoteProperty -Name "ShowBorders" -Value $false -Force }
        
        if ($null -eq $loaded.ShowMusicWidget) { $loaded | Add-Member -MemberType NoteProperty -Name "ShowMusicWidget" -Value $true -Force }
        if ($null -eq $loaded.ShowMusicControls) { $loaded | Add-Member -MemberType NoteProperty -Name "ShowMusicControls" -Value $true -Force }
        if ($null -eq $loaded.MusicPosition) { $loaded | Add-Member -MemberType NoteProperty -Name "MusicPosition" -Value "Right" -Force }
        if ($null -eq $loaded.MusicFontFamily) { $loaded | Add-Member -MemberType NoteProperty -Name "MusicFontFamily" -Value "Segoe UI" -Force }
        if ($null -eq $loaded.MusicFontColorMode) { $loaded | Add-Member -MemberType NoteProperty -Name "MusicFontColorMode" -Value "Auto" -Force }
        if ($null -eq $loaded.MusicCustomColor) { $loaded | Add-Member -MemberType NoteProperty -Name "MusicCustomColor" -Value "#00FF00" -Force }
        
        if ($null -eq $loaded.Buttons) { $loaded | Add-Member -MemberType NoteProperty -Name "Buttons" -Value @() -Force }
        
        $btns = @()
        for ($i=0; $i -lt 10; $i++) {
            $btn = $null
            if ($loaded.Buttons.Count -gt $i) { $btn = $loaded.Buttons[$i] }
            if ($null -eq $btn) { $btn = New-Object PSObject }
            
            $defaultChar = if ($i -eq 9) { "0" } else { ($i + 1).ToString() }
            if ($null -eq $btn.Char -or $btn.Char -eq "") { $btn | Add-Member -MemberType NoteProperty -Name "Char" -Value $defaultChar -Force }
            if ($null -eq $btn.FontFamily -or $btn.FontFamily -eq "") { $btn | Add-Member -MemberType NoteProperty -Name "FontFamily" -Value "Segoe UI" -Force }
            if ($null -eq $btn.FontSize -or [double]$btn.FontSize -le 0) { $btn | Add-Member -MemberType NoteProperty -Name "FontSize" -Value 20.0 -Force }
            if ($null -eq $btn.FontBold) { $btn | Add-Member -MemberType NoteProperty -Name "FontBold" -Value $true -Force }
            if ($null -eq $btn.FontItalic) { $btn | Add-Member -MemberType NoteProperty -Name "FontItalic" -Value $false -Force }
            
            if ($null -eq $btn.EnLeft) { $btn | Add-Member -MemberType NoteProperty -Name "EnLeft" -Value $true -Force }
            if ($null -eq $btn.EnLeftDouble) { $btn | Add-Member -MemberType NoteProperty -Name "EnLeftDouble" -Value $false -Force }
            if ($null -eq $btn.EnRight) { $btn | Add-Member -MemberType NoteProperty -Name "EnRight" -Value $false -Force }
            if ($null -eq $btn.EnRightDouble) { $btn | Add-Member -MemberType NoteProperty -Name "EnRightDouble" -Value $false -Force }
            if ($null -eq $btn.EnMid) { $btn | Add-Member -MemberType NoteProperty -Name "EnMid" -Value $false -Force }
            
            if ($null -eq $btn.LeftActions) { $btn | Add-Member -MemberType NoteProperty -Name "LeftActions" -Value @() -Force }
            if ($null -eq $btn.LeftDoubleActions) { $btn | Add-Member -MemberType NoteProperty -Name "LeftDoubleActions" -Value @() -Force }
            if ($null -eq $btn.RightActions) { $btn | Add-Member -MemberType NoteProperty -Name "RightActions" -Value @() -Force }
            if ($null -eq $btn.RightDoubleActions) { $btn | Add-Member -MemberType NoteProperty -Name "RightDoubleActions" -Value @() -Force }
            if ($null -eq $btn.MidActions) { $btn | Add-Member -MemberType NoteProperty -Name "MidActions" -Value @() -Force }
            
            $btns += $btn
        }
        $loaded.Buttons = $btns
        return $loaded
    }
    
    function Save-Settings ($SettingsObj) { $SettingsObj | ConvertTo-Json -Depth 5 | Set-Content $settingsFile -Force }
    $global:Settings = Load-Settings

    function Execute-Action ($path) {
        if ([string]::IsNullOrWhiteSpace($path)) { return }
        $cmd = $path.Trim()
        if ($cmd -match "^<([^:]+):(.*)>$") {
            $cat = $matches[1]; $val = $matches[2]
            try {
                switch ($cat) {
                    "sys" {
                        if ($val -eq "wifi") {
                            $ns = Get-NetAdapter | Where-Object { $_.InterfaceDescription -match "Wi-Fi" -or $_.Name -match "Wi-Fi" } | Select-Object -First 1
                            if ($ns.Status -eq "Up") { Disable-NetAdapter -Name $ns.Name -Confirm:$false } else { Enable-NetAdapter -Name $ns.Name -Confirm:$false }
                        }
                        elseif ($val -eq "bt") { Start-Process "ms-settings:bluetooth" }
                        elseif ($val -match "^vol:inc:(\d+)$") { $loops = [math]::Ceiling([int]$matches[1] / 2); for($i=0; $i -lt $loops; $i++) { [Native]::keybd_event(0xAF, 0, 1, 0); [Native]::keybd_event(0xAF, 0, 3, 0) } }
                        elseif ($val -match "^vol:dec:(\d+)$") { $loops = [math]::Ceiling([int]$matches[1] / 2); for($i=0; $i -lt $loops; $i++) { [Native]::keybd_event(0xAE, 0, 1, 0); [Native]::keybd_event(0xAE, 0, 3, 0) } }
                        elseif ($val -eq "vol:mute") { [Native]::keybd_event(0xAD, 0, 1, 0); [Native]::keybd_event(0xAD, 0, 3, 0) }
                        elseif ($val -match "^bright:inc:(\d+)$") {
                            $wmio = Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightness | Select-Object -First 1
                            $cur = $wmio.CurrentBrightness; $new = $cur + [int]$matches[1]; if ($new -gt 100) { $new = 100 }; (Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods).WmiSetBrightness(1, $new)
                        }
                        elseif ($val -match "^bright:dec:(\d+)$") {
                            $wmio = Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightness | Select-Object -First 1
                            $cur = $wmio.CurrentBrightness; $new = $cur - [int]$matches[1]; if ($new -lt 0) { $new = 0 }; (Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods).WmiSetBrightness(1, $new)
                        }
                        elseif ($val -match "^bright:set:(\d+)$") {
                            $lvl = [int]$matches[1]; if ($lvl -gt 100) { $lvl = 100 }; if ($lvl -lt 0) { $lvl = 0 }
                            (Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods).WmiSetBrightness(1, $lvl)
                        }
                    }
                    "key" { [System.Windows.Forms.SendKeys]::SendWait($val) }
                    "clip" { if ($val -eq "copy") { [System.Windows.Forms.SendKeys]::SendWait("^c") } elseif ($val -eq "cut") { [System.Windows.Forms.SendKeys]::SendWait("^x") } elseif ($val -eq "paste") { [System.Windows.Forms.SendKeys]::SendWait("^v") } }
                    "nav" { if ($val -eq "back") { [Native]::keybd_event(0xA6, 0, 1, 0); [Native]::keybd_event(0xA6, 0, 3, 0) } elseif ($val -eq "forward") { [Native]::keybd_event(0xA7, 0, 1, 0); [Native]::keybd_event(0xA7, 0, 3, 0) } }
                    "media" {
                        if ($global:MediaAPIEnabled) {
                            if ($val -eq "play") { [WinMedia]::PlayPause() }
                            elseif ($val -eq "next") { [WinMedia]::Next() }
                            elseif ($val -eq "prev") { [WinMedia]::Prev() }
                        } else {
                            if ($val -eq "play") { [Native]::keybd_event(0xB3, 0, 1, 0); [Native]::keybd_event(0xB3, 0, 3, 0) }
                            elseif ($val -eq "stop") { [Native]::keybd_event(0xB2, 0, 1, 0); [Native]::keybd_event(0xB2, 0, 3, 0) }
                            elseif ($val -eq "next") { [Native]::keybd_event(0xB0, 0, 1, 0); [Native]::keybd_event(0xB0, 0, 3, 0) }
                            elseif ($val -eq "prev") { [Native]::keybd_event(0xB1, 0, 1, 0); [Native]::keybd_event(0xB1, 0, 3, 0) }
                        }
                    }
                    "exp" { Start-Process $val }
                    "web" { Start-Process $val }
                    "kill" { Stop-Process -Name $val -Force -ErrorAction SilentlyContinue }
                    "switch" { $p = Get-Process | Where-Object { $_.MainWindowTitle -eq $val } | Select-Object -First 1; if ($p) { $wshell = New-Object -ComObject wscript.shell; $wshell.AppActivate($p.Id) | Out-Null } }
                    "winql" { Show-SettingsWindow }
                }
            } catch { [System.Windows.Forms.MessageBox]::Show("Action failed: $cmd", "WinQL Engine Error", 0, 16) }
        } else {
            try { Start-Process $cmd -ErrorAction Stop } catch { [System.Windows.Forms.MessageBox]::Show("Failed to launch: $cmd", "WinQL Error", 0, 16) }
        }
    }

    $uiXAML = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="WinQL" SizeToContent="WidthAndHeight"
            WindowStyle="None" AllowsTransparency="True" Background="Transparent" 
            ShowInTaskbar="False" Opacity="1" ShowActivated="False" Focusable="False">
        <Grid Name="MainGrid">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            
            <StackPanel Name="ButtonPanel" Grid.Column="0" Grid.Row="0"/>
            
            <Grid Name="MusicContainer" Visibility="Collapsed" Background="#01000000" Cursor="Hand" Margin="0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <Border Name="CoverBorder" Grid.Column="0" Width="38" Height="38" CornerRadius="4" Margin="0,0,8,0" Background="#22888888" VerticalAlignment="Center">
                    <Grid>
                        <TextBlock Name="FallbackIcon" Text="🎵" FontSize="18" VerticalAlignment="Center" HorizontalAlignment="Center" Foreground="Gray" Visibility="Collapsed"/>
                        <Border CornerRadius="4">
                            <Border.Background>
                                <ImageBrush x:Name="CoverBrush" Stretch="UniformToFill"/>
                            </Border.Background>
                        </Border>
                    </Grid>
                </Border>
                
                <StackPanel Name="MusicInfoPanel" Grid.Column="1" VerticalAlignment="Center" Width="130">
                    <Canvas Name="CanvasTitle" ClipToBounds="True" Height="18" Width="130">
                        <TextBlock Name="SongTitle" FontSize="13" FontWeight="Bold" Canvas.Left="0"/>
                    </Canvas>
                    <Canvas Name="CanvasArtist" ClipToBounds="True" Height="16" Width="130" Margin="0,2,0,0">
                        <TextBlock Name="SongArtist" FontSize="11" Opacity="0.8" Canvas.Left="0"/>
                    </Canvas>
                </StackPanel>
                
                <StackPanel Name="MusicControls" Grid.Column="2" Orientation="Horizontal" Visibility="Collapsed" VerticalAlignment="Center" Margin="8,0,0,0">
                    <TextBlock Name="BtnPrev" Text="⏮" FontSize="18" Cursor="Hand" Margin="0,0,8,0" />
                    <TextBlock Name="BtnPlay" Text="⏸" FontSize="18" Cursor="Hand" Margin="0,0,8,0" />
                    <TextBlock Name="BtnNext" Text="⏭" FontSize="18" Cursor="Hand" />
                </StackPanel>
            </Grid>
        </Grid>
    </Window>
"@

    function Update-Window-Position {
        if (-not $script:hwnd -or $script:hwnd -eq [IntPtr]::Zero) { return }
        
        $hTaskbar = [Native]::FindWindow("Shell_TrayWnd", $null)
        if ($hTaskbar -eq [IntPtr]::Zero) { return }

        if ($null -ne $script:window) { $script:window.UpdateLayout() }
        
        $hTray = [Native]::GetTrayHandle($hTaskbar)
        $tbRect = New-Object Native+RECT
        [Native]::GetClientRect($hTaskbar, [ref]$tbRect)
        
        $trayRect = New-Object Native+RECT
        if ($hTray -ne [IntPtr]::Zero) {
            [Native]::GetWindowRect($hTray, [ref]$trayRect)
            [Native]::MapWindowPoints([IntPtr]::Zero, $hTaskbar, [ref]$trayRect, 2) | Out-Null
        } else {
            $trayRect.left = $tbRect.right
            $trayRect.top = $tbRect.bottom
        }

        $dpiX = 1.0; $dpiY = 1.0
        try {
            $source = [System.Windows.PresentationSource]::FromVisual($script:window)
            if ($source -and $source.CompositionTarget) {
                $dpiX = $source.CompositionTarget.TransformToDevice.M11
                $dpiY = $source.CompositionTarget.TransformToDevice.M22
            }
        } catch {}

        $logicalW = $script:MainGrid.ActualWidth
        $logicalH = $script:MainGrid.ActualHeight

        if ($logicalW -eq 0) { $logicalW = $global:Settings.ButtonSize * $global:Settings.BtnCount }
        if ($logicalH -eq 0) { $logicalH = $global:Settings.ButtonSize }

        $pw = [int]($logicalW * $dpiX)
        $ph = [int]($logicalH * $dpiY)

        $tbW = $tbRect.right - $tbRect.left
        $tbH = $tbRect.bottom - $tbRect.top

        $edge = [Native]::GetTaskbarEdge()
        $align = $global:Settings.Alignment

        $taskbarAl = 0
        try { $taskbarAl = Get-ItemPropertyValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -ErrorAction SilentlyContinue } catch {}
        if ($taskbarAl -eq $null) { $taskbarAl = 0 }
        
        if (($edge -eq 1 -or $edge -eq 3) -and $taskbarAl -eq 1 -and $align -eq "Center") { $align = "Right" }
        if ($edge -eq 0 -and $align -eq "Left") { $align = "Center" }

        $x = 0; $y = 0

        if ($edge -eq 1 -or $edge -eq 3) { 
            $y = [int](($tbH - $ph) / 2)
            if ($align -eq "Left") { $x = [int]($global:Settings.LeftSpacing * $dpiX) } 
            elseif ($align -eq "Right") { $x = $trayRect.left - $pw - [int]($global:Settings.RightSpacing * $dpiX) } 
            else { $x = [int](($tbW - $pw) / 2) }
        } else { 
            $x = [int](($tbW - $pw) / 2)
            if ($align -eq "Left") { $y = [int]($global:Settings.LeftSpacing * $dpiY) } 
            elseif ($align -eq "Right") { $y = $trayRect.top - $ph - [int]($global:Settings.RightSpacing * $dpiY) } 
            else { $y = [int](($tbH - $ph) / 2) }
        }

        if ($x -lt 0) { $x = 0 }
        if ($y -lt 0) { $y = 0 }

        [Native]::SetWindowPos($script:hwnd, [IntPtr]::Zero, $x, $y, $pw, $ph, 0x0004) | Out-Null
    }

    function Render-Layout {
        if ($null -eq $script:ButtonPanel) { return }
        $script:ButtonPanel.Children.Clear()
        
        if ($global:Settings.Orientation -eq "Vertical") { 
            $script:ButtonPanel.Orientation = [System.Windows.Controls.Orientation]::Vertical
            if ($global:Settings.MusicPosition -eq "Left") { 
                [System.Windows.Controls.Grid]::SetColumn($script:MusicContainer, 0)
                [System.Windows.Controls.Grid]::SetRow($script:MusicContainer, 0)
                [System.Windows.Controls.Grid]::SetColumn($script:ButtonPanel, 0)
                [System.Windows.Controls.Grid]::SetRow($script:ButtonPanel, 1)
                $script:MusicContainer.Margin = New-Object System.Windows.Thickness(0, 0, 0, $global:Settings.Spacing)
            } else {
                [System.Windows.Controls.Grid]::SetColumn($script:ButtonPanel, 0)
                [System.Windows.Controls.Grid]::SetRow($script:ButtonPanel, 0)
                [System.Windows.Controls.Grid]::SetColumn($script:MusicContainer, 0)
                [System.Windows.Controls.Grid]::SetRow($script:MusicContainer, 1)
                $script:MusicContainer.Margin = New-Object System.Windows.Thickness(0, $global:Settings.Spacing, 0, 0)
            }
        } else { 
            $script:ButtonPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
            if ($global:Settings.MusicPosition -eq "Left") {
                [System.Windows.Controls.Grid]::SetColumn($script:MusicContainer, 0)
                [System.Windows.Controls.Grid]::SetRow($script:MusicContainer, 0)
                [System.Windows.Controls.Grid]::SetColumn($script:ButtonPanel, 1)
                [System.Windows.Controls.Grid]::SetRow($script:ButtonPanel, 0)
                $script:MusicContainer.Margin = New-Object System.Windows.Thickness(0, 0, $global:Settings.Spacing, 0)
            } else {
                [System.Windows.Controls.Grid]::SetColumn($script:ButtonPanel, 0)
                [System.Windows.Controls.Grid]::SetRow($script:ButtonPanel, 0)
                [System.Windows.Controls.Grid]::SetColumn($script:MusicContainer, 1)
                [System.Windows.Controls.Grid]::SetRow($script:MusicContainer, 0)
                $script:MusicContainer.Margin = New-Object System.Windows.Thickness($global:Settings.Spacing, 0, 0, 0)
            }
        }
        
        $script:SongTitle.FontFamily = New-Object System.Windows.Media.FontFamily($global:Settings.MusicFontFamily)
        $script:SongArtist.FontFamily = New-Object System.Windows.Media.FontFamily($global:Settings.MusicFontFamily)

        $brushConv = New-Object System.Windows.Media.BrushConverter
        $fcMode = $global:Settings.FontColorMode
        if ($fcMode -eq "Auto") { $fcHex = Get-ThemeColor }
        elseif ($fcMode -eq "White") { $fcHex = "#FFFFFF" }
        elseif ($fcMode -eq "Black") { $fcHex = "#000000" }
        else { $fcHex = $global:Settings.CustomFontColor }
        try { $fontBrush = $brushConv.ConvertFromString($fcHex) } catch { $fontBrush = [System.Windows.Media.Brushes]::White }

        if ($global:Settings.ShowMusicControls) { $script:MusicControls.Visibility = 'Visible' } 
        else { $script:MusicControls.Visibility = 'Collapsed' }

        for ($i=0; $i -lt $global:Settings.BtnCount; $i++) {
            $btnDef = $global:Settings.Buttons[$i]
            
            $border = New-Object System.Windows.Controls.Border
            $border.Background = $brushConv.ConvertFromString("#01000000")
            $border.Cursor = [System.Windows.Input.Cursors]::Hand
            $border.Width = $global:Settings.ButtonSize
            $border.Height = $global:Settings.ButtonSize
            
            if ($global:Settings.ShowBorders) {
                $border.BorderBrush = [System.Windows.Media.Brushes]::Red
                $border.BorderThickness = New-Object System.Windows.Thickness(1)
            } else {
                $border.BorderThickness = New-Object System.Windows.Thickness(0)
            }
            
            if ($i -gt 0) { 
                if ($global:Settings.Orientation -eq "Vertical") { $border.Margin = New-Object System.Windows.Thickness(0, $global:Settings.Spacing, 0, 0) } 
                else { $border.Margin = New-Object System.Windows.Thickness($global:Settings.Spacing, 0, 0, 0) }
            }
            
            $tb = New-Object System.Windows.Controls.TextBlock
            $tb.Text = $btnDef.Char
            $tb.FontSize = $btnDef.FontSize
            $tb.FontFamily = New-Object System.Windows.Media.FontFamily($btnDef.FontFamily)
            $tb.Foreground = $fontBrush
            $tb.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $tb.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
            
            if ($btnDef.FontBold) { $tb.FontWeight = [System.Windows.FontWeights]::Bold } else { $tb.FontWeight = [System.Windows.FontWeights]::Normal }
            if ($btnDef.FontItalic) { $tb.FontStyle = [System.Windows.FontStyles]::Italic } else { $tb.FontStyle = [System.Windows.FontStyles]::Normal }
            
            $border.Child = $tb
            
            $clickState = @{
                Timer = New-Object System.Windows.Threading.DispatcherTimer
                ClickCount = 0
                BtnType = ""
                Def = $btnDef
            }
            $clickState.Timer.Interval = [TimeSpan]::FromMilliseconds(300)
            $clickState.Timer.Add_Tick({
                $state = $this.Tag
                $state.Timer.Stop()
                $btnType = $state.BtnType
                $def = $state.Def
                $count = $state.ClickCount
                $state.ClickCount = 0
                
                $targetPaths = @()
                if ($count -eq 1) {
                    if ($btnType -eq 'Left' -and $def.EnLeft) { $targetPaths = $def.LeftActions }
                    elseif ($btnType -eq 'Right' -and $def.EnRight) { $targetPaths = $def.RightActions }
                    elseif ($btnType -eq 'Middle' -and $def.EnMid) { $targetPaths = $def.MidActions }
                } elseif ($count -ge 2) {
                    if ($btnType -eq 'Left' -and $def.EnLeftDouble) { $targetPaths = $def.LeftDoubleActions }
                    elseif ($btnType -eq 'Right' -and $def.EnRightDouble) { $targetPaths = $def.RightDoubleActions }
                    elseif ($btnType -eq 'Left' -and $def.EnLeft) { $targetPaths = $def.LeftActions }
                    elseif ($btnType -eq 'Right' -and $def.EnRight) { $targetPaths = $def.RightActions }
                    elseif ($btnType -eq 'Middle' -and $def.EnMid) { $targetPaths = $def.MidActions }
                }
                foreach ($p in $targetPaths) { Execute-Action $p }
            })
            $clickState.Timer.Tag = $clickState
            
            $border.Tag = $clickState
            $border.Add_PreviewMouseDown({
                param($sender, $e)
                $state = $sender.Tag
                $btnTypeStr = $e.ChangedButton.ToString()
                if ($state.BtnType -ne $btnTypeStr -and $state.ClickCount -gt 0) { $state.ClickCount = 0 }
                $state.BtnType = $btnTypeStr
                $state.ClickCount++
                $state.Timer.Stop()
                $state.Timer.Start()
            })
            
            $script:ButtonPanel.Children.Add($border) | Out-Null
        }
        Update-Window-Position
    }

    function Tick-Marquee ($tb, $canvas) {
        if ($tb.ActualWidth -gt $canvas.ActualWidth) {
            $left = [System.Windows.Controls.Canvas]::GetLeft($tb)
            $left -= 1.0
            if ($left -lt -($tb.ActualWidth)) { $left = $canvas.ActualWidth }
            [System.Windows.Controls.Canvas]::SetLeft($tb, $left)
        } else {
            [System.Windows.Controls.Canvas]::SetLeft($tb, 0)
        }
    }

    # --- ACTION BUILDER DIALOG ---
    function Show-ActionBuilder {
        $abXAML = @"
        <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="Action Builder" Height="380" Width="420" WindowStartupLocation="CenterScreen" Topmost="True" ResizeMode="NoResize">
            <StackPanel Margin="15">
                <TextBlock Text="Select Action Category:" FontWeight="Bold" Margin="0,0,0,5"/>
                <ComboBox Name="cmbCat" Margin="0,0,0,15"/>
                
                <TextBlock Name="lblSub" Text="Specific Action:" FontWeight="Bold" Margin="0,0,0,5" Visibility="Collapsed"/>
                <ComboBox Name="cmbSub" Margin="0,0,0,10" Visibility="Collapsed"/>
                
                <TextBlock Name="lblVal" Text="Value:" FontWeight="Bold" Margin="0,0,0,5" Visibility="Collapsed"/>
                <WrapPanel Name="pnlKeys" Visibility="Collapsed" Margin="0,0,0,10">
                    <Button Name="btnCtrl" Content="Ctrl (^)" Margin="0,0,5,5" Padding="5,2" Cursor="Hand"/>
                    <Button Name="btnAlt" Content="Alt (%)" Margin="0,0,5,5" Padding="5,2" Cursor="Hand"/>
                    <Button Name="btnShift" Content="Shift (+)" Margin="0,0,5,5" Padding="5,2" Cursor="Hand"/>
                    <Button Name="btnCaps" Content="Caps Lock" Margin="0,0,5,5" Padding="5,2" Cursor="Hand"/>
                    <Button Name="btnNum" Content="Num Lock" Margin="0,0,5,5" Padding="5,2" Cursor="Hand"/>
                </WrapPanel>
                
                <Grid Name="gridVal" Margin="0,0,0,15" Visibility="Collapsed">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <TextBox Name="txtVal" Grid.Column="0" VerticalContentAlignment="Center"/>
                    <ComboBox Name="cmbDynamic" Grid.Column="0" Visibility="Collapsed"/>
                    <Button Name="btnBrowse" Grid.Column="1" Content="Browse..." Padding="10,2" Margin="5,0,0,0" Visibility="Collapsed" Cursor="Hand"/>
                </Grid>
                
                <Button Name="btnOk" Content="Add Action" Padding="10,5" FontWeight="Bold" Cursor="Hand" Margin="0,10,0,0"/>
            </StackPanel>
        </Window>
"@
        $abReader = New-Object System.IO.StringReader($abXAML)
        $abWin = [System.Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create($abReader))
        
        $cmbCat = $abWin.FindName("cmbCat"); $cmbSub = $abWin.FindName("cmbSub")
        $txtVal = $abWin.FindName("txtVal"); $btnOk = $abWin.FindName("btnOk")
        $cmbDynamic = $abWin.FindName("cmbDynamic"); $btnBrowse = $abWin.FindName("btnBrowse")
        $lblVal = $abWin.FindName("lblVal"); $lblSub = $abWin.FindName("lblSub")
        $gridVal = $abWin.FindName("gridVal"); $pnlKeys = $abWin.FindName("pnlKeys")
        
        $script:builtAction = $null
        
        $abWin.FindName("btnCtrl").Add_Click({ $txtVal.Text += "^" })
        $abWin.FindName("btnAlt").Add_Click({ $txtVal.Text += "%" })
        $abWin.FindName("btnShift").Add_Click({ $txtVal.Text += "+" })
        $abWin.FindName("btnCaps").Add_Click({ $txtVal.Text += "{CAPSLOCK}" })
        $abWin.FindName("btnNum").Add_Click({ $txtVal.Text += "{NUMLOCK}" })

        "System","Keyboard Shortcut","Clipboard","Navigation","Explorer / File / Folder","Media Control","Open App / Switch Window","Open Website","Kill Process","Open WinQL Settings" | ForEach-Object { $cmbCat.Items.Add($_) | Out-Null }
        
        $cmbCat.Add_SelectionChanged({
            param($sender, $e)
            $cat = Get-ComboText $sender
            if ([string]::IsNullOrWhiteSpace($cat)) { return }
            
            $cmbSub.Items.Clear()
            $cmbSub.Visibility = "Collapsed"; $lblSub.Visibility = "Collapsed"
            $lblVal.Visibility = "Collapsed"; $gridVal.Visibility = "Collapsed"
            $txtVal.Visibility = "Collapsed"; $cmbDynamic.Visibility = "Collapsed"; $btnBrowse.Visibility = "Collapsed"
            $pnlKeys.Visibility = "Collapsed"

            switch ($cat) {
                "System" { 
                    $lblSub.Visibility = "Visible"; $cmbSub.Visibility = "Visible"
                    "Toggle Wi-Fi","Bluetooth Settings","Increase Volume by X%","Decrease Volume by X%","Mute / Unmute Volume","Increase Brightness by X%","Decrease Brightness by X%","Set Brightness to X%" | ForEach-Object { $cmbSub.Items.Add($_) | Out-Null }
                    $cmbSub.SelectedIndex = 0
                }
                "Keyboard Shortcut" {
                    $lblVal.Visibility = "Visible"; $gridVal.Visibility = "Visible"; $txtVal.Visibility = "Visible"; $pnlKeys.Visibility = "Visible"
                    $lblVal.Text = "Keystroke (Use buttons to insert modifiers):"; $txtVal.Text = "{ENTER}"
                }
                "Clipboard" {
                    $lblSub.Visibility = "Visible"; $cmbSub.Visibility = "Visible"
                    "Copy","Cut","Paste" | ForEach-Object { $cmbSub.Items.Add($_) | Out-Null }
                    $cmbSub.SelectedIndex = 0
                }
                "Navigation" {
                    $lblSub.Visibility = "Visible"; $cmbSub.Visibility = "Visible"
                    "Forward","Backward" | ForEach-Object { $cmbSub.Items.Add($_) | Out-Null }
                    $cmbSub.SelectedIndex = 0
                }
                "Media Control" {
                    $lblSub.Visibility = "Visible"; $cmbSub.Visibility = "Visible"
                    "Play / Pause","Stop","Next Track","Previous Track" | ForEach-Object { $cmbSub.Items.Add($_) | Out-Null }
                    $cmbSub.SelectedIndex = 0
                }
                "Explorer / File / Folder" {
                    $lblSub.Visibility = "Visible"; $cmbSub.Visibility = "Visible"
                    "Open File","Open Folder" | ForEach-Object { $cmbSub.Items.Add($_) | Out-Null }
                    $cmbSub.SelectedIndex = 0
                }
                "Open App / Switch Window" {
                    $lblSub.Visibility = "Visible"; $cmbSub.Visibility = "Visible"
                    "Launch Start Menu App","Switch to Open Window" | ForEach-Object { $cmbSub.Items.Add($_) | Out-Null }
                    $cmbSub.SelectedIndex = 0
                }
                "Open Website" {
                    $lblVal.Visibility = "Visible"; $gridVal.Visibility = "Visible"; $txtVal.Visibility = "Visible"
                    $lblVal.Text = "Website URL:"; $txtVal.Text = "https://google.com"
                }
                "Kill Process" {
                    $lblSub.Visibility = "Visible"; $cmbSub.Visibility = "Visible"
                    "Select Process to Kill" | ForEach-Object { $cmbSub.Items.Add($_) | Out-Null }
                    $cmbSub.SelectedIndex = 0
                }
                "Open WinQL Settings" { }
            }
        })
        
        $cmbSub.Add_SelectionChanged({
            param($sender, $e)
            $sub = Get-ComboText $sender
            if ([string]::IsNullOrWhiteSpace($sub)) { return }
            
            $lblVal.Visibility = "Collapsed"; $gridVal.Visibility = "Collapsed"
            $txtVal.Visibility = "Collapsed"; $cmbDynamic.Visibility = "Collapsed"; $btnBrowse.Visibility = "Collapsed"
            
            if ($sub -match "X%") {
                $lblVal.Visibility = "Visible"; $gridVal.Visibility = "Visible"; $txtVal.Visibility = "Visible"
                $lblVal.Text = "Enter Value (%) :"
                if ($txtVal.Text -eq "") { $txtVal.Text = "10" }
            }
            elseif ($sub -eq "Open File" -or $sub -eq "Open Folder") {
                $lblVal.Visibility = "Visible"; $gridVal.Visibility = "Visible"
                $txtVal.Visibility = "Visible"; $btnBrowse.Visibility = "Visible"
                $lblVal.Text = "Path:"
            }
            elseif ($sub -eq "Launch Start Menu App") {
                $lblVal.Visibility = "Visible"; $gridVal.Visibility = "Visible"; $cmbDynamic.Visibility = "Visible"
                $lblVal.Text = "Select App:"
                $cmbDynamic.Items.Clear()
                $paths = @("$env:ProgramData\Microsoft\Windows\Start Menu\Programs", "$env:APPDATA\Microsoft\Windows\Start Menu\Programs")
                Get-ChildItem -Path $paths -Filter "*.lnk" -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -Unique | Sort-Object | ForEach-Object { $cmbDynamic.Items.Add($_) | Out-Null }
                if ($cmbDynamic.Items.Count -gt 0) { $cmbDynamic.SelectedIndex = 0 }
            }
            elseif ($sub -eq "Switch to Open Window") {
                $lblVal.Visibility = "Visible"; $gridVal.Visibility = "Visible"; $cmbDynamic.Visibility = "Visible"
                $lblVal.Text = "Select Window:"
                $cmbDynamic.Items.Clear()
                Get-Process | Where-Object { $_.MainWindowTitle -ne "" } | Select-Object -ExpandProperty MainWindowTitle -Unique | Sort-Object | ForEach-Object { $cmbDynamic.Items.Add($_) | Out-Null }
                if ($cmbDynamic.Items.Count -gt 0) { $cmbDynamic.SelectedIndex = 0 }
            }
            elseif ($sub -eq "Select Process to Kill") {
                $lblVal.Visibility = "Visible"; $gridVal.Visibility = "Visible"; $cmbDynamic.Visibility = "Visible"
                $lblVal.Text = "Select Process:"
                $cmbDynamic.Items.Clear()
                Get-Process | Select-Object -ExpandProperty Name -Unique | Sort-Object | ForEach-Object { $cmbDynamic.Items.Add($_) | Out-Null }
                if ($cmbDynamic.Items.Count -gt 0) { $cmbDynamic.SelectedIndex = 0 }
            }
        })
        
        $btnBrowse.Add_Click({
            $sub = Get-ComboText $cmbSub
            if ($sub -eq "Open File") {
                $fd = New-Object System.Windows.Forms.OpenFileDialog
                if ($fd.ShowDialog() -eq 'OK') { $txtVal.Text = $fd.FileName }
            } else {
                $fd = New-Object System.Windows.Forms.FolderBrowserDialog
                if ($fd.ShowDialog() -eq 'OK') { $txtVal.Text = $fd.SelectedPath }
            }
        })
        
        $cmbCat.SelectedIndex = 0
        
        $btnOk.Add_Click({
            $cat = Get-ComboText $cmbCat
            $sub = Get-ComboText $cmbSub
            $val = if ($txtVal.Visibility -eq [System.Windows.Visibility]::Visible) { $txtVal.Text } elseif ($cmbDynamic.Visibility -eq [System.Windows.Visibility]::Visible) { Get-ComboText $cmbDynamic } else { "" }
            
            if ($cat -eq "System") {
                if ($sub -eq "Toggle Wi-Fi") { $script:builtAction = "<sys:wifi>" }
                elseif ($sub -eq "Bluetooth Settings") { $script:builtAction = "<sys:bt>" }
                elseif ($sub -eq "Increase Volume by X%") { $script:builtAction = "<sys:vol:inc:$val>" }
                elseif ($sub -eq "Decrease Volume by X%") { $script:builtAction = "<sys:vol:dec:$val>" }
                elseif ($sub -eq "Mute / Unmute Volume") { $script:builtAction = "<sys:vol:mute>" }
                elseif ($sub -eq "Increase Brightness by X%") { $script:builtAction = "<sys:bright:inc:$val>" }
                elseif ($sub -eq "Decrease Brightness by X%") { $script:builtAction = "<sys:bright:dec:$val>" }
                elseif ($sub -eq "Set Brightness to X%") { $script:builtAction = "<sys:bright:set:$val>" }
            }
            elseif ($cat -eq "Keyboard Shortcut") { $script:builtAction = "<key:$val>" }
            elseif ($cat -eq "Clipboard") {
                if ($sub -eq "Copy") { $script:builtAction = "<clip:copy>" } elseif ($sub -eq "Cut") { $script:builtAction = "<clip:cut>" } elseif ($sub -eq "Paste") { $script:builtAction = "<clip:paste>" }
            }
            elseif ($cat -eq "Navigation") {
                if ($sub -eq "Backward") { $script:builtAction = "<nav:back>" } elseif ($sub -eq "Forward") { $script:builtAction = "<nav:forward>" }
            }
            elseif ($cat -eq "Media Control") {
                if ($sub -eq "Play / Pause") { $script:builtAction = "<media:play>" } elseif ($sub -eq "Stop") { $script:builtAction = "<media:stop>" } elseif ($sub -eq "Next Track") { $script:builtAction = "<media:next>" } elseif ($sub -eq "Previous Track") { $script:builtAction = "<media:prev>" }
            }
            elseif ($cat -eq "Explorer / File / Folder") { $script:builtAction = "<exp:$val>" }
            elseif ($cat -eq "Open App / Switch Window") {
                if ($sub -eq "Launch Start Menu App") { $script:builtAction = "<exp:$val>" } elseif ($sub -eq "Switch to Open Window") { $script:builtAction = "<switch:$val>" }
            }
            elseif ($cat -eq "Open Website") { $script:builtAction = "<web:$val>" }
            elseif ($cat -eq "Kill Process") { $script:builtAction = "<kill:$val>" }
            elseif ($cat -eq "Open WinQL Settings") { $script:builtAction = "<winql:settings>" }
            
            $abWin.Close()
        })
        
        $abWin.ShowDialog() | Out-Null
        return $script:builtAction
    }

    function Add-ActionTextBox ($parentPanel, $text) {
        $grid = New-Object System.Windows.Controls.Grid
        $grid.Margin = New-Object System.Windows.Thickness(0,0,0,5)
        $cd1 = New-Object System.Windows.Controls.ColumnDefinition; $cd1.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
        $cd2 = New-Object System.Windows.Controls.ColumnDefinition; $cd2.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Auto)
        $cd3 = New-Object System.Windows.Controls.ColumnDefinition; $cd3.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Auto)
        $grid.ColumnDefinitions.Add($cd1); $grid.ColumnDefinitions.Add($cd2); $grid.ColumnDefinitions.Add($cd3)
        
        $tb = New-Object System.Windows.Controls.TextBox
        $tb.Text = $text; $tb.Padding = New-Object System.Windows.Thickness(2)
        [System.Windows.Controls.Grid]::SetColumn($tb, 0)
        $tb.Add_TextChanged($script:updateAction)
        
        $btnB = New-Object System.Windows.Controls.Button
        $btnB.Content = "Build"; $btnB.Padding = New-Object System.Windows.Thickness(10,0,10,0); $btnB.Margin = New-Object System.Windows.Thickness(5,0,0,0); $btnB.Cursor = [System.Windows.Input.Cursors]::Hand
        [System.Windows.Controls.Grid]::SetColumn($btnB, 1)
        $btnB.Tag = $tb
        $btnB.Add_Click({
            param($sender, $e)
            $res = Show-ActionBuilder
            if ($res) { $sender.Tag.Text = $res; & $script:updateAction }
        })
        
        $btnD = New-Object System.Windows.Controls.Button
        $btnD.Content = "Delete"; $btnD.Padding = New-Object System.Windows.Thickness(10,0,10,0); $btnD.Margin = New-Object System.Windows.Thickness(5,0,0,0); $btnD.Cursor = [System.Windows.Input.Cursors]::Hand
        [System.Windows.Controls.Grid]::SetColumn($btnD, 2)
        $btnD.Tag = @{ Panel=$parentPanel; Grid=$grid }
        $btnD.Add_Click({
            param($sender, $e)
            $data = $sender.Tag
            $data.Panel.Children.Remove($data.Grid)
            & $script:updateAction
        })
        
        $grid.Children.Add($tb) | Out-Null; $grid.Children.Add($btnB) | Out-Null; $grid.Children.Add($btnD) | Out-Null
        $parentPanel.Children.Add($grid) | Out-Null
    }

    $script:updateAction = {
        if ($script:isLoading) { return }
        
        $global:Settings.BtnCount = $script:sldCount.Value
        $global:Settings.Alignment = Get-ComboText $script:cmbAlignment
        $global:Settings.LeftSpacing = $script:sldLeftSpacing.Value
        $global:Settings.RightSpacing = $script:sldRightSpacing.Value
        $global:Settings.Spacing = $script:sldSpacing.Value
        $global:Settings.Orientation = Get-ComboText $script:cmbOrientation
        $global:Settings.FontColorMode = Get-ComboText $script:cmbColor
        $global:Settings.CustomFontColor = $script:txtCustomColor.Text
        $global:Settings.Startup = ($script:chkStartup.IsChecked -eq $true)
        $global:Settings.ShowBorders = ($script:chkBorders.IsChecked -eq $true)
        
        $global:Settings.ShowMusicWidget = ($script:chkSong.IsChecked -eq $true)
        $global:Settings.ShowMusicControls = ($script:chkControls.IsChecked -eq $true)
        $global:Settings.MusicPosition = Get-ComboText $script:cmbMusicPos
        $global:Settings.MusicFontColorMode = Get-ComboText $script:cmbMusicColor
        $global:Settings.MusicCustomColor = $script:txtMusicCustomColor.Text

        try {
            $parsedSize = [int]$script:txtBtnSize.Text
            if ($parsedSize -gt 5) { $global:Settings.ButtonSize = $parsedSize }
        } catch {}

        for ($i=0; $i -lt 10; $i++) {
            $tab = $script:setWindow.FindName("tabBtn_$i")
            if ($i -lt $global:Settings.BtnCount) { $tab.Visibility = 'Visible' } else { $tab.Visibility = 'Collapsed' }

            $global:Settings.Buttons[$i].Char = $script:setWindow.FindName("txtChar_$i").Text
            
            $global:Settings.Buttons[$i].EnLeft = ($script:setWindow.FindName("chkLeft_$i").IsChecked -eq $true)
            $global:Settings.Buttons[$i].EnLeftDouble = ($script:setWindow.FindName("chkLeftDouble_$i").IsChecked -eq $true)
            $global:Settings.Buttons[$i].EnRight = ($script:setWindow.FindName("chkRight_$i").IsChecked -eq $true)
            $global:Settings.Buttons[$i].EnRightDouble = ($script:setWindow.FindName("chkRightDouble_$i").IsChecked -eq $true)
            $global:Settings.Buttons[$i].EnMid = ($script:setWindow.FindName("chkMid_$i").IsChecked -eq $true)
            
            if ($global:Settings.Buttons[$i].EnLeft) { $script:setWindow.FindName("pnlLeft_$i").Visibility='Visible' } else { $script:setWindow.FindName("pnlLeft_$i").Visibility='Collapsed' }
            if ($global:Settings.Buttons[$i].EnLeftDouble) { $script:setWindow.FindName("pnlLeftDouble_$i").Visibility='Visible' } else { $script:setWindow.FindName("pnlLeftDouble_$i").Visibility='Collapsed' }
            if ($global:Settings.Buttons[$i].EnRight) { $script:setWindow.FindName("pnlRight_$i").Visibility='Visible' } else { $script:setWindow.FindName("pnlRight_$i").Visibility='Collapsed' }
            if ($global:Settings.Buttons[$i].EnRightDouble) { $script:setWindow.FindName("pnlRightDouble_$i").Visibility='Visible' } else { $script:setWindow.FindName("pnlRightDouble_$i").Visibility='Collapsed' }
            if ($global:Settings.Buttons[$i].EnMid) { $script:setWindow.FindName("pnlMid_$i").Visibility='Visible' } else { $script:setWindow.FindName("pnlMid_$i").Visibility='Collapsed' }
            
            $hasAny = ($global:Settings.Buttons[$i].EnLeft -or $global:Settings.Buttons[$i].EnLeftDouble -or $global:Settings.Buttons[$i].EnRight -or $global:Settings.Buttons[$i].EnRightDouble -or $global:Settings.Buttons[$i].EnMid)
            if ($hasAny) { $script:setWindow.FindName("lblNoActions_$i").Visibility='Collapsed' } else { $script:setWindow.FindName("lblNoActions_$i").Visibility='Visible' }

            $lPaths = @(); $boxL = $script:setWindow.FindName("boxLeft_$i"); if ($null -ne $boxL -and $null -ne $boxL.Children) { foreach($g in $boxL.Children) { if ($g -is [System.Windows.Controls.Grid]) { foreach($c in $g.Children) { if ($c -is [System.Windows.Controls.TextBox]) { $lPaths += $c.Text } } } } }
            $ldPaths = @(); $boxLD = $script:setWindow.FindName("boxLeftDouble_$i"); if ($null -ne $boxLD -and $null -ne $boxLD.Children) { foreach($g in $boxLD.Children) { if ($g -is [System.Windows.Controls.Grid]) { foreach($c in $g.Children) { if ($c -is [System.Windows.Controls.TextBox]) { $ldPaths += $c.Text } } } } }
            $rPaths = @(); $boxR = $script:setWindow.FindName("boxRight_$i"); if ($null -ne $boxR -and $null -ne $boxR.Children) { foreach($g in $boxR.Children) { if ($g -is [System.Windows.Controls.Grid]) { foreach($c in $g.Children) { if ($c -is [System.Windows.Controls.TextBox]) { $rPaths += $c.Text } } } } }
            $rdPaths = @(); $boxRD = $script:setWindow.FindName("boxRightDouble_$i"); if ($null -ne $boxRD -and $null -ne $boxRD.Children) { foreach($g in $boxRD.Children) { if ($g -is [System.Windows.Controls.Grid]) { foreach($c in $g.Children) { if ($c -is [System.Windows.Controls.TextBox]) { $rdPaths += $c.Text } } } } }
            $mPaths = @(); $boxM = $script:setWindow.FindName("boxMid_$i"); if ($null -ne $boxM -and $null -ne $boxM.Children) { foreach($g in $boxM.Children) { if ($g -is [System.Windows.Controls.Grid]) { foreach($c in $g.Children) { if ($c -is [System.Windows.Controls.TextBox]) { $mPaths += $c.Text } } } } }
            
            $global:Settings.Buttons[$i].LeftActions = $lPaths
            $global:Settings.Buttons[$i].LeftDoubleActions = $ldPaths
            $global:Settings.Buttons[$i].RightActions = $rPaths
            $global:Settings.Buttons[$i].RightDoubleActions = $rdPaths
            $global:Settings.Buttons[$i].MidActions = $mPaths
        }
        
        $script:lastSong = ""
        Save-Settings $global:Settings
        Render-Layout
    }

    function Show-SettingsWindow {
        if ($script:isSettingsOpen) { return }
        $script:isSettingsOpen = $true
        $script:isLoading = $true
        
        $global:Settings = Load-Settings
        
        $dynamicTabs = ""
        for ($i=0; $i -lt 10; $i++) {
            $num = $i + 1
            $dynamicTabs += @"
            <TabItem Name="tabBtn_$i" Header="Btn $num">
                <TabControl Margin="5" TabStripPlacement="Bottom">
                    <TabItem Header="Style">
                        <StackPanel Margin="10">
                            <TextBlock Text="Character (1 Char):" FontWeight="Bold" Margin="0,0,0,5"/>
                            <TextBox Name="txtChar_$i" MaxLength="1" Width="50" HorizontalAlignment="Left" Margin="0,0,0,15" Padding="4" FontSize="16" FontFamily="Consolas"/>
                            
                            <TextBlock Text="Font Settings:" FontWeight="Bold" Margin="0,0,0,5"/>
                            <StackPanel Orientation="Horizontal">
                                <Button Name="btnFont_$i" Content="Choose Font..." Padding="10,4" Margin="0,0,10,0" Cursor="Hand"/>
                                <TextBlock Name="lblFont_$i" VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/>
                            </StackPanel>
                        </StackPanel>
                    </TabItem>
                    <TabItem Header="Clicks">
                        <StackPanel Margin="10">
                            <TextBlock Text="Enable the following mouse actions:" FontWeight="Bold" Margin="0,0,0,10"/>
                            <CheckBox Name="chkLeft_$i" Content="Left Single Click" Margin="0,5"/>
                            <CheckBox Name="chkLeftDouble_$i" Content="Left Double Click" Margin="0,5"/>
                            <CheckBox Name="chkRight_$i" Content="Right Single Click" Margin="0,5"/>
                            <CheckBox Name="chkRightDouble_$i" Content="Right Double Click" Margin="0,5"/>
                            <CheckBox Name="chkMid_$i" Content="Middle Click" Margin="0,5"/>
                        </StackPanel>
                    </TabItem>
                    <TabItem Header="Actions">
                        <ScrollViewer VerticalScrollBarVisibility="Auto">
                            <StackPanel Margin="10">
                                <TextBlock Name="lblNoActions_$i" Text="Please enable clicks in the 'Clicks' tab." FontStyle="Italic" Foreground="Gray"/>
                                
                                <StackPanel Name="pnlLeft_$i" Visibility="Collapsed" Margin="0,0,0,15">
                                    <TextBlock Text="Left Single Click Actions:" FontWeight="Bold" Margin="0,0,0,5"/>
                                    <StackPanel Name="boxLeft_$i"/>
                                    <Button Name="btnAddLeft_$i" Content="Add Action" Padding="10,4" HorizontalAlignment="Left" Cursor="Hand"/>
                                </StackPanel>
                                
                                <StackPanel Name="pnlLeftDouble_$i" Visibility="Collapsed" Margin="0,0,0,15">
                                    <TextBlock Text="Left Double Click Actions:" FontWeight="Bold" Margin="0,0,0,5"/>
                                    <StackPanel Name="boxLeftDouble_$i"/>
                                    <Button Name="btnAddLeftDouble_$i" Content="Add Action" Padding="10,4" HorizontalAlignment="Left" Cursor="Hand"/>
                                </StackPanel>
                                
                                <StackPanel Name="pnlRight_$i" Visibility="Collapsed" Margin="0,0,0,15">
                                    <TextBlock Text="Right Single Click Actions:" FontWeight="Bold" Margin="0,0,0,5"/>
                                    <StackPanel Name="boxRight_$i"/>
                                    <Button Name="btnAddRight_$i" Content="Add Action" Padding="10,4" HorizontalAlignment="Left" Cursor="Hand"/>
                                </StackPanel>
                                
                                <StackPanel Name="pnlRightDouble_$i" Visibility="Collapsed" Margin="0,0,0,15">
                                    <TextBlock Text="Right Double Click Actions:" FontWeight="Bold" Margin="0,0,0,5"/>
                                    <StackPanel Name="boxRightDouble_$i"/>
                                    <Button Name="btnAddRightDouble_$i" Content="Add Action" Padding="10,4" HorizontalAlignment="Left" Cursor="Hand"/>
                                </StackPanel>
                                
                                <StackPanel Name="pnlMid_$i" Visibility="Collapsed" Margin="0,0,0,15">
                                    <TextBlock Text="Middle Click Actions:" FontWeight="Bold" Margin="0,0,0,5"/>
                                    <StackPanel Name="boxMid_$i"/>
                                    <Button Name="btnAddMid_$i" Content="Add Action" Padding="10,4" HorizontalAlignment="Left" Cursor="Hand"/>
                                </StackPanel>
                            </StackPanel>
                        </ScrollViewer>
                    </TabItem>
                </TabControl>
            </TabItem>
"@
        }

        $setXAML = @"
        <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="WinQL Settings (v5.1.0 Fix)" Height="700" Width="700" WindowStartupLocation="CenterScreen" Topmost="True" ResizeMode="NoResize">
            <TabControl Margin="5">
                <TabItem Header="Appearance">
                    <StackPanel Margin="15">
                        <TextBlock Text="Global Font Color Mode:" FontWeight="Bold" Margin="0,0,0,5"/>
                        <Grid Margin="0,0,0,15">
                            <Grid.ColumnDefinitions><ColumnDefinition Width="150"/><ColumnDefinition Width="*"/><ColumnDefinition Width="80"/></Grid.ColumnDefinitions>
                            <ComboBox Name="cmbColor" Grid.Column="0" Margin="0,0,10,0">
                                <ComboBoxItem Content="Auto"/>
                                <ComboBoxItem Content="White"/>
                                <ComboBoxItem Content="Black"/>
                                <ComboBoxItem Content="Custom"/>
                            </ComboBox>
                            <TextBox Name="txtCustomColor" Grid.Column="1" Margin="0,0,10,0" VerticalContentAlignment="Center"/>
                            <Button Name="btnPickColor" Grid.Column="2" Content="Pick Color" Padding="5,2" Cursor="Hand"/>
                        </Grid>
                        
                        <TextBlock Text="Shortcuts Orientation:" FontWeight="Bold" Margin="0,0,0,5"/>
                        <ComboBox Name="cmbOrientation" Margin="0,0,0,15" Width="150" HorizontalAlignment="Left">
                            <ComboBoxItem Content="Horizontal"/>
                            <ComboBoxItem Content="Vertical"/>
                        </ComboBox>
                        
                        <TextBlock Text="Distance Between Elements (Spacing):" FontWeight="Bold" Margin="0,0,0,5"/>
                        <Slider Name="sldSpacing" Minimum="0" Maximum="100" TickFrequency="2" IsSnapToTickEnabled="True" Margin="0,0,0,15"/>

                        <Grid Margin="0,0,0,15">
                            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                            <StackPanel Grid.Column="0" Margin="0,0,10,0">
                                <TextBlock Text="Button Hitbox Size (px):" FontWeight="Bold" Margin="0,0,0,5"/>
                                <TextBox Name="txtBtnSize" Width="60" HorizontalAlignment="Left" Padding="2"/>
                            </StackPanel>
                            <StackPanel Grid.Column="1">
                                <CheckBox Name="chkBorders" Content="Show Temporary Borders" FontWeight="Bold" Margin="0,0,0,10"/>
                            </StackPanel>
                        </Grid>
                        
                        <Border BorderBrush="LightGray" BorderThickness="0,1,0,0" Margin="0,5,0,15"/>

                        <TextBlock Text="Media Player Settings:" FontWeight="Bold" Margin="0,0,0,5"/>
                        <CheckBox Name="chkSong" Content="Display Universal Music Player (Cover Art, Song, Artist)" FontWeight="Bold" Margin="0,0,0,10"/>
                        
                        <Grid Margin="0,0,0,10">
                            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                            <StackPanel Grid.Column="0" Margin="0,0,10,0">
                                <TextBlock Text="Widget Position:" Margin="0,0,0,5"/>
                                <ComboBox Name="cmbMusicPos" Width="150" HorizontalAlignment="Left">
                                    <ComboBoxItem Content="Left"/>
                                    <ComboBoxItem Content="Right"/>
                                </ComboBox>
                            </StackPanel>
                            <StackPanel Grid.Column="1">
                                <CheckBox Name="chkControls" Content="Show Media Control Buttons" Margin="0,5,0,0"/>
                            </StackPanel>
                        </Grid>

                        <Grid Margin="0,0,0,10">
                            <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                            <Button Name="btnMusicFont" Content="Choose Font..." Padding="10,2" Margin="0,0,10,0" Cursor="Hand"/>
                            <TextBlock Name="lblMusicFont" Grid.Column="1" VerticalAlignment="Center" FontStyle="Italic"/>
                        </Grid>
                        <Grid Margin="0,0,0,15">
                            <Grid.ColumnDefinitions><ColumnDefinition Width="150"/><ColumnDefinition Width="*"/><ColumnDefinition Width="80"/></Grid.ColumnDefinitions>
                            <ComboBox Name="cmbMusicColor" Grid.Column="0" Margin="0,0,10,0">
                                <ComboBoxItem Content="Auto"/>
                                <ComboBoxItem Content="White"/>
                                <ComboBoxItem Content="Black"/>
                                <ComboBoxItem Content="Custom"/>
                                <ComboBoxItem Content="Random"/>
                            </ComboBox>
                            <TextBox Name="txtMusicCustomColor" Grid.Column="1" Margin="0,0,10,0" VerticalContentAlignment="Center"/>
                            <Button Name="btnMusicPickColor" Grid.Column="2" Content="Pick Color" Padding="5,2" Cursor="Hand"/>
                        </Grid>
                    </StackPanel>
                </TabItem>
                <TabItem Header="Button Actions">
                    <Grid>
                        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
                        <StackPanel Grid.Row="0" Margin="10,10,10,0">
                            <TextBlock Text="Active Buttons (1-10):" FontWeight="Bold" Margin="0,0,0,5"/>
                            <Slider Name="sldCount" Minimum="1" Maximum="10" TickFrequency="1" IsSnapToTickEnabled="True" Margin="0,0,0,5"/>
                        </StackPanel>
                        <TabControl Grid.Row="1" TabStripPlacement="Left" Margin="5">
                            $dynamicTabs
                        </TabControl>
                    </Grid>
                </TabItem>
                <TabItem Header="Advanced">
                    <StackPanel Margin="15">
                        <CheckBox Name="chkStartup" Content="Launch WinQL automatically on Windows Startup" FontWeight="Bold" Margin="0,0,0,25"/>

                        <TextBlock Text="Taskbar Alignment &amp; Offsets" FontWeight="Bold" Margin="0,0,0,5"/>
                        <TextBlock Text="Widget Alignment:" FontWeight="Bold" Margin="0,0,0,5"/>
                        <ComboBox Name="cmbAlignment" Margin="0,0,0,15" Width="150" HorizontalAlignment="Left">
                            <ComboBoxItem Name="cmbAlignLeft" Content="Left"/>
                            <ComboBoxItem Name="cmbAlignCenter" Content="Center"/>
                            <ComboBoxItem Name="cmbAlignRight" Content="Right"/>
                        </ComboBox>
                        
                        <StackPanel Name="pnlLeftSpacing" Visibility="Collapsed">
                            <TextBlock Text="Left Spacing (px):" Margin="0,0,0,5"/>
                            <Slider Name="sldLeftSpacing" Minimum="0" Maximum="2000" TickFrequency="10" IsSnapToTickEnabled="True" Margin="0,0,0,15"/>
                        </StackPanel>

                        <StackPanel Name="pnlRightSpacing" Visibility="Collapsed">
                            <TextBlock Text="Right Spacing (px):" Margin="0,0,0,5"/>
                            <Slider Name="sldRightSpacing" Minimum="0" Maximum="2000" TickFrequency="10" IsSnapToTickEnabled="True" Margin="0,0,0,15"/>
                        </StackPanel>

                        <TextBlock Text="Note: Window saves automatically and applies instantly." FontStyle="Italic" Foreground="Gray" Margin="0,15,0,0"/>
                    </StackPanel>
                </TabItem>
            </TabControl>
        </Window>
"@
        $setStringReader = New-Object System.IO.StringReader($setXAML)
        $setXmlReader = [System.Xml.XmlReader]::Create($setStringReader)
        $script:setWindow = [System.Windows.Markup.XamlReader]::Load($setXmlReader)
        
        $script:sldCount = $script:setWindow.FindName("sldCount")
        
        $script:cmbAlignment = $script:setWindow.FindName("cmbAlignment")
        $script:cmbAlignLeft = $script:setWindow.FindName("cmbAlignLeft")
        $script:cmbAlignCenter = $script:setWindow.FindName("cmbAlignCenter")
        
        $script:pnlLeftSpacing = $script:setWindow.FindName("pnlLeftSpacing")
        $script:sldLeftSpacing = $script:setWindow.FindName("sldLeftSpacing")
        $script:pnlRightSpacing = $script:setWindow.FindName("pnlRightSpacing")
        $script:sldRightSpacing = $script:setWindow.FindName("sldRightSpacing")

        $script:sldSpacing = $script:setWindow.FindName("sldSpacing")
        $script:cmbOrientation = $script:setWindow.FindName("cmbOrientation")
        $script:cmbColor = $script:setWindow.FindName("cmbColor")
        $script:txtCustomColor = $script:setWindow.FindName("txtCustomColor")
        $script:btnPickColor = $script:setWindow.FindName("btnPickColor")
        $script:chkStartup = $script:setWindow.FindName("chkStartup")
        
        $script:txtBtnSize = $script:setWindow.FindName("txtBtnSize")
        $script:chkBorders = $script:setWindow.FindName("chkBorders")
        
        $script:chkSong = $script:setWindow.FindName("chkSong")
        $script:cmbMusicPos = $script:setWindow.FindName("cmbMusicPos")
        $script:chkControls = $script:setWindow.FindName("chkControls")

        $script:btnMusicFont = $script:setWindow.FindName("btnMusicFont"); $script:lblMusicFont = $script:setWindow.FindName("lblMusicFont")
        $script:cmbMusicColor = $script:setWindow.FindName("cmbMusicColor"); $script:txtMusicCustomColor = $script:setWindow.FindName("txtMusicCustomColor")
        $script:btnMusicPickColor = $script:setWindow.FindName("btnMusicPickColor")

        $script:sldCount.Value = $global:Settings.BtnCount
        
        $script:cmbAlignment.Text = $global:Settings.Alignment
        $script:sldLeftSpacing.Value = $global:Settings.LeftSpacing
        $script:sldRightSpacing.Value = $global:Settings.RightSpacing
        
        $script:sldSpacing.Value = $global:Settings.Spacing
        $script:cmbOrientation.Text = $global:Settings.Orientation
        $script:cmbColor.Text = $global:Settings.FontColorMode; $script:txtCustomColor.Text = $global:Settings.CustomFontColor
        $script:chkStartup.IsChecked = $global:Settings.Startup
        
        $script:txtBtnSize.Text = $global:Settings.ButtonSize
        $script:chkBorders.IsChecked = $global:Settings.ShowBorders
        
        $script:chkSong.IsChecked = $global:Settings.ShowMusicWidget
        $script:cmbMusicPos.Text = $global:Settings.MusicPosition
        $script:chkControls.IsChecked = $global:Settings.ShowMusicControls
        
        $script:lblMusicFont.Text = $global:Settings.MusicFontFamily
        $script:cmbMusicColor.Text = $global:Settings.MusicFontColorMode; $script:txtMusicCustomColor.Text = $global:Settings.MusicCustomColor

        $script:txtCustomColor.IsEnabled = ($script:cmbColor.Text -eq "Custom")
        $script:btnPickColor.IsEnabled = ($script:cmbColor.Text -eq "Custom")

        $script:txtMusicCustomColor.IsEnabled = ($script:cmbMusicColor.Text -eq "Custom")
        $script:btnMusicPickColor.IsEnabled = ($script:cmbMusicColor.Text -eq "Custom")

        for ($i=0; $i -lt 10; $i++) {
            $def = $global:Settings.Buttons[$i]
            
            $tab = $script:setWindow.FindName("tabBtn_$i")
            if ($i -lt $global:Settings.BtnCount) { $tab.Visibility = 'Visible' } else { $tab.Visibility = 'Collapsed' }
            
            $script:setWindow.FindName("txtChar_$i").Text = $def.Char
            $chkL = $script:setWindow.FindName("chkLeft_$i"); $chkL.IsChecked = $def.EnLeft
            $chkLD = $script:setWindow.FindName("chkLeftDouble_$i"); $chkLD.IsChecked = $def.EnLeftDouble
            $chkR = $script:setWindow.FindName("chkRight_$i"); $chkR.IsChecked = $def.EnRight
            $chkRD = $script:setWindow.FindName("chkRightDouble_$i"); $chkRD.IsChecked = $def.EnRightDouble
            $chkM = $script:setWindow.FindName("chkMid_$i"); $chkM.IsChecked = $def.EnMid
            
            $lbl = $script:setWindow.FindName("lblFont_$i")
            $w = "Regular"; if ($def.FontBold) { $w = "Bold" }
            $lbl.Text = "$($def.FontFamily), $($def.FontSize)pt, $w"

            $boxL = $script:setWindow.FindName("boxLeft_$i"); if ($def.LeftActions.Count -gt 0) { foreach($p in $def.LeftActions) { Add-ActionTextBox $boxL $p } }
            $boxLD = $script:setWindow.FindName("boxLeftDouble_$i"); if ($def.LeftDoubleActions.Count -gt 0) { foreach($p in $def.LeftDoubleActions) { Add-ActionTextBox $boxLD $p } }
            $boxR = $script:setWindow.FindName("boxRight_$i"); if ($def.RightActions.Count -gt 0) { foreach($p in $def.RightActions) { Add-ActionTextBox $boxR $p } }
            $boxRD = $script:setWindow.FindName("boxRightDouble_$i"); if ($def.RightDoubleActions.Count -gt 0) { foreach($p in $def.RightDoubleActions) { Add-ActionTextBox $boxRD $p } }
            $boxM = $script:setWindow.FindName("boxMid_$i"); if ($def.MidActions.Count -gt 0) { foreach($p in $def.MidActions) { Add-ActionTextBox $boxM $p } }

            $btnFont = $script:setWindow.FindName("btnFont_$i")
            $btnFont.Tag = $i
            $btnFont.Add_Click({
                param($sender, $e)
                $idx = $sender.Tag
                $dlg = New-Object System.Windows.Forms.FontDialog
                try {
                    $fStyle = [System.Drawing.FontStyle]::Regular
                    if ($global:Settings.Buttons[$idx].FontBold) { $fStyle = $fStyle -bor [System.Drawing.FontStyle]::Bold }
                    if ($global:Settings.Buttons[$idx].FontItalic) { $fStyle = $fStyle -bor [System.Drawing.FontStyle]::Italic }
                    $dlg.Font = New-Object System.Drawing.Font($global:Settings.Buttons[$idx].FontFamily, [float]$global:Settings.Buttons[$idx].FontSize, $fStyle)
                } catch {}
                
                if ($dlg.ShowDialog() -eq 'OK') {
                    $global:Settings.Buttons[$idx].FontFamily = $dlg.Font.Name
                    $global:Settings.Buttons[$idx].FontSize = $dlg.Font.Size
                    $global:Settings.Buttons[$idx].FontBold = $dlg.Font.Bold
                    $global:Settings.Buttons[$idx].FontItalic = $dlg.Font.Italic
                    
                    $w = "Regular"; if ($dlg.Font.Bold) { $w = "Bold" }
                    $script:setWindow.FindName("lblFont_$idx").Text = "$($dlg.Font.Name), $($dlg.Font.Size)pt, $w"
                    & $script:updateAction
                }
            })

            $script:setWindow.FindName("btnAddLeft_$i").Tag = $boxL; $script:setWindow.FindName("btnAddLeft_$i").Add_Click({ param($sender, $e) Add-ActionTextBox $sender.Tag ""; & $script:updateAction })
            $script:setWindow.FindName("btnAddLeftDouble_$i").Tag = $boxLD; $script:setWindow.FindName("btnAddLeftDouble_$i").Add_Click({ param($sender, $e) Add-ActionTextBox $sender.Tag ""; & $script:updateAction })
            $script:setWindow.FindName("btnAddRight_$i").Tag = $boxR; $script:setWindow.FindName("btnAddRight_$i").Add_Click({ param($sender, $e) Add-ActionTextBox $sender.Tag ""; & $script:updateAction })
            $script:setWindow.FindName("btnAddRightDouble_$i").Tag = $boxRD; $script:setWindow.FindName("btnAddRightDouble_$i").Add_Click({ param($sender, $e) Add-ActionTextBox $sender.Tag ""; & $script:updateAction })
            $script:setWindow.FindName("btnAddMid_$i").Tag = $boxM; $script:setWindow.FindName("btnAddMid_$i").Add_Click({ param($sender, $e) Add-ActionTextBox $sender.Tag ""; & $script:updateAction })

            $script:setWindow.FindName("txtChar_$i").Add_TextChanged($script:updateAction)
            $chkL.Add_Click($script:updateAction); $chkLD.Add_Click($script:updateAction); $chkR.Add_Click($script:updateAction); $chkRD.Add_Click($script:updateAction); $chkM.Add_Click($script:updateAction)
        }

        $script:btnMusicFont.Add_Click({
            $dlg = New-Object System.Windows.Forms.FontDialog
            try { $dlg.Font = New-Object System.Drawing.Font($global:Settings.MusicFontFamily, 12.0) } catch {}
            if ($dlg.ShowDialog() -eq 'OK') {
                $global:Settings.MusicFontFamily = $dlg.Font.Name
                $script:lblMusicFont.Text = $dlg.Font.Name
                & $script:updateAction
            }
        })

        function Update-Alignment-UI {
            $align = Get-ComboText $script:cmbAlignment
            if ($align -eq "Left") {
                $script:pnlLeftSpacing.Visibility = 'Visible'
                $script:pnlRightSpacing.Visibility = 'Collapsed'
            } elseif ($align -eq "Right") {
                $script:pnlLeftSpacing.Visibility = 'Collapsed'
                $script:pnlRightSpacing.Visibility = 'Visible'
            } else {
                $script:pnlLeftSpacing.Visibility = 'Collapsed'
                $script:pnlRightSpacing.Visibility = 'Collapsed'
            }

            $edge = [Native]::GetTaskbarEdge()
            $taskbarAl = 0
            try { $taskbarAl = Get-ItemPropertyValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -ErrorAction SilentlyContinue } catch {}
            if ($taskbarAl -eq $null) { $taskbarAl = 0 }
            
            $script:cmbAlignLeft.IsEnabled = ($edge -ne 0)
            if (-not $script:cmbAlignLeft.IsEnabled) { $script:cmbAlignLeft.ToolTip = "Unavailable when taskbar is vertically on the left." } else { $script:cmbAlignLeft.ToolTip = $null }

            $script:cmbAlignCenter.IsEnabled = (-not (($edge -eq 1 -or $edge -eq 3) -and $taskbarAl -eq 1))
            if (-not $script:cmbAlignCenter.IsEnabled) { $script:cmbAlignCenter.ToolTip = "Unavailable when Windows 11 taskbar icons are Centered." } else { $script:cmbAlignCenter.ToolTip = $null }
        }

        $script:cmbAlignment.Add_SelectionChanged({ 
            Update-Alignment-UI
            $script:setWindow.Dispatcher.BeginInvoke([Action]{ & $script:updateAction }, [System.Windows.Threading.DispatcherPriority]::Background) | Out-Null
        })
        
        $script:cmbOrientation.Add_SelectionChanged($script:updateAction)
        $script:cmbMusicPos.Add_SelectionChanged($script:updateAction)
        
        $script:cmbMusicColor.Add_SelectionChanged({
            $mode = Get-ComboText $script:cmbMusicColor
            $isCustom = ($mode -eq "Custom")
            $script:txtMusicCustomColor.IsEnabled = $isCustom; $script:btnMusicPickColor.IsEnabled = $isCustom
            $script:setWindow.Dispatcher.BeginInvoke([Action]{ & $script:updateAction }, [System.Windows.Threading.DispatcherPriority]::Background) | Out-Null
        })

        $script:cmbColor.Add_SelectionChanged({
            $mode = Get-ComboText $script:cmbColor
            $isCustom = ($mode -eq "Custom")
            $script:txtCustomColor.IsEnabled = $isCustom; $script:btnPickColor.IsEnabled = $isCustom
            $script:setWindow.Dispatcher.BeginInvoke([Action]{ & $script:updateAction }, [System.Windows.Threading.DispatcherPriority]::Background) | Out-Null
        })

        $script:btnPickColor.Add_Click({
            $dlg = New-Object System.Windows.Forms.ColorDialog
            $dlg.FullOpen = $true
            try { $dlg.Color = [System.Drawing.ColorTranslator]::FromHtml($script:txtCustomColor.Text) } catch {}
            if ($dlg.ShowDialog() -eq 'OK') {
                $script:txtCustomColor.Text = "#$($dlg.Color.R.ToString('X2'))$($dlg.Color.G.ToString('X2'))$($dlg.Color.B.ToString('X2'))"
                & $script:updateAction
            }
            $dlg.Dispose()
        })

        $script:btnMusicPickColor.Add_Click({
            $dlg = New-Object System.Windows.Forms.ColorDialog
            $dlg.FullOpen = $true
            try { $dlg.Color = [System.Drawing.ColorTranslator]::FromHtml($script:txtMusicCustomColor.Text) } catch {}
            if ($dlg.ShowDialog() -eq 'OK') {
                $script:txtMusicCustomColor.Text = "#$($dlg.Color.R.ToString('X2'))$($dlg.Color.G.ToString('X2'))$($dlg.Color.B.ToString('X2'))"
                & $script:updateAction
            }
            $dlg.Dispose()
        })
        
        $script:chkStartup.Add_Click({
            if ($script:chkStartup.IsChecked) { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WinQL" -Value "wscript.exe `"C:\Program Files\Detaroxz\WinQL\Invisible.vbs`"" } 
            else { Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WinQL" -ErrorAction SilentlyContinue }
            & $script:updateAction
        })

        $script:sldCount.Add_ValueChanged($script:updateAction)
        $script:sldLeftSpacing.Add_ValueChanged($script:updateAction)
        $script:sldRightSpacing.Add_ValueChanged($script:updateAction)
        $script:sldSpacing.Add_ValueChanged($script:updateAction)
        $script:txtCustomColor.Add_TextChanged($script:updateAction)
        $script:txtMusicCustomColor.Add_TextChanged($script:updateAction)
        $script:txtBtnSize.Add_TextChanged($script:updateAction)
        $script:chkBorders.Add_Click($script:updateAction)
        $script:chkSong.Add_Click($script:updateAction)
        $script:chkControls.Add_Click($script:updateAction)

        $script:setWindow.Add_Closed({ $script:isSettingsOpen = $false; [Native]::TrimMemory() })
        
        $script:isLoading = $false
        Update-Alignment-UI
        & $script:updateAction 
        $script:setWindow.ShowDialog() | Out-Null
    }

    # --- THE LIFECYCLE RESTART LOOP ---
    $global:keepRunning = $true
    
    $global:sysTray = New-Object System.Windows.Forms.NotifyIcon
    try { $global:sysTray.Icon = New-Object System.Drawing.Icon("C:\Program Files\Detaroxz\WinQL\icon.ico") } catch { $global:sysTray.Icon = [System.Drawing.SystemIcons]::Application }
    $global:sysTray.Text = "WinQL v5.1.0"
    $global:sysTray.Visible = $true
    
    $contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
    $itemSettings = $contextMenu.Items.Add("Settings"); $itemSettings.add_Click({ Show-SettingsWindow })
    $itemExit = $contextMenu.Items.Add("Exit"); $itemExit.add_Click({ 
        $global:keepRunning = $false
        $global:sysTray.Visible = $false
        $global:sysTray.Dispose()
        if ($null -ne $script:window) { $script:window.Close() }
        if ($null -ne $script:dispatcher) { $script:dispatcher.InvokeShutdown() }
    })
    $global:sysTray.ContextMenuStrip = $contextMenu

    while ($global:keepRunning) {
        $hTaskbar = [Native]::FindWindow("Shell_TrayWnd", $null)
        if ($hTaskbar -eq [IntPtr]::Zero) {
            Start-Sleep -Seconds 2
            continue
        }

        $stringReader = New-Object System.IO.StringReader($uiXAML)
        $script:window = [System.Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create($stringReader))
        $stringReader.Dispose()

        $script:MainGrid = $script:window.FindName("MainGrid")
        $script:ButtonPanel = $script:window.FindName("ButtonPanel")
        
        $script:MusicContainer = $script:window.FindName("MusicContainer")
        $script:CoverBorder = $script:window.FindName("CoverBorder")
        $script:CoverBrush = $script:window.FindName("CoverBrush")
        $script:FallbackIcon = $script:window.FindName("FallbackIcon")
        
        $script:CanvasTitle = $script:window.FindName("CanvasTitle")
        $script:SongTitle = $script:window.FindName("SongTitle")
        $script:CanvasArtist = $script:window.FindName("CanvasArtist")
        $script:SongArtist = $script:window.FindName("SongArtist")
        
        $script:MusicControls = $script:window.FindName("MusicControls")
        $script:BtnPrev = $script:window.FindName("BtnPrev")
        $script:BtnPlay = $script:window.FindName("BtnPlay")
        $script:BtnNext = $script:window.FindName("BtnNext")

        # Fuzzy Source App Switching on Click
        $script:MusicContainer.Add_MouseUp({
            param($sender, $e)
            if (-not $global:MediaAPIEnabled -or [string]::IsNullOrWhiteSpace([WinMedia]::AppId)) { return }
            
            $appId = [WinMedia]::AppId.ToLower()
            $searchTerm = $appId -replace '\.exe$','' -replace '!.*$',''
            if ($searchTerm -match '\.') { $searchTerm = $searchTerm.Split('.')[-1] }
            
            # Common overrides for UWP IDs
            if ($appId -match "spotify") { $p = Get-Process Spotify -ErrorAction SilentlyContinue | Select-Object -First 1 }
            elseif ($appId -match "chrome") { $p = Get-Process chrome -ErrorAction SilentlyContinue | Select-Object -First 1 }
            elseif ($appId -match "msedge") { $p = Get-Process msedge -ErrorAction SilentlyContinue | Select-Object -First 1 }
            elseif ($appId -match "vlc") { $p = Get-Process vlc -ErrorAction SilentlyContinue | Select-Object -First 1 }
            else { 
                $p = Get-Process | Where-Object { -not [string]::IsNullOrWhiteSpace($_.MainWindowTitle) -and ($_.ProcessName.ToLower() -match $searchTerm -or $appId -match $_.ProcessName.ToLower()) } | Select-Object -First 1
                if (-not $p) { $p = Get-Process | Where-Object { $_.MainWindowTitle -ne "" } | Select-Object -First 1 }
            }
            
            if ($p) {
                $wshell = New-Object -ComObject wscript.shell
                $wshell.AppActivate($p.Id) | Out-Null
            }
        })

        $script:BtnPrev.Add_PreviewMouseLeftButtonDown({ param($sender, $e) if ($global:MediaAPIEnabled) { [WinMedia]::Prev() }; $e.Handled = $true })
        $script:BtnPlay.Add_PreviewMouseLeftButtonDown({ param($sender, $e) if ($global:MediaAPIEnabled) { [WinMedia]::PlayPause() }; $e.Handled = $true })
        $script:BtnNext.Add_PreviewMouseLeftButtonDown({ param($sender, $e) if ($global:MediaAPIEnabled) { [WinMedia]::Next() }; $e.Handled = $true })

        $script:window.Add_Loaded({
            $script:hwnd = (New-Object System.Windows.Interop.WindowInteropHelper($script:window)).Handle
            
            $style = [Native]::GetWindowLong($script:hwnd, -16)
            $style = $style -band -bnot 0x80000000 
            $style = $style -bor 0x40000000       
            $style = $style -bor 0x04000000       
            [Native]::SetWindowLong($script:hwnd, -16, $style) | Out-Null
            
            [Native]::SetParent($script:hwnd, $hTaskbar) | Out-Null
            
            $script:hookDelegate = [System.Windows.Interop.HwndSourceHook]{
                param([IntPtr]$hwnd, [int]$msg, [IntPtr]$wParam, [IntPtr]$lParam, [ref]$handled)
                if ($msg -eq [Native]::WM_TASKBARCREATED) {
                    if ($null -ne $script:window) { $script:window.Close() }
                    if ($null -ne $script:dispatcher) { $script:dispatcher.InvokeShutdown() }
                }
                return [IntPtr]::Zero
            }
            $source = [System.Windows.Interop.HwndSource]::FromHwnd($script:hwnd)
            $source.AddHook($script:hookDelegate)

            $script:lastThemeColor = Get-ThemeColor
            Render-Layout
        })

        $marqueeTimer = New-Object System.Windows.Threading.DispatcherTimer
        $marqueeTimer.Interval = [TimeSpan]::FromMilliseconds(50) 
        
        $updateTimer = New-Object System.Windows.Threading.DispatcherTimer
        $updateTimer.Interval = [TimeSpan]::FromMilliseconds(1000) 
        $script:tickCount = 0
        $script:lastSong = ""
        
        $marqueeTimer.Add_Tick({
            if ($script:MusicContainer.Visibility -eq 'Visible') {
                Tick-Marquee $script:SongTitle $script:CanvasTitle
                Tick-Marquee $script:SongArtist $script:CanvasArtist
            }
        })

        $updateTimer.Add_Tick({
            $script:tickCount++

            if ($global:Settings.ShowMusicWidget -and $global:MediaAPIEnabled) {
                [WinMedia]::Update()
                if ([WinMedia]::HasMedia -and -not [string]::IsNullOrWhiteSpace([WinMedia]::Title)) {
                    $song = [WinMedia]::Title
                    if ($song -ne $script:lastSong) {
                        $script:lastSong = $song
                        $script:SongTitle.Text = $song
                        $script:SongArtist.Text = [WinMedia]::Artist
                        
                        [System.Windows.Controls.Canvas]::SetLeft($script:SongTitle, 0)
                        [System.Windows.Controls.Canvas]::SetLeft($script:SongArtist, 0)

                        if ($null -ne [WinMedia]::ThumbBytes) {
                            try {
                                $ms = New-Object System.IO.MemoryStream(,[byte[]][WinMedia]::ThumbBytes)
                                $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
                                $bmp.BeginInit()
                                $bmp.StreamSource = $ms
                                $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                                $bmp.EndInit()
                                $bmp.Freeze()
                                $script:CoverBrush.ImageSource = $bmp
                                $script:CoverBorder.Background = [System.Windows.Media.Brushes]::Transparent
                                $script:FallbackIcon.Visibility = 'Collapsed'
                                $ms.Dispose()
                            } catch {}
                        } else {
                            $script:CoverBrush.ImageSource = $null
                            $brushConv = New-Object System.Windows.Media.BrushConverter
                            $script:CoverBorder.Background = $brushConv.ConvertFromString("#22888888")
                            $script:FallbackIcon.Visibility = 'Visible'
                        }

                        $brushConv = New-Object System.Windows.Media.BrushConverter
                        if ($global:Settings.MusicFontColorMode -eq "Random") {
                            $rc = "#$((Get-Random -Min 100 -Max 255).ToString('X2'))$((Get-Random -Min 100 -Max 255).ToString('X2'))$((Get-Random -Min 100 -Max 255).ToString('X2'))"
                            $brush = $brushConv.ConvertFromString($rc)
                            $script:SongTitle.Foreground = $brush; $script:SongArtist.Foreground = $brush
                            $script:BtnPrev.Foreground = $brush; $script:BtnPlay.Foreground = $brush; $script:BtnNext.Foreground = $brush
                        } elseif ($global:Settings.MusicFontColorMode -eq "White") { 
                            $brush = $brushConv.ConvertFromString("#FFFFFF")
                            $script:SongTitle.Foreground = $brush; $script:SongArtist.Foreground = $brush
                            $script:BtnPrev.Foreground = $brush; $script:BtnPlay.Foreground = $brush; $script:BtnNext.Foreground = $brush
                        } elseif ($global:Settings.MusicFontColorMode -eq "Black") { 
                            $brush = $brushConv.ConvertFromString("#000000")
                            $script:SongTitle.Foreground = $brush; $script:SongArtist.Foreground = $brush
                            $script:BtnPrev.Foreground = $brush; $script:BtnPlay.Foreground = $brush; $script:BtnNext.Foreground = $brush
                        } elseif ($global:Settings.MusicFontColorMode -eq "Custom") { 
                            try { $brush = $brushConv.ConvertFromString($global:Settings.MusicCustomColor) } catch { $brush = [System.Windows.Media.Brushes]::White }
                            $script:SongTitle.Foreground = $brush; $script:SongArtist.Foreground = $brush
                            $script:BtnPrev.Foreground = $brush; $script:BtnPlay.Foreground = $brush; $script:BtnNext.Foreground = $brush
                        } else { 
                            try { $brush = $brushConv.ConvertFromString((Get-ThemeColor)) } catch { $brush = [System.Windows.Media.Brushes]::White }
                            $script:SongTitle.Foreground = $brush; $script:SongArtist.Foreground = $brush
                            $script:BtnPrev.Foreground = $brush; $script:BtnPlay.Foreground = $brush; $script:BtnNext.Foreground = $brush
                        }
                    }
                    if ([WinMedia]::IsPlaying) { $script:BtnPlay.Text = "⏸" } else { $script:BtnPlay.Text = "▶" }
                    
                    if ($script:MusicContainer.Visibility -ne 'Visible') {
                        $script:MusicContainer.Visibility = 'Visible'
                        Update-Window-Position
                    }
                } else {
                    if ($script:MusicContainer.Visibility -ne 'Collapsed') {
                        $script:MusicContainer.Visibility = 'Collapsed'
                        $script:lastSong = ""
                        Update-Window-Position
                    }
                }
            } else {
                if ($script:MusicContainer.Visibility -ne 'Collapsed') {
                    $script:MusicContainer.Visibility = 'Collapsed'
                    Update-Window-Position
                }
            }
            
            if ($script:tickCount % 4 -eq 0 -and $global:Settings.FontColorMode -eq "Auto") { 
                $currTheme = Get-ThemeColor
                if ($currTheme -ne $script:lastThemeColor) {
                    $script:lastThemeColor = $currTheme
                    Render-Layout
                }
            }
            if ($script:tickCount -ge 20) { $script:tickCount = 0; [Native]::TrimMemory() }
        })
        
        $marqueeTimer.Start()
        $updateTimer.Start()

        $script:window.Show()
        $script:dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher
        [System.Windows.Threading.Dispatcher]::Run()

        $marqueeTimer.Stop()
        $updateTimer.Stop()
        if ($global:keepRunning) { Start-Sleep -Seconds 2 } 
    }
} catch {
    $errMsg = "Exception: $($_.Exception.Message)`nStackTrace: $($_.Exception.StackTrace)"
    $errMsg | Out-File "$env:APPDATA\Detaroxz\WinQL\crash.log"
}
'@

# --- 6. WRITE REMAINING FILES & START MENU ---
Set-Content -Path "$installDir\WinQL.ps1" -Value $mainContent -Encoding UTF8

$uninstallContent = @'
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { Start-Process powershell.exe -ArgumentList "-Sta -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit }
Write-Host "Uninstalling WinQL..." -ForegroundColor Cyan
Get-CimInstance Win32_Process | Where-Object { ($_.CommandLine -match "WinQL.ps1" -or $_.Name -match "WinQL.exe") -and $_.ProcessId -ne $PID } | Invoke-CimMethod -MethodName Terminate | Out-Null
$installDir = "C:\Program Files\Detaroxz\WinQL"; $appDataDir = "$env:APPDATA\Detaroxz\WinQL"; $commonPrograms = [Environment]::GetFolderPath('CommonPrograms')
if (Test-Path $installDir) { Remove-Item -Path $installDir -Recurse -Force -ErrorAction SilentlyContinue }
if (Test-Path $appDataDir) { Remove-Item -Path $appDataDir -Recurse -Force -ErrorAction SilentlyContinue }

$mainShortcutPath = Join-Path $commonPrograms "WinQL.lnk"
if (Test-Path $mainShortcutPath) { Remove-Item $mainShortcutPath -Force -ErrorAction SilentlyContinue }

Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WinQL" -ErrorAction SilentlyContinue
$shortcutPath = Join-Path ([Environment]::GetFolderPath('Startup')) "WinQL.lnk"
if (Test-Path $shortcutPath) { Remove-Item $shortcutPath -Force -ErrorAction SilentlyContinue }
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WinQL" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Uninstallation Complete!" -ForegroundColor Green; Start-Sleep -Seconds 2
'@
Set-Content -Path "$installDir\Uninstall.ps1" -Value $uninstallContent -Encoding UTF8

$WshShell = New-Object -ComObject WScript.Shell
$mainShortcutPath = Join-Path $commonPrograms "WinQL.lnk"
$shortcutStart = $WshShell.CreateShortcut($mainShortcutPath)
$shortcutStart.TargetPath = "wscript.exe"
$shortcutStart.Arguments = "`"C:\Program Files\Detaroxz\WinQL\Invisible.vbs`""
$shortcutStart.IconLocation = "C:\Program Files\Detaroxz\WinQL\icon.ico"
$shortcutStart.Save()

# --- 7. REGISTRY & LAUNCH ---
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WinQL"
if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
Set-ItemProperty -Path $regPath -Name "DisplayName" -Value "WinQL"
Set-ItemProperty -Path $regPath -Name "DisplayVersion" -Value "5.1.0"
Set-ItemProperty -Path $regPath -Name "Publisher" -Value "Detaroxz"
Set-ItemProperty -Path $regPath -Name "DisplayIcon" -Value "C:\Program Files\Detaroxz\WinQL\icon.ico"
Set-ItemProperty -Path $regPath -Name "UninstallString" -Value "powershell.exe -Sta -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$installDir\Uninstall.ps1`""
Set-ItemProperty -Path $regPath -Name "NoModify" -Value 1; Set-ItemProperty -Path $regPath -Name "NoRepair" -Value 1

if ($global:Settings.Startup) {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WinQL" -Value "wscript.exe `"C:\Program Files\Detaroxz\WinQL\Invisible.vbs`""
}

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host " Installation Complete! Launching WinQL...       " -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Cyan
Start-Process -FilePath "wscript.exe" -ArgumentList "`"$installDir\Invisible.vbs`""
Start-Sleep -Seconds 2