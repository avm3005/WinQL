# Install-WinQL.ps1 - Taskbar-Integrated Setup for WinQL v1.0.0 (Patched Media Engine & Adaptive Thumbnail)

# --- 1. AUTOMATIC ADMINISTRATOR ELEVATION ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-Sta -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "    WinQL Utility Installer - v1.0.0             " -ForegroundColor White
Write-Host "=================================================" -ForegroundColor Cyan
Start-Sleep -Seconds 1

# --- 2. CLEANUP & PREVIOUS INSTALLATION DETECTION ---
$appDataFolder = "$env:APPDATA\Detaroxz\WinQL"
$settingsFile = "$appDataFolder\settings.json"
$installDir = Join-Path $env:ProgramFiles "Detaroxz\WinQL"
$commonPrograms = [Environment]::GetFolderPath('CommonPrograms')

Write-Host "[*] Terminating existing background processes..." -ForegroundColor DarkGray
Get-CimInstance Win32_Process | Where-Object { ($_.CommandLine -match "wscript.*Invisible\.vbs" -or $_.Name -match "WinQL\.exe" -or ($_.CommandLine -match "powershell.*WinQL\.ps1" -and $_.CommandLine -notmatch "code\.exe|devenv\.exe|notepad")) -and $_.ProcessId -ne $PID } | Invoke-CimMethod -MethodName Terminate | Out-Null

if (Test-Path $installDir) { Remove-Item -Path $installDir -Recurse -Force -ErrorAction SilentlyContinue }
$oldMenuDir = Join-Path $commonPrograms "WinQL"
if (Test-Path $oldMenuDir) { Remove-Item -Path $oldMenuDir -Recurse -Force -ErrorAction SilentlyContinue }
$mainShortcutPath = Join-Path $commonPrograms "WinQL.lnk"
if (Test-Path $mainShortcutPath) { Remove-Item $mainShortcutPath -Force -ErrorAction SilentlyContinue }
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WinQL" -ErrorAction SilentlyContinue
$shortcutPath = Join-Path ([Environment]::GetFolderPath('Startup')) "WinQL.lnk"
if (Test-Path $shortcutPath) { Remove-Item $shortcutPath -Force -ErrorAction SilentlyContinue }
Unregister-ScheduledTask -TaskName "WinQL_Service" -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WinQL" -Recurse -Force -ErrorAction SilentlyContinue

New-Item -Path $installDir -ItemType Directory -Force | Out-Null
if (-not (Test-Path $appDataFolder)) { New-Item -Path $appDataFolder -ItemType Directory -Force | Out-Null }

# --- 3. ICO GENERATION ---
Write-Host "[*] Compiling Native SVG Icon..." -ForegroundColor Cyan
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName WindowsBase

$dv = New-Object System.Windows.Media.DrawingVisual
$dc = $dv.RenderOpen()
$brushConv = New-Object System.Windows.Media.BrushConverter

$transform = New-Object System.Windows.Media.TransformGroup
$transform.Children.Add((New-Object System.Windows.Media.TranslateTransform(1, 1)))
$transform.Children.Add((New-Object System.Windows.Media.ScaleTransform(0.5, 0.5)))
$dc.PushTransform($transform)

$dc.DrawGeometry($brushConv.ConvertFromString("#FFA81E"), $null, [System.Windows.Media.Geometry]::Parse("M489.525,493.943c-2.554,0-5.109-0.958-7.082-2.882L202.203,217.825 c-4.013-3.913-4.094-10.338-0.181-14.348c3.913-4.014,10.337-4.095,14.35-0.183L496.609,476.53 c4.013,3.913,4.094,10.338,0.183,14.348C494.804,492.919,492.166,493.943,489.525,493.943z"))
$dc.DrawGeometry($brushConv.ConvertFromString("#FFD92D"), $null, [System.Windows.Media.Geometry]::Parse("M511.807,192.381c-11.258,0.325-25.52,1.755-41.526,5.933c-18.494,4.826-33.315,11.753-44.071,17.797 c4.988-41.131,5.085-52.544,5.085-52.544c0.2-23.451-4.554-41.131-7.625-52.544C408.39,54.226,367.591,12.837,354.175,0 C340.91,11.633,324.4,28.551,309.256,51.697c-19.555,29.9-29.043,58.289-33.9,77.968c-0.344-0.357-29.909-36.019-61.867-60.173 c-21.792-16.464-40.951-24.756-58.477-32.204C127.115,25.435,77.035,8.486,7.821,7.646c0.786,69.4,17.775,119.6,29.649,147.547 c7.448,17.524,15.737,36.683,32.204,58.476c24.153,31.957,59.814,61.524,60.173,61.869c-19.679,4.856-48.07,14.343-77.971,33.899 c-23.145,15.14-40.063,31.65-51.696,44.915c12.84,13.418,54.226,54.217,111.022,69.495c11.415,3.071,29.092,7.826,52.544,7.628 c0,0,11.415-0.096,52.544-5.085c-6.046,10.755-12.971,25.577-17.797,44.069c-4.178,16.006-5.608,30.268-5.933,41.527 c15.869,0.192,67.694-1.216,108.479-38.986c22.458-20.795,32.794-44.489,37.288-55.087c8.674-20.438,11.072-37.847,13.271-66.523 c28.445-2.192,45.788-4.607,66.135-13.24c10.595-4.496,34.289-14.833,55.087-37.291 C510.593,260.073,512.002,208.253,511.807,192.381z"))
$dc.DrawGeometry($brushConv.ConvertFromString("#FFE571"), $null, [System.Windows.Media.Geometry]::Parse("M240.285,477.27c0.342-11.914,1.856-27.007,6.278-43.944c5.106-19.568,12.435-35.253,18.834-46.633 c-43.523,5.279-55.602,5.381-55.602,5.381c-24.818,0.21-43.523-4.822-55.602-8.072c-53.551-14.405-94.135-50.234-111.961-67.92 c-18.272,13.206-32.102,26.924-42.052,38.269c12.84,13.418,54.226,54.217,111.022,69.495c11.415,3.071,29.092,7.826,52.544,7.628 c0,0,11.415-0.096,52.544-5.085c-6.046,10.755-12.971,25.577-17.797,44.069c-4.178,16.006-5.608,30.268-5.933,41.527 c15.869,0.192,67.694-1.216,108.479-38.986c2.918-2.702,5.622-5.454,8.145-8.218C279.166,476.786,251.396,477.404,240.285,477.27z"))
$dc.DrawGeometry($brushConv.ConvertFromString("#FFA81E"), $null, [System.Windows.Media.Geometry]::Parse("M470.281,198.315c-18.494,4.826-33.317,11.751-44.073,17.796c4.988-41.127,5.085-52.543,5.085-52.543 c0.198-23.453-4.553-41.131-7.624-52.544C408.39,54.229,367.591,12.84,354.172,0c-13.265,11.633-29.772,28.549-44.919,51.697 c-19.555,29.901-29.043,58.292-33.898,77.968c-0.345-0.357-29.909-36.016-61.867-60.171c-21.792-16.467-40.953-24.756-58.477-32.204 C127.12,25.44,77.027,8.521,7.838,7.673c0.794,69.373,17.761,119.579,29.634,147.518c1.905,4.496,3.89,9.106,6.03,13.832 c-1.135-10.503-1.932-21.569-2.066-33.466c0.003,0.007-0.001,0.003,0,0c56.98,0.699,98.232,14.633,121.208,24.393 c14.431,6.134,30.207,12.962,48.153,26.523c8.466,6.397,16.726,13.775,24.048,20.851c12.188,11.775,32.396,8.103,39.373-7.341 c4.045-8.955,9.104-18.464,15.452-28.166c5.865-8.969,11.981-16.801,17.95-23.58c10.045-11.404,27.844-10.812,37.556,0.878 c13.879,16.707,30.633,41.515,38.713,71.557c2.533,9.402,6.444,23.96,6.285,43.274c0,0-0.008,0.966-0.156,3.392 c-1.039,17.225,15.118,29.755,31.801,25.341c0.153-0.039,0.303-0.08,0.456-0.118c13.186-3.442,24.926-4.618,34.201-4.887 c0.069,5.624-0.269,16.876-2.966,30.38c6.409-4.765,12.982-10.358,19.31-17.192c37.77-40.786,39.178-92.608,38.985-108.479 C500.547,192.707,486.288,194.137,470.281,198.315z"))
$dc.Pop()

$dc.Close()

$rtb = New-Object System.Windows.Media.Imaging.RenderTargetBitmap(256, 256, 96, 96, [System.Windows.Media.PixelFormats]::Pbgra32)
$rtb.Render($dv)

$encoder = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
$encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($rtb))
$ms = New-Object System.IO.MemoryStream
$encoder.Save($ms)
$pngBytes = $ms.ToArray()

$icoStream = New-Object System.IO.FileStream("$installDir\icon.ico", [System.IO.FileMode]::Create)
$bw = New-Object System.IO.BinaryWriter($icoStream)
$bw.Write([int16]0); $bw.Write([int16]1); $bw.Write([int16]1); $bw.Write([byte]0); $bw.Write([byte]0); $bw.Write([byte]0); $bw.Write([byte]0); $bw.Write([int16]1); $bw.Write([int16]32)
$bw.Write([int32]$pngBytes.Length); $bw.Write([int32]22); $bw.Write($pngBytes)
$bw.Flush(); $icoStream.Dispose(); $ms.Dispose()

# --- 4. INVISIBLE LAUNCHER ---
Write-Host "[*] Creating Background Wrapper..." -ForegroundColor Cyan
Copy-Item "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" -Destination "$installDir\WinQL.exe" -Force
Copy-Item "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe.config" -Destination "$installDir\WinQL.exe.config" -Force -ErrorAction SilentlyContinue

$launcherVbs = @"
Set ws = CreateObject("WScript.Shell")
ws.Run """$installDir\WinQL.exe"" -Sta -ExecutionPolicy Bypass -WindowStyle Hidden -File ""$installDir\WinQL.ps1""", 0, False
"@
Set-Content -Path "$installDir\Invisible.vbs" -Value $launcherVbs -Encoding Ascii

# --- 5. MAIN SCRIPT PAYLOAD ---
Write-Host "[*] Writing Taskbar Engine..." -ForegroundColor Cyan
$mainContent = @'
try {
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Windows.Forms
    
    $appInstallDir = Join-Path $env:ProgramFiles "Detaroxz\WinQL"

    # --- WIN32 INTEROP ---
    $signature = @"
    using System;
    using System.Runtime.InteropServices;
    public class Native {
        [DllImport("user32.dll", SetLastError = true)] public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
        [DllImport("user32.dll", SetLastError = true)] public static extern IntPtr FindWindowEx(IntPtr hwndParent, IntPtr hwndChildAfter, string lpszClass, string lpszWindow);
        [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hwnd, out RECT lpRect);
        [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd, out RECT lpRect);
        [DllImport("user32.dll")] public static extern int MapWindowPoints(IntPtr hWndFrom, IntPtr hWndTo, ref RECT lpPoints, uint cPoints);
        [DllImport("user32.dll", SetLastError = true)] public static extern IntPtr SetParent(IntPtr hWndChild, IntPtr hWndNewParent);
        [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
        [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr hWnd, int nIndex);
        [DllImport("user32.dll")] public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);
        [DllImport("user32.dll")] public static extern uint RegisterWindowMessage(string lpString);
        [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, int dwExtraInfo);
        [DllImport("kernel32.dll")] public static extern bool SetProcessWorkingSetSize(IntPtr proc, int min, int max);
        [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, IntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out IntPtr lpdwResult);

        public static void UpdateTheme() {
            IntPtr result;
            SendMessageTimeout((IntPtr)0xffff, 0x001A, IntPtr.Zero, "ImmersiveColorSet", 0x0002, 2000, out result);
        }

        [StructLayout(LayoutKind.Sequential)] public struct RECT { public int left, top, right, bottom; }
        [StructLayout(LayoutKind.Sequential)] public struct APPBARDATA { public int cbSize; public IntPtr hWnd; public int uCallbackMessage; public int uEdge; public RECT rc; public IntPtr lParam; }
        [DllImport("shell32.dll")] public static extern IntPtr SHAppBarMessage(int dwMessage, ref APPBARDATA pData);

        public static int GetTaskbarEdge() { APPBARDATA abd = new APPBARDATA(); abd.cbSize = Marshal.SizeOf(abd); SHAppBarMessage(5, ref abd); return abd.uEdge; }
        public static uint WM_TASKBARCREATED = RegisterWindowMessage("TaskbarCreated");
        public static IntPtr GetTrayHandle(IntPtr hTaskbar) { return FindWindowEx(hTaskbar, IntPtr.Zero, "TrayNotifyWnd", null); }
    }
"@
    Add-Type -TypeDefinition $signature -Language CSharp

    # --- UWP MEDIA ENGINE WITH ASYNC BROWSER THUMBNAIL FETCHING ---
    try {
        $smtcSig = @"
        using System;
        using System.Threading;
        using System.Threading.Tasks;
        using System.Collections.Generic;
        using Windows.Media.Control;
        using Windows.Storage.Streams;
        using Windows.Foundation;

        public static class MediaTracker {
            private static readonly object _stateLock = new object();
            private static string _title = "";
            private static string _artist = "";
            private static string _appId = "";
            private static byte[] _thumbnailBytes = null;
            private static bool _isPlaying = false;
            private static bool _hasMedia = false;
            
            public static bool IsRunning = false;
            private static string _lastTrackId = "";
            private static int _ticksSinceTrackChange = 0;
            private static GlobalSystemMediaTransportControlsSessionManager _manager;

            public static int SessionTarget = -1;
            private static string _lastOsSessionId = "";

            public static void CycleSession() {
                if (_manager != null) {
                    var sessions = _manager.GetSessions();
                    if (sessions.Count > 1) {
                        SessionTarget++;
                        if (SessionTarget >= sessions.Count) SessionTarget = 0;
                        lock(_stateLock) { _lastTrackId = ""; _thumbnailBytes = null; }
                    } else {
                        SessionTarget = -1;
                    }
                }
            }

            private static GlobalSystemMediaTransportControlsSession GetTargetSession() {
                if (_manager == null) return null;
                var sessions = _manager.GetSessions();
                if (sessions.Count == 0) { SessionTarget = -1; _lastOsSessionId = ""; return null; }
                
                var current = _manager.GetCurrentSession();
                string currentId = current != null ? current.SourceAppUserModelId : "";
                
                // Auto-switch when Windows promotes a new media session to active
                if (!string.IsNullOrEmpty(currentId) && currentId != _lastOsSessionId) {
                    _lastOsSessionId = currentId;
                    for (int i = 0; i < sessions.Count; i++) {
                        if (sessions[i].SourceAppUserModelId == currentId) {
                            if (SessionTarget != i) {
                                SessionTarget = i;
                                lock(_stateLock) { _lastTrackId = ""; _thumbnailBytes = null; }
                            }
                            return current;
                        }
                    }
                }
                
                _lastOsSessionId = currentId;

                if (SessionTarget == -1 || SessionTarget >= sessions.Count) {
                    if (current != null) {
                        for (int i=0; i<sessions.Count; i++) {
                            if (sessions[i].SourceAppUserModelId == currentId) {
                                SessionTarget = i;
                                return current;
                            }
                        }
                    }
                    SessionTarget = 0;
                }
                return sessions[SessionTarget];
            }

            public static object[] GetState() {
                lock(_stateLock) {
                    return new object[] { _hasMedia, _title, _artist, _appId, _isPlaying, _thumbnailBytes };
                }
            }

            private static T AwaitOp<T>(IAsyncOperation<T> op) {
                while (op.Status == AsyncStatus.Started) { Thread.Sleep(50); }
                if (op.Status == AsyncStatus.Completed) return op.GetResults();
                return default(T);
            }
            
            private static T AwaitOpProgress<T, P>(IAsyncOperationWithProgress<T, P> op) {
                while (op.Status == AsyncStatus.Started) { Thread.Sleep(50); }
                if (op.Status == AsyncStatus.Completed) return op.GetResults();
                return default(T);
            }

            public static void Start() {
                if (IsRunning) return;
                IsRunning = true;
                
                Task.Run(() => {
                    while(IsRunning) {
                        try {
                            if (_manager == null) {
                                var opMgr = GlobalSystemMediaTransportControlsSessionManager.RequestAsync();
                                _manager = AwaitOp(opMgr);
                            }

                            if (_manager != null) {
                                var session = GetTargetSession();
                                if (session == null) { 
                                    lock(_stateLock) { 
                                        _hasMedia = false; _lastTrackId = ""; _thumbnailBytes = null;
                                    } 
                                    Thread.Sleep(500); 
                                    continue; 
                                }
                                
                                var opInfo = session.TryGetMediaPropertiesAsync();
                                var info = AwaitOp(opInfo);
                                var playback = session.GetPlaybackInfo();
                                
                                string title = info != null && info.Title != null ? info.Title : ""; 
                                string artist = info != null ? (!string.IsNullOrEmpty(info.Artist) ? info.Artist : (!string.IsNullOrEmpty(info.AlbumArtist) ? info.AlbumArtist : "")) : ""; 
                                string appId = session.SourceAppUserModelId ?? "";
                                bool isPlaying = playback != null && playback.PlaybackStatus == GlobalSystemMediaTransportControlsSessionPlaybackStatus.Playing;
                                string currentTrackId = title + " - " + artist;
                                
                                byte[] thumbBytes = _thumbnailBytes;
                                
                                bool trackChanged = (currentTrackId != _lastTrackId);
                                if (trackChanged) {
                                    _ticksSinceTrackChange = 0;
                                    thumbBytes = null; 
                                } else {
                                    if (_ticksSinceTrackChange < 100) _ticksSinceTrackChange++;
                                }

                                bool forceThumbRefresh = (_ticksSinceTrackChange == 3 || _ticksSinceTrackChange == 8);

                                if (trackChanged || forceThumbRefresh || (thumbBytes == null && info != null && info.Thumbnail != null)) {
                                    if (info != null && info.Thumbnail != null) {
                                        try {
                                            var opStream = info.Thumbnail.OpenReadAsync();
                                            var streamRef = AwaitOp(opStream);
                                            if (streamRef != null && streamRef.Size > 0) {
                                                using (streamRef) {
                                                    var buffer = new Windows.Storage.Streams.Buffer((uint)streamRef.Size);
                                                    var opRead = streamRef.ReadAsync(buffer, buffer.Capacity, InputStreamOptions.None);
                                                    AwaitOpProgress(opRead);
                                                    using (var dataReader = DataReader.FromBuffer(buffer)) {
                                                        byte[] bytes = new byte[(int)buffer.Length];
                                                        dataReader.ReadBytes(bytes);
                                                        thumbBytes = bytes;
                                                    }
                                                }
                                            }
                                        } catch { }
                                    }
                                }

                                lock(_stateLock) {
                                    _hasMedia = true; 
                                    _title = title; 
                                    _artist = artist; 
                                    _appId = appId; 
                                    _isPlaying = isPlaying;
                                    _thumbnailBytes = thumbBytes;
                                }

                                _lastTrackId = currentTrackId;
                            }
                        } catch { lock(_stateLock) { _hasMedia = false; } }
                        
                        Thread.Sleep(400);
                    }
                });
            }
            
            public static void PlayPause() { Task.Run(() => { try { if (_manager != null) { var s = GetTargetSession(); if(s != null) AwaitOp(s.TryTogglePlayPauseAsync()); } } catch { }}); }
            public static void Next() { Task.Run(() => { try { if (_manager != null) { var s = GetTargetSession(); if(s != null) { var pb = s.GetPlaybackInfo(); AwaitOp(s.TrySkipNextAsync()); if (pb != null && pb.PlaybackStatus != GlobalSystemMediaTransportControlsSessionPlaybackStatus.Playing) { Thread.Sleep(150); AwaitOp(s.TryPlayAsync()); } } } } catch { }}); }
            public static void Prev() { Task.Run(() => { try { if (_manager != null) { var s = GetTargetSession(); if(s != null) { var pb = s.GetPlaybackInfo(); AwaitOp(s.TrySkipPreviousAsync()); if (pb != null && pb.PlaybackStatus != GlobalSystemMediaTransportControlsSessionPlaybackStatus.Playing) { Thread.Sleep(150); AwaitOp(s.TryPlayAsync()); } } } } catch { }}); }
        }
"@
        $winmdPath = "$env:windir\System32\WinMetadata"
        $cp = New-Object System.CodeDom.Compiler.CompilerParameters
        $cp.GenerateInMemory = $true
        
        $cp.CompilerOptions = "/reference:`"$winmdPath\Windows.Foundation.winmd`" /reference:`"$winmdPath\Windows.Media.winmd`" /reference:`"$winmdPath\Windows.Storage.winmd`""
        
        $cp.ReferencedAssemblies.Add("System.dll") | Out-Null
        $cp.ReferencedAssemblies.Add("System.Core.dll") | Out-Null
        
        @("System.Runtime", "System.Threading.Tasks", "System.IO", "System.Collections") | ForEach-Object {
            $asm = [System.Reflection.Assembly]::LoadWithPartialName($_)
            if ($null -ne $asm -and -not [string]::IsNullOrWhiteSpace($asm.Location)) { 
                $cp.ReferencedAssemblies.Add($asm.Location) | Out-Null 
            }
        }

        Add-Type -TypeDefinition $smtcSig -Language CSharp -CompilerParameters $cp -ErrorAction Stop
        
        [MediaTracker]::Start()
        $global:MediaAPIEnabled = $true
    } catch {
        $_ | Out-File "$env:APPDATA\Detaroxz\WinQL\smtc_error.log" -Append
        $global:MediaAPIEnabled = $false
    }

    $mutexCreated = $false
    $script:appMutex = New-Object System.Threading.Mutex($true, "Global\WinQLDesktop_Mutex", [ref]$mutexCreated)
    if (-not $mutexCreated) { Exit }

    $appDataFolder = "$env:APPDATA\Detaroxz\WinQL"
    $settingsFile = "$appDataFolder\settings.json"

    function Get-ThemeColor {
        try {
            $reg = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -ErrorAction Stop
            if ($reg -eq 1) { return "#000000" } else { return "#FFFFFF" }
        } catch { 
            if ($null -ne $script:lastThemeColor) { return $script:lastThemeColor }
            return "#FFFFFF" 
        }
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
        if ($null -eq $loaded.VerticalOffset) { $loaded | Add-Member -MemberType NoteProperty -Name "VerticalOffset" -Value 2 -Force }
        if ($null -eq $loaded.CompensateBorder) { $loaded | Add-Member -MemberType NoteProperty -Name "CompensateBorder" -Value $true -Force }
        if ($null -eq $loaded.Spacing) { $loaded | Add-Member -MemberType NoteProperty -Name "Spacing" -Value 15 -Force }
        if ($null -eq $loaded.ButtonSize) { $loaded | Add-Member -MemberType NoteProperty -Name "ButtonSize" -Value 40 -Force }
        if ($null -eq $loaded.Orientation) { $loaded | Add-Member -MemberType NoteProperty -Name "Orientation" -Value "Horizontal" -Force }
        
        if ($null -eq $loaded.StartupMethod) {
            if ($null -ne $loaded.Startup -and $loaded.Startup -eq $true) {
                $loaded | Add-Member -MemberType NoteProperty -Name "StartupMethod" -Value "Registry" -Force
            } else {
                $loaded | Add-Member -MemberType NoteProperty -Name "StartupMethod" -Value "Task Manager" -Force
            }
        }
        
        if ($null -eq $loaded.ShowBorders) { $loaded | Add-Member -MemberType NoteProperty -Name "ShowBorders" -Value $false -Force }
        if ($null -eq $loaded.FontColorMode) { $loaded | Add-Member -MemberType NoteProperty -Name "FontColorMode" -Value "Auto" -Force }
        if ($null -eq $loaded.CustomFontColor) { $loaded | Add-Member -MemberType NoteProperty -Name "CustomFontColor" -Value "#00FF00" -Force }
        if ($null -eq $loaded.GlobalBtnFontFamily) { $loaded | Add-Member -MemberType NoteProperty -Name "GlobalBtnFontFamily" -Value "Segoe UI" -Force }
        if ($null -eq $loaded.GlobalBtnFontSize) { $loaded | Add-Member -MemberType NoteProperty -Name "GlobalBtnFontSize" -Value 20.0 -Force }
        if ($null -eq $loaded.GlobalBtnFontBold) { $loaded | Add-Member -MemberType NoteProperty -Name "GlobalBtnFontBold" -Value $true -Force }
        if ($null -eq $loaded.GlobalBtnFontItalic) { $loaded | Add-Member -MemberType NoteProperty -Name "GlobalBtnFontItalic" -Value $false -Force }

        if ($null -eq $loaded.MusicFontFamily) { $loaded | Add-Member -MemberType NoteProperty -Name "MusicFontFamily" -Value "Segoe UI" -Force }
        if ($null -eq $loaded.MusicFontColorMode) { $loaded | Add-Member -MemberType NoteProperty -Name "MusicFontColorMode" -Value "Auto" -Force }
        if ($null -eq $loaded.MusicCustomColor) { $loaded | Add-Member -MemberType NoteProperty -Name "MusicCustomColor" -Value "#00FF00" -Force }
        
        if ($null -eq $loaded.MaxTitleLength) { $loaded | Add-Member -MemberType NoteProperty -Name "MaxTitleLength" -Value 35 -Force }
        if ($null -eq $loaded.MaxArtistLength) { $loaded | Add-Member -MemberType NoteProperty -Name "MaxArtistLength" -Value 30 -Force }

        if ($null -eq $loaded.Buttons) { $loaded | Add-Member -MemberType NoteProperty -Name "Buttons" -Value @() -Force }
        $btns = @()
        for ($i=0; $i -lt 10; $i++) {
            $btn = $null
            if ($loaded.Buttons.Count -gt $i) { $btn = $loaded.Buttons[$i] }
            if ($null -eq $btn) { $btn = New-Object PSObject }
            
            $defaultChar = if ($i -eq 9) { "0" } else { ($i + 1).ToString() }
            if ($null -eq $btn.Char -or $btn.Char -eq "") { $btn | Add-Member -MemberType NoteProperty -Name "Char" -Value $defaultChar -Force }
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
                            $ns = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.InterfaceDescription -match "Wi-Fi" -or $_.Name -match "Wi-Fi" } | Select-Object -First 1
                            if ($ns.Status -eq "Up") { Disable-NetAdapter -Name $ns.Name -Confirm:$false } else { Enable-NetAdapter -Name $ns.Name -Confirm:$false }
                        }
                        elseif ($val -eq "bt") { Start-Process "ms-settings:bluetooth" }
                        elseif ($val -match "^vol:inc:(\d+)$") { $loops = [math]::Ceiling([int]$matches[1] / 2); for($i=0; $i -lt $loops; $i++) { [Native]::keybd_event(0xAF, 0, 1, 0); [Native]::keybd_event(0xAF, 0, 3, 0) } }
                        elseif ($val -match "^vol:dec:(\d+)$") { $loops = [math]::Ceiling([int]$matches[1] / 2); for($i=0; $i -lt $loops; $i++) { [Native]::keybd_event(0xAE, 0, 1, 0); [Native]::keybd_event(0xAE, 0, 3, 0) } }
                        elseif ($val -eq "vol:mute") { [Native]::keybd_event(0xAD, 0, 1, 0); [Native]::keybd_event(0xAD, 0, 3, 0) }
                        elseif ($val -match "^bright:inc:(\d+)$") {
                            try { $wmio = Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightness -ErrorAction Stop | Select-Object -First 1; if ($null -ne $wmio) { $cur = $wmio.CurrentBrightness; $new = $cur + [int]$matches[1]; if ($new -gt 100) { $new = 100 }; (Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods).WmiSetBrightness(1, $new) } } catch {}
                        }
                        elseif ($val -match "^bright:dec:(\d+)$") {
                            try { $wmio = Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightness -ErrorAction Stop | Select-Object -First 1; if ($null -ne $wmio) { $cur = $wmio.CurrentBrightness; $new = $cur - [int]$matches[1]; if ($new -lt 0) { $new = 0 }; (Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods).WmiSetBrightness(1, $new) } } catch {}
                        }
                        elseif ($val -match "^bright:set:(\d+)$") {
                            try { $wmio = Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods -ErrorAction Stop; $lvl = [int]$matches[1]; if ($lvl -gt 100) { $lvl = 100 }; if ($lvl -lt 0) { $lvl = 0 }; $wmio.WmiSetBrightness(1, $lvl) } catch {}
                        }
                    }
                    "pers" {
                        if ($val -match "^wall:(.+)$") {
                            $imgPath = $matches[1]
                            if (Test-Path $imgPath) {
                                [Native]::SystemParametersInfo(20, 0, $imgPath, 3) | Out-Null
                            }
                        }
                        elseif ($val -match "^theme:(.+)$") {
                            $theme = $matches[1]
                            $regKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
                            if ($theme -eq "toggle") {
                                $current = Get-ItemPropertyValue -Path $regKey -Name "SystemUsesLightTheme" -ErrorAction SilentlyContinue
                                if ($current -eq 1) { $theme = "dark" } else { $theme = "light" }
                            }
                            if ($theme -eq "dark") {
                                Set-ItemProperty -Path $regKey -Name "SystemUsesLightTheme" -Value 0 -ErrorAction SilentlyContinue
                                Set-ItemProperty -Path $regKey -Name "AppsUseLightTheme" -Value 0 -ErrorAction SilentlyContinue
                            } elseif ($theme -eq "light") {
                                Set-ItemProperty -Path $regKey -Name "SystemUsesLightTheme" -Value 1 -ErrorAction SilentlyContinue
                                Set-ItemProperty -Path $regKey -Name "AppsUseLightTheme" -Value 1 -ErrorAction SilentlyContinue
                            }
                            [Native]::UpdateTheme()
                        }
                    }
                    "cmd" {
                        $parts = $val -split ':', 3
                        if ($parts.Length -eq 3) {
                            $shell = $parts[0]
                            $mode = $parts[1]
                            $command = $parts[2]
                            $winStyle = if ($mode -eq "vis") { "Normal" } else { "Hidden" }
                            if ($shell -eq "ps") {
                                Start-Process "powershell.exe" -ArgumentList "-NoProfile -Command `"$command`"" -WindowStyle $winStyle
                            } elseif ($shell -eq "cmd") {
                                Start-Process "cmd.exe" -ArgumentList "/c `"$command`"" -WindowStyle $winStyle
                            }
                        }
                    }
                    "key" { [System.Windows.Forms.SendKeys]::SendWait($val) }
                    "clip" { if ($val -eq "copy") { [System.Windows.Forms.SendKeys]::SendWait("^c") } elseif ($val -eq "cut") { [System.Windows.Forms.SendKeys]::SendWait("^x") } elseif ($val -eq "paste") { [System.Windows.Forms.SendKeys]::SendWait("^v") } }
                    "nav" { if ($val -eq "back") { [Native]::keybd_event(0xA6, 0, 1, 0); [Native]::keybd_event(0xA6, 0, 3, 0) } elseif ($val -eq "forward") { [Native]::keybd_event(0xA7, 0, 1, 0); [Native]::keybd_event(0xA7, 0, 3, 0) } }
                    "media" {
                        if ($global:MediaAPIEnabled -and -not $script:usingFallbackMedia) {
                            if ($val -eq "play") { [MediaTracker]::PlayPause() } 
                            elseif ($val -eq "next") { [MediaTracker]::Next() } 
                            elseif ($val -eq "prev") { [MediaTracker]::Prev() }
                            elseif ($val -eq "cycle") { [MediaTracker]::CycleSession() }
                        } else {
                            if ($val -eq "play") { 
                                [Native]::keybd_event(0xB3, 0, 1, 0); [Native]::keybd_event(0xB3, 0, 3, 0) 
                            } 
                            elseif ($val -eq "stop") { 
                                [Native]::keybd_event(0xB2, 0, 1, 0); [Native]::keybd_event(0xB2, 0, 3, 0) 
                            } 
                            elseif ($val -eq "next") { 
                                [Native]::keybd_event(0xB0, 0, 1, 0); [Native]::keybd_event(0xB0, 0, 3, 0) 
                                if (-not $script:wasPlaying) { Start-Sleep -Milliseconds 150; [Native]::keybd_event(0xB3, 0, 1, 0); [Native]::keybd_event(0xB3, 0, 3, 0) }
                            } 
                            elseif ($val -eq "prev") { 
                                [Native]::keybd_event(0xB1, 0, 1, 0); [Native]::keybd_event(0xB1, 0, 3, 0) 
                                if (-not $script:wasPlaying) { Start-Sleep -Milliseconds 150; [Native]::keybd_event(0xB3, 0, 1, 0); [Native]::keybd_event(0xB3, 0, 3, 0) }
                            }
                        }
                    }
                    "exp" { Start-Process $val }
                    "web" { Start-Process $val }
                    "kill" { Stop-Process -Name $val -Force -ErrorAction SilentlyContinue }
                    "switch" { 
                        $procs = [System.Diagnostics.Process]::GetProcesses()
                        foreach ($p in $procs) {
                            if ($p.MainWindowTitle -eq $val -and $p.MainWindowHandle -ne [IntPtr]::Zero) { 
                                [Native]::ShowWindow($p.MainWindowHandle, 9) | Out-Null
                                [Native]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
                                break
                            }
                        }
                        foreach ($p in $procs) { $p.Dispose() }
                    }
                    "winql" { 
                        if ($val -eq "settings") { Show-SettingsWindow } 
                    }
                }
            } catch { [System.Windows.Forms.MessageBox]::Show("Action failed: $cmd", "WinQL Engine Error", 0, 16) }
        } else {
            try { Start-Process $cmd -ErrorAction Stop } catch { [System.Windows.Forms.MessageBox]::Show("Failed to launch: $cmd", "WinQL Error", 0, 16) }
        }
    }

    # --- UI XAML ---
    $uiXAML = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="WinQL" SizeToContent="WidthAndHeight"
            WindowStyle="None" AllowsTransparency="True" Background="Transparent" 
            ShowInTaskbar="False" Opacity="1" ShowActivated="False" Focusable="False">
        <Grid Name="MainGrid" VerticalAlignment="Center">
            <StackPanel Name="LayoutStack" Orientation="Horizontal" VerticalAlignment="Center">
                
                <!-- MEDIA PLAYER PANEL WITH ADAPTIVE THUMBNAIL AND FALLBACK -->
                <Border Name="MusicContainer" Visibility="Collapsed" Background="Transparent" VerticalAlignment="Center">
                    <StackPanel Name="SongInfoPanel" Orientation="Horizontal" Background="#01000000" VerticalAlignment="Center" Cursor="Hand" Margin="0,0,10,0" Height="40">
                        
                        <Border Name="ThumbnailWrapper" Margin="0,0,10,0" VerticalAlignment="Center" Visibility="Collapsed" Width="40" Height="40" Background="#33FFFFFF" CornerRadius="4">
                            <Grid>
                                <!-- Main Thumbnail/Icon (Mask applied dynamically via PS) -->
                                <Image Name="SongThumbnail" Stretch="UniformToFill" Visibility="Collapsed" />
                                
                                <!-- Letter Fallback (Visible only if image fails) -->
                                <TextBlock Name="ThumbnailFallbackE" Text="" FontSize="20" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center" VerticalAlignment="Center" Visibility="Collapsed" />
                                
                                <!-- Vector Pause Overlay (Never glitches) -->
                                <Border Name="PauseOverlay" Background="#99000000" CornerRadius="4" Visibility="Collapsed">
                                    <Path Data="M 0,0 H 3 V 12 H 0 Z M 7,0 H 10 V 12 H 7 Z" Fill="White" HorizontalAlignment="Center" VerticalAlignment="Center" Width="10" Height="12" />
                                </Border>
                            </Grid>
                        </Border>

                        <StackPanel VerticalAlignment="Center">
                            <TextBlock Name="SongTitle" FontSize="14" FontWeight="SemiBold" Padding="0,0,0,0" Margin="0,-2,0,0"/>
                            <TextBlock Name="SongArtist" FontSize="11" FontWeight="Normal" Padding="0,0,0,0" Margin="0,-2,0,0" Opacity="0.65"/>
                        </StackPanel>
                    </StackPanel>
                </Border>

                <!-- MEDIA TOGGLE PIN -->
                <Border Name="MediaToggleBtn" Background="#01000000" Cursor="Hand" VerticalAlignment="Center" Visibility="Collapsed">
                    <TextBlock Name="MediaToggleText" Text="&#xE189;" FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" FontSize="16" VerticalAlignment="Center" HorizontalAlignment="Center"/>
                </Border>
                
                <!-- BUTTONS PANEL -->
                <StackPanel Name="ButtonPanel" Orientation="Horizontal" VerticalAlignment="Center" />
                
            </StackPanel>
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
            $trayRect.left = $tbRect.right; $trayRect.top = $tbRect.bottom
        }

        $dpiX = 1.0; $dpiY = 1.0
        try {
            $source = [System.Windows.PresentationSource]::FromVisual($script:window)
            if ($source -and $source.CompositionTarget) { $dpiX = $source.CompositionTarget.TransformToDevice.M11; $dpiY = $source.CompositionTarget.TransformToDevice.M22 }
        } catch {}

        $logicalW = $script:MainGrid.ActualWidth
        $logicalH = $script:MainGrid.ActualHeight
        if ($logicalW -eq 0 -or [double]::IsNaN($logicalW)) { $logicalW = 200 }
        if ($logicalH -eq 0 -or [double]::IsNaN($logicalH)) { $logicalH = $global:Settings.ButtonSize }

        $pw = [int]($logicalW * $dpiX); $ph = [int]($logicalH * $dpiY)
        $tbW = $tbRect.right - $tbRect.left; $tbH = $tbRect.bottom - $tbRect.top
        $edge = [Native]::GetTaskbarEdge()
        $align = $global:Settings.Alignment
        $taskbarAl = 0; try { $taskbarAl = Get-ItemPropertyValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -ErrorAction SilentlyContinue } catch {}
        if ($taskbarAl -eq $null) { $taskbarAl = 0 }
        if (($edge -eq 1 -or $edge -eq 3) -and $taskbarAl -eq 1 -and $align -eq "Center") { $align = "Right" }
        if ($edge -eq 0 -and $align -eq "Left") { $align = "Center" }

        $x = 0; $y = 0
        if ($edge -eq 1 -or $edge -eq 3) { 
            $y = [int](($tbH - $ph) / 2) + $global:Settings.VerticalOffset
            if ($global:Settings.CompensateBorder -and $edge -eq 3) { $y += 1 } 
            if ($align -eq "Left") { $x = [int]($global:Settings.LeftSpacing * $dpiX) } elseif ($align -eq "Right") { $x = $trayRect.left - $pw - [int]($global:Settings.RightSpacing * $dpiX) } else { $x = [int](($tbW - $pw) / 2) }
        } else { 
            $x = [int](($tbW - $pw) / 2) + $global:Settings.VerticalOffset
            if ($global:Settings.CompensateBorder -and $edge -eq 3) { $y += 1 } 
            if ($align -eq "Left") { $y = [int]($global:Settings.LeftSpacing * $dpiY) } elseif ($align -eq "Right") { $y = $trayRect.top - $ph - [int]($global:Settings.RightSpacing * $dpiY) } else { $y = [int](($tbH - $ph) / 2) }
        }
        if ($x -lt 0) { $x = 0 }; if ($y -lt 0) { $y = 0 }

        [Native]::SetWindowPos($script:hwnd, [IntPtr]::Zero, $x, $y, 0, 0, 0x0005) | Out-Null
    }

    function Render-Layout {
        if ($null -eq $script:ButtonPanel) { return }
        $script:ButtonPanel.Children.Clear()
        
        $script:MediaToggleBtn.Width = $global:Settings.ButtonSize; $script:MediaToggleBtn.Height = $global:Settings.ButtonSize
        $spc = $global:Settings.Spacing
        $script:LayoutStack.Orientation = if ($global:Settings.Orientation -eq "Vertical") { [System.Windows.Controls.Orientation]::Vertical } else { [System.Windows.Controls.Orientation]::Horizontal }
        $script:ButtonPanel.Orientation = $script:LayoutStack.Orientation

        $script:LayoutStack.Children.Remove($script:ButtonPanel)
        $script:LayoutStack.Children.Remove($script:MediaToggleBtn)
        $script:LayoutStack.Children.Remove($script:MusicContainer)

        $script:LayoutStack.Children.Add($script:MusicContainer) | Out-Null
        $script:LayoutStack.Children.Add($script:MediaToggleBtn) | Out-Null
        $script:LayoutStack.Children.Add($script:ButtonPanel) | Out-Null
        
        $script:MediaToggleBtn.Margin = if ($global:Settings.Orientation -eq "Vertical") { New-Object System.Windows.Thickness(0,$spc,0,0) } else { New-Object System.Windows.Thickness($spc,0,0,0) }
        $script:ButtonPanel.Margin = if ($global:Settings.Orientation -eq "Vertical") { New-Object System.Windows.Thickness(0,$spc,0,0) } else { New-Object System.Windows.Thickness($spc,0,0,0) }
        $script:MusicContainer.Margin = New-Object System.Windows.Thickness(0,0,0,0)
        
        $script:SongTitle.FontFamily = New-Object System.Windows.Media.FontFamily($global:Settings.MusicFontFamily)
        $script:SongArtist.FontFamily = New-Object System.Windows.Media.FontFamily($global:Settings.MusicFontFamily)

        $brushConv = New-Object System.Windows.Media.BrushConverter
        $fcMode = $global:Settings.FontColorMode
        if ($fcMode -eq "Auto") { $fcHex = Get-ThemeColor } elseif ($fcMode -eq "White") { $fcHex = "#FFFFFF" } elseif ($fcMode -eq "Black") { $fcHex = "#000000" } else { $fcHex = $global:Settings.CustomFontColor }
        try { $fontBrush = $brushConv.ConvertFromString($fcHex) } catch { $fontBrush = [System.Windows.Media.Brushes]::White }

        $script:MediaToggleText.Foreground = $fontBrush

        for ($i=0; $i -lt $global:Settings.BtnCount; $i++) {
            $btnDef = $global:Settings.Buttons[$i]
            $border = New-Object System.Windows.Controls.Border; $border.Background = $brushConv.ConvertFromString("#01000000"); $border.Cursor = [System.Windows.Input.Cursors]::Hand
            $border.Width = $global:Settings.ButtonSize; $border.Height = $global:Settings.ButtonSize
            if ($global:Settings.ShowBorders) { $border.BorderBrush = [System.Windows.Media.Brushes]::Red; $border.BorderThickness = New-Object System.Windows.Thickness(1) } else { $border.BorderThickness = New-Object System.Windows.Thickness(0) }
            if ($i -gt 0) { if ($global:Settings.Orientation -eq "Vertical") { $border.Margin = New-Object System.Windows.Thickness(0, $global:Settings.Spacing, 0, 0) } else { $border.Margin = New-Object System.Windows.Thickness($global:Settings.Spacing, 0, 0, 0) } }
            
            $tb = New-Object System.Windows.Controls.TextBlock; $tb.Text = $btnDef.Char; $tb.FontSize = $global:Settings.GlobalBtnFontSize; $tb.FontFamily = New-Object System.Windows.Media.FontFamily($global:Settings.GlobalBtnFontFamily)
            $tb.Foreground = $fontBrush; $tb.VerticalAlignment = [System.Windows.VerticalAlignment]::Center; $tb.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center; $tb.IsHitTestVisible = $false
            if ($global:Settings.GlobalBtnFontBold) { $tb.FontWeight = [System.Windows.FontWeights]::Bold } else { $tb.FontWeight = [System.Windows.FontWeights]::Normal }
            if ($global:Settings.GlobalBtnFontItalic) { $tb.FontStyle = [System.Windows.FontStyles]::Italic } else { $tb.FontStyle = [System.Windows.FontStyles]::Normal }
            
            $border.Child = $tb
            $clickState = @{ Timer = New-Object System.Windows.Threading.DispatcherTimer; ClickCount = 0; BtnType = ""; Def = $btnDef }
            $clickState.Timer.Interval = [TimeSpan]::FromMilliseconds(300)
            $clickState.Timer.Add_Tick({
                $state = $this.Tag; $state.Timer.Stop(); $btnType = $state.BtnType; $def = $state.Def; $count = $state.ClickCount; $state.ClickCount = 0
                $targetPaths = @()
                if ($count -eq 1) {
                    if ($btnType -eq 'Left' -and $def.EnLeft) { $targetPaths = $def.LeftActions } elseif ($btnType -eq 'Right' -and $def.EnRight) { $targetPaths = $def.RightActions } elseif ($btnType -eq 'Middle' -and $def.EnMid) { $targetPaths = $def.MidActions }
                } elseif ($count -ge 2) {
                    if ($btnType -eq 'Left' -and $def.EnLeftDouble) { $targetPaths = $def.LeftDoubleActions } elseif ($btnType -eq 'Right' -and $def.EnRightDouble) { $targetPaths = $def.RightDoubleActions } elseif ($btnType -eq 'Left' -and $def.EnLeft) { $targetPaths = $def.LeftActions } elseif ($btnType -eq 'Right' -and $def.EnRight) { $targetPaths = $def.RightActions } elseif ($btnType -eq 'Middle' -and $def.EnMid) { $targetPaths = $def.MidActions }
                }
                foreach ($p in $targetPaths) { Execute-Action $p }
            })
            $clickState.Timer.Tag = $clickState; $border.Tag = $clickState
            $border.Add_PreviewMouseDown({
                param($sender, $e)
                $state = $sender.Tag; $btnTypeStr = $e.ChangedButton.ToString()
                if ($state.BtnType -ne $btnTypeStr -and $state.ClickCount -gt 0) { $state.ClickCount = 0 }
                $state.BtnType = $btnTypeStr; $state.ClickCount++; $state.Timer.Stop(); $state.Timer.Start()
            })
            $script:ButtonPanel.Children.Add($border) | Out-Null
        }
        Update-Window-Position
        
        # Flush working set heavily after layout redraws
        [System.GC]::Collect()
        [Native]::SetProcessWorkingSetSize([System.Diagnostics.Process]::GetCurrentProcess().Handle, -1, -1) | Out-Null
    }

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
        $abReader = New-Object System.IO.StringReader($abXAML); $abWin = [System.Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create($abReader))
        $cmbCat = $abWin.FindName("cmbCat"); $cmbSub = $abWin.FindName("cmbSub"); $txtVal = $abWin.FindName("txtVal"); $btnOk = $abWin.FindName("btnOk"); $cmbDynamic = $abWin.FindName("cmbDynamic"); $btnBrowse = $abWin.FindName("btnBrowse"); $lblVal = $abWin.FindName("lblVal"); $lblSub = $abWin.FindName("lblSub"); $gridVal = $abWin.FindName("gridVal"); $pnlKeys = $abWin.FindName("pnlKeys")
        
        $script:builtAction = $null
        $abWin.FindName("btnCtrl").Add_Click({ $txtVal.Text += "^" }); $abWin.FindName("btnAlt").Add_Click({ $txtVal.Text += "%" }); $abWin.FindName("btnShift").Add_Click({ $txtVal.Text += "+" }); $abWin.FindName("btnCaps").Add_Click({ $txtVal.Text += "{CAPSLOCK}" }); $abWin.FindName("btnNum").Add_Click({ $txtVal.Text += "{NUMLOCK}" })
        "System","Keyboard Shortcut","Clipboard","Navigation","Explorer / File / Folder","Media Control","Open App / Switch Window","Open Website","Kill Process","WinQL Internal Actions","Personalization","Run a Command" | ForEach-Object { $cmbCat.Items.Add($_) | Out-Null }
        
        $cmbCat.Add_SelectionChanged({
            param($sender, $e)
            $cat = Get-ComboText $sender; if ([string]::IsNullOrWhiteSpace($cat)) { return }
            $cmbSub.Items.Clear(); $cmbSub.Visibility = "Collapsed"; $lblSub.Visibility = "Collapsed"; $lblVal.Visibility = "Collapsed"; $gridVal.Visibility = "Collapsed"; $txtVal.Visibility = "Collapsed"; $cmbDynamic.Visibility = "Collapsed"; $btnBrowse.Visibility = "Collapsed"; $pnlKeys.Visibility = "Collapsed"
            switch ($cat) {
                "System" { $lblSub.Visibility = "Visible"; $cmbSub.Visibility = "Visible"; "Toggle Wi-Fi","Bluetooth Settings","Increase Volume by X%","Decrease Volume by X%","Mute / Unmute Volume","Increase Brightness by X%","Decrease Brightness by X%","Set Brightness to X%" | ForEach-Object { $cmbSub.Items.Add($_) | Out-Null }; $cmbSub.SelectedIndex = 0 }
                "Keyboard Shortcut" { $lblVal.Visibility = "Visible"; $gridVal.Visibility = "Visible"; $txtVal.Visibility = "Visible"; $pnlKeys.Visibility = "Visible"; $lblVal.Text = "Keystroke (Use buttons to insert modifiers):"; $txtVal.Text = "{ENTER}" }
                "Clipboard" { $lblSub.Visibility = "Visible"; $cmbSub.Visibility = "Visible"; "Copy","Cut","Paste" | ForEach-Object { $cmbSub.Items.Add($_) | Out-Null }; $cmbSub.SelectedIndex = 0 }
                "Navigation" { $lblSub.Visibility = "Visible"; $cmbSub.Visibility = "Visible"; "Forward","Backward" | ForEach-Object { $cmbSub.Items.Add($_) | Out-Null }; $cmbSub.SelectedIndex = 0 }
                "Media Control" { $lblSub.Visibility = "Visible"; $cmbSub.Visibility = "Visible"; "Play / Pause","Stop","Next Track","Previous Track" | ForEach-Object { $cmbSub.Items.Add($_) | Out-Null }; $cmbSub.SelectedIndex = 0 }
                "Explorer / File / Folder" { $lblSub.Visibility = "Visible"; $cmbSub.Visibility = "Visible"; "Open File","Open Folder" | ForEach-Object { $cmbSub.Items.Add($_) | Out-Null }; $cmbSub.SelectedIndex = 0 }
                "Open App / Switch Window" { $lblSub.Visibility = "Visible"; $cmbSub.Visibility = "Visible"; "Launch Start Menu App","Switch to Open Window" | ForEach-Object { $cmbSub.Items.Add($_) | Out-Null }; $cmbSub.SelectedIndex = 0 }
                "Open Website" { $lblVal.Visibility = "Visible"; $gridVal.Visibility = "Visible"; $txtVal.Visibility = "Visible"; $lblVal.Text = "Website URL:"; $txtVal.Text = "https://google.com" }
                "Kill Process" { $lblSub.Visibility = "Visible"; $cmbSub.Visibility = "Visible"; "Select Process to Kill" | ForEach-Object { $cmbSub.Items.Add($_) | Out-Null }; $cmbSub.SelectedIndex = 0 }
                "WinQL Internal Actions" { $lblSub.Visibility = "Visible"; $cmbSub.Visibility = "Visible"; "Open Settings" | ForEach-Object { $cmbSub.Items.Add($_) | Out-Null }; $cmbSub.SelectedIndex = 0 }
                "Personalization" { $lblSub.Visibility = "Visible"; $cmbSub.Visibility = "Visible"; "Change Wallpaper","Toggle Dark/Light Mode","Set Dark Mode","Set Light Mode" | ForEach-Object { $cmbSub.Items.Add($_) | Out-Null }; $cmbSub.SelectedIndex = 0 }
                "Run a Command" { $lblSub.Visibility = "Visible"; $cmbSub.Visibility = "Visible"; "PowerShell (Visible)","PowerShell (Hidden)","CMD (Visible)","CMD (Hidden)" | ForEach-Object { $cmbSub.Items.Add($_) | Out-Null }; $cmbSub.SelectedIndex = 0 }
            }
        })
        
        $cmbSub.Add_SelectionChanged({
            param($sender, $e)
            $cat = Get-ComboText $cmbCat
            $sub = Get-ComboText $sender; if ([string]::IsNullOrWhiteSpace($sub)) { return }
            $lblVal.Visibility = "Collapsed"; $gridVal.Visibility = "Collapsed"; $txtVal.Visibility = "Collapsed"; $cmbDynamic.Visibility = "Collapsed"; $btnBrowse.Visibility = "Collapsed"
            if ($sub -match "X%") { $lblVal.Visibility = "Visible"; $gridVal.Visibility = "Visible"; $txtVal.Visibility = "Visible"; $lblVal.Text = "Enter Value (%) :"; if ($txtVal.Text -eq "") { $txtVal.Text = "10" } }
            elseif ($sub -eq "Open File" -or $sub -eq "Open Folder" -or $sub -eq "Change Wallpaper") { $lblVal.Visibility = "Visible"; $gridVal.Visibility = "Visible"; $txtVal.Visibility = "Visible"; $btnBrowse.Visibility = "Visible"; $lblVal.Text = "Path:" }
            elseif ($sub -eq "Launch Start Menu App") { $lblVal.Visibility = "Visible"; $gridVal.Visibility = "Visible"; $cmbDynamic.Visibility = "Visible"; $lblVal.Text = "Select App:"; $cmbDynamic.Items.Clear(); $paths = @("$env:ProgramData\Microsoft\Windows\Start Menu\Programs", "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"); $items = Get-ChildItem -Path $paths -Filter "*.lnk" -Recurse -ErrorAction SilentlyContinue; foreach ($i in $items) { $cmbDynamic.Items.Add($i.FullName) | Out-Null }; if ($cmbDynamic.Items.Count -gt 0) { $cmbDynamic.SelectedIndex = 0 } }
            elseif ($sub -eq "Switch to Open Window") { $lblVal.Visibility = "Visible"; $gridVal.Visibility = "Visible"; $cmbDynamic.Visibility = "Visible"; $lblVal.Text = "Select Window:"; $cmbDynamic.Items.Clear(); $procs = [System.Diagnostics.Process]::GetProcesses(); foreach ($p in $procs) { if (-not [string]::IsNullOrWhiteSpace($p.MainWindowTitle)) { $cmbDynamic.Items.Add($p.MainWindowTitle) | Out-Null } $p.Dispose() }; if ($cmbDynamic.Items.Count -gt 0) { $cmbDynamic.SelectedIndex = 0 } }
            elseif ($sub -eq "Select Process to Kill") { $lblVal.Visibility = "Visible"; $gridVal.Visibility = "Visible"; $cmbDynamic.Visibility = "Visible"; $lblVal.Text = "Select Process:"; $cmbDynamic.Items.Clear(); $procs = [System.Diagnostics.Process]::GetProcesses(); foreach ($p in $procs) { $cmbDynamic.Items.Add($p.Name) | Out-Null; $p.Dispose() }; if ($cmbDynamic.Items.Count -gt 0) { $cmbDynamic.SelectedIndex = 0 } }
            elseif ($cat -eq "Run a Command") { $lblVal.Visibility = "Visible"; $gridVal.Visibility = "Visible"; $txtVal.Visibility = "Visible"; $lblVal.Text = "Command:" }
        })
        
        $btnBrowse.Add_Click({ 
            $sub = Get-ComboText $cmbSub; 
            if ($sub -eq "Open File") { 
                $fd = New-Object System.Windows.Forms.OpenFileDialog; 
                if ($fd.ShowDialog() -eq 'OK') { $txtVal.Text = $fd.FileName } 
            } elseif ($sub -eq "Change Wallpaper") { 
                $fd = New-Object System.Windows.Forms.OpenFileDialog; 
                $fd.Filter = "Images (*.jpg;*.jpeg;*.png;*.bmp)|*.jpg;*.jpeg;*.png;*.bmp|All Files (*.*)|*.*"; 
                if ($fd.ShowDialog() -eq 'OK') { $txtVal.Text = $fd.FileName } 
            } else { 
                $fd = New-Object System.Windows.Forms.FolderBrowserDialog; 
                if ($fd.ShowDialog() -eq 'OK') { $txtVal.Text = $fd.SelectedPath } 
            } 
        })
        
        $cmbCat.SelectedIndex = 0
        $btnOk.Add_Click({
            $cat = Get-ComboText $cmbCat; $sub = Get-ComboText $cmbSub
            $val = if ($txtVal.Visibility -eq [System.Windows.Visibility]::Visible) { $txtVal.Text } elseif ($cmbDynamic.Visibility -eq [System.Windows.Visibility]::Visible) { Get-ComboText $cmbDynamic } else { "" }
            
            if ($cat -eq "System") {
                if ($sub -eq "Toggle Wi-Fi") { $script:builtAction = "<sys:wifi>" } elseif ($sub -eq "Bluetooth Settings") { $script:builtAction = "<sys:bt>" } elseif ($sub -eq "Increase Volume by X%") { $script:builtAction = "<sys:vol:inc:$val>" } elseif ($sub -eq "Decrease Volume by X%") { $script:builtAction = "<sys:vol:dec:$val>" } elseif ($sub -eq "Mute / Unmute Volume") { $script:builtAction = "<sys:vol:mute>" } elseif ($sub -eq "Increase Brightness by X%") { $script:builtAction = "<sys:bright:inc:$val>" } elseif ($sub -eq "Decrease Brightness by X%") { $script:builtAction = "<sys:bright:dec:$val>" } elseif ($sub -eq "Set Brightness to X%") { $script:builtAction = "<sys:bright:set:$val>" }
            }
            elseif ($cat -eq "Keyboard Shortcut") { $script:builtAction = "<key:$val>" }
            elseif ($cat -eq "Clipboard") { if ($sub -eq "Copy") { $script:builtAction = "<clip:copy>" } elseif ($sub -eq "Cut") { $script:builtAction = "<clip:cut>" } elseif ($sub -eq "Paste") { $script:builtAction = "<clip:paste>" } }
            elseif ($cat -eq "Navigation") { if ($sub -eq "Backward") { $script:builtAction = "<nav:back>" } elseif ($sub -eq "Forward") { $script:builtAction = "<nav:forward>" } }
            elseif ($cat -eq "Media Control") { if ($sub -eq "Play / Pause") { $script:builtAction = "<media:play>" } elseif ($sub -eq "Stop") { $script:builtAction = "<media:stop>" } elseif ($sub -eq "Next Track") { $script:builtAction = "<media:next>" } elseif ($sub -eq "Previous Track") { $script:builtAction = "<media:prev>" } }
            elseif ($cat -eq "Explorer / File / Folder") { $script:builtAction = "<exp:$val>" }
            elseif ($cat -eq "Open App / Switch Window") { if ($sub -eq "Launch Start Menu App") { $script:builtAction = "<exp:$val>" } elseif ($sub -eq "Switch to Open Window") { $script:builtAction = "<switch:$val>" } }
            elseif ($cat -eq "Open Website") { $script:builtAction = "<web:$val>" }
            elseif ($cat -eq "Kill Process") { $script:builtAction = "<kill:$val>" }
            elseif ($cat -eq "WinQL Internal Actions") { if ($sub -eq "Open Settings") { $script:builtAction = "<winql:settings>" } }
            elseif ($cat -eq "Personalization") {
                if ($sub -eq "Change Wallpaper") { $script:builtAction = "<pers:wall:$val>" }
                elseif ($sub -eq "Toggle Dark/Light Mode") { $script:builtAction = "<pers:theme:toggle>" }
                elseif ($sub -eq "Set Dark Mode") { $script:builtAction = "<pers:theme:dark>" }
                elseif ($sub -eq "Set Light Mode") { $script:builtAction = "<pers:theme:light>" }
            }
            elseif ($cat -eq "Run a Command") {
                if ($sub -eq "PowerShell (Visible)") { $script:builtAction = "<cmd:ps:vis:$val>" }
                elseif ($sub -eq "PowerShell (Hidden)") { $script:builtAction = "<cmd:ps:hid:$val>" }
                elseif ($sub -eq "CMD (Visible)") { $script:builtAction = "<cmd:cmd:vis:$val>" }
                elseif ($sub -eq "CMD (Hidden)") { $script:builtAction = "<cmd:cmd:hid:$val>" }
            }
            $abWin.Close()
        })
        $abWin.ShowDialog() | Out-Null
        return $script:builtAction
    }

    function Add-ActionTextBox ($parentPanel, $text) {
        $grid = New-Object System.Windows.Controls.Grid; $grid.Margin = New-Object System.Windows.Thickness(0,0,0,5)
        $cd1 = New-Object System.Windows.Controls.ColumnDefinition; $cd1.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
        $cd2 = New-Object System.Windows.Controls.ColumnDefinition; $cd2.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Auto)
        $cd3 = New-Object System.Windows.Controls.ColumnDefinition; $cd3.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Auto)
        $grid.ColumnDefinitions.Add($cd1); $grid.ColumnDefinitions.Add($cd2); $grid.ColumnDefinitions.Add($cd3)
        $tb = New-Object System.Windows.Controls.TextBox; $tb.Text = $text; $tb.Padding = New-Object System.Windows.Thickness(2); [System.Windows.Controls.Grid]::SetColumn($tb, 0); $tb.Add_TextChanged($script:updateAction)
        $btnB = New-Object System.Windows.Controls.Button; $btnB.Content = "Build"; $btnB.Padding = New-Object System.Windows.Thickness(10,0,10,0); $btnB.Margin = New-Object System.Windows.Thickness(5,0,0,0); $btnB.Cursor = [System.Windows.Input.Cursors]::Hand; [System.Windows.Controls.Grid]::SetColumn($btnB, 1); $btnB.Tag = $tb; $btnB.Add_Click({ param($sender, $e) $res = Show-ActionBuilder; if ($res) { $sender.Tag.Text = $res; & $script:updateAction } })
        $btnD = New-Object System.Windows.Controls.Button; $btnD.Content = "Delete"; $btnD.Padding = New-Object System.Windows.Thickness(10,0,10,0); $btnD.Margin = New-Object System.Windows.Thickness(5,0,0,0); $btnD.Cursor = [System.Windows.Input.Cursors]::Hand; [System.Windows.Controls.Grid]::SetColumn($btnD, 2); $btnD.Tag = @{ Panel=$parentPanel; Grid=$grid }; $btnD.Add_Click({ param($sender, $e) $data = $sender.Tag; $data.Panel.Children.Remove($data.Grid); & $script:updateAction })
        $grid.Children.Add($tb) | Out-Null; $grid.Children.Add($btnB) | Out-Null; $grid.Children.Add($btnD) | Out-Null
        $parentPanel.Children.Add($grid) | Out-Null
    }

    $script:updateAction = {
        if ($script:isLoading) { return }
        try {
            $global:Settings.BtnCount = $script:sldCount.Value; $global:Settings.Alignment = Get-ComboText $script:cmbAlignment; $global:Settings.LeftSpacing = $script:sldLeftSpacing.Value; $global:Settings.RightSpacing = $script:sldRightSpacing.Value; $global:Settings.VerticalOffset = $script:sldVerticalOffset.Value; $global:Settings.Spacing = $script:sldSpacing.Value; $global:Settings.Orientation = Get-ComboText $script:cmbOrientation; $global:Settings.FontColorMode = Get-ComboText $script:cmbColor; $global:Settings.CustomFontColor = $script:txtCustomColor.Text; $global:Settings.ShowBorders = ($script:chkBorders.IsChecked -eq $true)
            
            # Save Startup Method cleanly
            $newStartup = Get-ComboText $script:cmbStartup
            if ($newStartup -ne $global:Settings.StartupMethod) {
                $global:Settings.StartupMethod = $newStartup
                Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WinQL" -ErrorAction SilentlyContinue
                $startupLink = Join-Path ([Environment]::GetFolderPath('Startup')) "WinQL.lnk"
                if (Test-Path $startupLink) { Remove-Item $startupLink -Force -ErrorAction SilentlyContinue }
                Unregister-ScheduledTask -TaskName "WinQL_Service" -Confirm:$false -ErrorAction SilentlyContinue
                
                if ($newStartup -eq "Task Manager") {
                    $WshShell = New-Object -ComObject WScript.Shell
                    $shortcutStart = $WshShell.CreateShortcut($startupLink)
                    $shortcutStart.TargetPath = "wscript.exe"
                    $shortcutStart.Arguments = "`"$appInstallDir\Invisible.vbs`""
                    $shortcutStart.WindowStyle = 0
                    $shortcutStart.Save()
                } elseif ($newStartup -eq "Registry") {
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WinQL" -Value "wscript.exe `"$appInstallDir\Invisible.vbs`""
                } elseif ($newStartup -eq "Service") {
                    try {
                        $action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$appInstallDir\Invisible.vbs`""
                        $trigger = New-ScheduledTaskTrigger -AtLogOn
                        Register-ScheduledTask -TaskName "WinQL_Service" -Action $action -Trigger $trigger -Force | Out-Null
                    } catch {}
                }
            }
            
            if ($null -ne $script:cmbMusicColor) { $global:Settings.MusicFontColorMode = Get-ComboText $script:cmbMusicColor }
            if ($null -ne $script:txtMusicCustomColor) { $global:Settings.MusicCustomColor = $script:txtMusicCustomColor.Text }
            try { $parsedSize = [int]$script:txtBtnSize.Text; if ($parsedSize -gt 5) { $global:Settings.ButtonSize = $parsedSize } } catch {}
            try { $parsedTitleLen = [int]$script:txtMaxTitle.Text; if ($parsedTitleLen -ge 5) { $global:Settings.MaxTitleLength = $parsedTitleLen } } catch {}
            try { $parsedArtistLen = [int]$script:txtMaxArtist.Text; if ($parsedArtistLen -ge 5) { $global:Settings.MaxArtistLength = $parsedArtistLen } } catch {}
            
            if ($null -ne $script:chkCompensateBorder) { $global:Settings.CompensateBorder = ($script:chkCompensateBorder.IsChecked -eq $true) }

            for ($i=0; $i -lt 10; $i++) {
                $tab = $script:setWindow.FindName("tabBtn_$i"); if ($i -lt $global:Settings.BtnCount) { $tab.Visibility = 'Visible' } else { $tab.Visibility = 'Collapsed' }
                $global:Settings.Buttons[$i].Char = $script:setWindow.FindName("txtChar_$i").Text
                $global:Settings.Buttons[$i].EnLeft = ($script:setWindow.FindName("chkLeft_$i").IsChecked -eq $true); $global:Settings.Buttons[$i].EnLeftDouble = ($script:setWindow.FindName("chkLeftDouble_$i").IsChecked -eq $true); $global:Settings.Buttons[$i].EnRight = ($script:setWindow.FindName("chkRight_$i").IsChecked -eq $true); $global:Settings.Buttons[$i].EnRightDouble = ($script:setWindow.FindName("chkRightDouble_$i").IsChecked -eq $true); $global:Settings.Buttons[$i].EnMid = ($script:setWindow.FindName("chkMid_$i").IsChecked -eq $true)
                if ($global:Settings.Buttons[$i].EnLeft) { $script:setWindow.FindName("pnlLeft_$i").Visibility='Visible' } else { $script:setWindow.FindName("pnlLeft_$i").Visibility='Collapsed' }; if ($global:Settings.Buttons[$i].EnLeftDouble) { $script:setWindow.FindName("pnlLeftDouble_$i").Visibility='Visible' } else { $script:setWindow.FindName("pnlLeftDouble_$i").Visibility='Collapsed' }; if ($global:Settings.Buttons[$i].EnRight) { $script:setWindow.FindName("pnlRight_$i").Visibility='Visible' } else { $script:setWindow.FindName("pnlRight_$i").Visibility='Collapsed' }; if ($global:Settings.Buttons[$i].EnRightDouble) { $script:setWindow.FindName("pnlRightDouble_$i").Visibility='Visible' } else { $script:setWindow.FindName("pnlRightDouble_$i").Visibility='Collapsed' }; if ($global:Settings.Buttons[$i].EnMid) { $script:setWindow.FindName("pnlMid_$i").Visibility='Visible' } else { $script:setWindow.FindName("pnlMid_$i").Visibility='Collapsed' }
                $hasAny = ($global:Settings.Buttons[$i].EnLeft -or $global:Settings.Buttons[$i].EnLeftDouble -or $global:Settings.Buttons[$i].EnRight -or $global:Settings.Buttons[$i].EnRightDouble -or $global:Settings.Buttons[$i].EnMid)
                if ($hasAny) { $script:setWindow.FindName("lblNoActions_$i").Visibility='Collapsed' } else { $script:setWindow.FindName("lblNoActions_$i").Visibility='Visible' }

                $lPaths = @(); $boxL = $script:setWindow.FindName("boxLeft_$i"); if ($null -ne $boxL -and $null -ne $boxL.Children) { foreach($g in $boxL.Children) { if ($g -is [System.Windows.Controls.Grid]) { foreach($c in $g.Children) { if ($c -is [System.Windows.Controls.TextBox]) { $lPaths += $c.Text } } } } }
                $ldPaths = @(); $boxLD = $script:setWindow.FindName("boxLeftDouble_$i"); if ($null -ne $boxLD -and $null -ne $boxLD.Children) { foreach($g in $boxLD.Children) { if ($g -is [System.Windows.Controls.Grid]) { foreach($c in $g.Children) { if ($c -is [System.Windows.Controls.TextBox]) { $ldPaths += $c.Text } } } } }
                $rPaths = @(); $boxR = $script:setWindow.FindName("boxRight_$i"); if ($null -ne $boxR -and $null -ne $boxR.Children) { foreach($g in $boxR.Children) { if ($g -is [System.Windows.Controls.Grid]) { foreach($c in $g.Children) { if ($c -is [System.Windows.Controls.TextBox]) { $rPaths += $c.Text } } } } }
                $rdPaths = @(); $boxRD = $script:setWindow.FindName("boxRightDouble_$i"); if ($null -ne $boxRD -and $null -ne $boxRD.Children) { foreach($g in $boxRD.Children) { if ($g -is [System.Windows.Controls.Grid]) { foreach($c in $g.Children) { if ($c -is [System.Windows.Controls.TextBox]) { $rdPaths += $c.Text } } } } }
                $mPaths = @(); $boxM = $script:setWindow.FindName("boxMid_$i"); if ($null -ne $boxM -and $null -ne $boxM.Children) { foreach($g in $boxM.Children) { if ($g -is [System.Windows.Controls.Grid]) { foreach($c in $g.Children) { if ($c -is [System.Windows.Controls.TextBox]) { $mPaths += $c.Text } } } } }
                
                $global:Settings.Buttons[$i].LeftActions = $lPaths; $global:Settings.Buttons[$i].LeftDoubleActions = $ldPaths; $global:Settings.Buttons[$i].RightActions = $rPaths; $global:Settings.Buttons[$i].RightDoubleActions = $rdPaths; $global:Settings.Buttons[$i].MidActions = $mPaths
            }
            Save-Settings $global:Settings
            Render-Layout
        } catch { }
    }

    function Show-SettingsWindow {
        if ($script:isSettingsOpen) { return }
        $script:isSettingsOpen = $true; $script:isLoading = $true; $global:Settings = Load-Settings
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
                        </StackPanel>
                    </TabItem>
                    <TabItem Header="Clicks">
                        <StackPanel Margin="10">
                            <TextBlock Text="Enable the following mouse actions:" FontWeight="Bold" Margin="0,0,0,10"/>
                            <CheckBox Name="chkLeft_$i" Content="Left Single Click" Margin="0,5"/><CheckBox Name="chkLeftDouble_$i" Content="Left Double Click" Margin="0,5"/><CheckBox Name="chkRight_$i" Content="Right Single Click" Margin="0,5"/><CheckBox Name="chkRightDouble_$i" Content="Right Double Click" Margin="0,5"/><CheckBox Name="chkMid_$i" Content="Middle Click" Margin="0,5"/>
                        </StackPanel>
                    </TabItem>
                    <TabItem Header="Actions">
                        <ScrollViewer VerticalScrollBarVisibility="Auto">
                            <StackPanel Margin="10">
                                <TextBlock Name="lblNoActions_$i" Text="Please enable clicks in the 'Clicks' tab." FontStyle="Italic" Foreground="Gray"/>
                                <StackPanel Name="pnlLeft_$i" Visibility="Collapsed" Margin="0,0,0,15"><TextBlock Text="Left Single Click Actions:" FontWeight="Bold" Margin="0,0,0,5"/><StackPanel Name="boxLeft_$i"/><Button Name="btnAddLeft_$i" Content="Add Action" Padding="10,4" HorizontalAlignment="Left" Cursor="Hand"/></StackPanel>
                                <StackPanel Name="pnlLeftDouble_$i" Visibility="Collapsed" Margin="0,0,0,15"><TextBlock Text="Left Double Click Actions:" FontWeight="Bold" Margin="0,0,0,5"/><StackPanel Name="boxLeftDouble_$i"/><Button Name="btnAddLeftDouble_$i" Content="Add Action" Padding="10,4" HorizontalAlignment="Left" Cursor="Hand"/></StackPanel>
                                <StackPanel Name="pnlRight_$i" Visibility="Collapsed" Margin="0,0,0,15"><TextBlock Text="Right Single Click Actions:" FontWeight="Bold" Margin="0,0,0,5"/><StackPanel Name="boxRight_$i"/><Button Name="btnAddRight_$i" Content="Add Action" Padding="10,4" HorizontalAlignment="Left" Cursor="Hand"/></StackPanel>
                                <StackPanel Name="pnlRightDouble_$i" Visibility="Collapsed" Margin="0,0,0,15"><TextBlock Text="Right Double Click Actions:" FontWeight="Bold" Margin="0,0,0,5"/><StackPanel Name="boxRightDouble_$i"/><Button Name="btnAddRightDouble_$i" Content="Add Action" Padding="10,4" HorizontalAlignment="Left" Cursor="Hand"/></StackPanel>
                                <StackPanel Name="pnlMid_$i" Visibility="Collapsed" Margin="0,0,0,15"><TextBlock Text="Middle Click Actions:" FontWeight="Bold" Margin="0,0,0,5"/><StackPanel Name="boxMid_$i"/><Button Name="btnAddMid_$i" Content="Add Action" Padding="10,4" HorizontalAlignment="Left" Cursor="Hand"/></StackPanel>
                            </StackPanel>
                        </ScrollViewer>
                    </TabItem>
                </TabControl>
            </TabItem>
"@
        }

        $setXAML = @"
        <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="WinQL Settings (v1.0.0)" Height="750" Width="700" WindowStartupLocation="CenterScreen" Topmost="True" ResizeMode="NoResize">
            <TabControl Margin="5">
                <TabItem Header="Appearance">
                    <StackPanel Margin="15">
                        <TextBlock Text="Global Button Font Settings:" FontWeight="Bold" Margin="0,0,0,5"/>
                        <Grid Margin="0,0,0,10"><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><Button Name="btnGlobalFont" Content="Choose Font..." Padding="10,2" Margin="0,0,10,0" Cursor="Hand"/><TextBlock Name="lblGlobalFont" Grid.Column="1" VerticalAlignment="Center" FontStyle="Italic"/></Grid>
                        <TextBlock Text="Global Font Color Mode:" FontWeight="Bold" Margin="0,0,0,5"/>
                        <Grid Margin="0,0,0,15"><Grid.ColumnDefinitions><ColumnDefinition Width="150"/><ColumnDefinition Width="*"/><ColumnDefinition Width="80"/></Grid.ColumnDefinitions><ComboBox Name="cmbColor" Grid.Column="0" Margin="0,0,10,0"><ComboBoxItem Content="Auto"/><ComboBoxItem Content="White"/><ComboBoxItem Content="Black"/><ComboBoxItem Content="Custom"/></ComboBox><TextBox Name="txtCustomColor" Grid.Column="1" Margin="0,0,10,0" VerticalContentAlignment="Center"/><Button Name="btnPickColor" Grid.Column="2" Content="Pick Color" Padding="5,2" Cursor="Hand"/></Grid>
                        <TextBlock Text="Shortcuts Orientation:" FontWeight="Bold" Margin="0,0,0,5"/>
                        <ComboBox Name="cmbOrientation" Margin="0,0,0,15" Width="150" HorizontalAlignment="Left"><ComboBoxItem Content="Horizontal"/><ComboBoxItem Content="Vertical"/></ComboBox>
                        <TextBlock Text="Distance Between Elements (Spacing):" FontWeight="Bold" Margin="0,0,0,5"/>
                        <Slider Name="sldSpacing" Minimum="0" Maximum="100" TickFrequency="2" IsSnapToTickEnabled="True" Margin="0,0,0,15"/>
                        <Grid Margin="0,0,0,15"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><StackPanel Grid.Column="0" Margin="0,0,10,0"><TextBlock Text="Button Hitbox Size (px):" FontWeight="Bold" Margin="0,0,0,5"/><TextBox Name="txtBtnSize" Width="60" HorizontalAlignment="Left" Padding="2"/></StackPanel><StackPanel Grid.Column="1"><CheckBox Name="chkBorders" Content="Show Temporary Borders" FontWeight="Bold" Margin="0,0,0,10"/></StackPanel></Grid>
                        <Border BorderBrush="LightGray" BorderThickness="0,1,0,0" Margin="0,5,0,15"/>
                        
                        <!-- CLEANED MEDIA PLAYER SETTINGS -->
                        <TextBlock Text="Media Player Aesthetics:" FontWeight="Bold" Margin="0,0,0,5"/>
                        <TextBlock Text="Controls Hint: 1x Left-Click = Play/Pause | 1x Right-Click = Hide Player&#10;Thumbnail: 2x Left = Focus App | Text: 2x Left = Prev Song / 2x Right = Next Song" FontStyle="Italic" Foreground="Gray" Margin="0,0,0,10"/>
                        <Grid Margin="0,0,0,10"><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><Button Name="btnMusicFont" Content="Choose Font..." Padding="10,2" Margin="0,0,10,0" Cursor="Hand"/><TextBlock Name="lblMusicFont" Grid.Column="1" VerticalAlignment="Center" FontStyle="Italic"/></Grid>
                        <Grid Margin="0,0,0,15"><Grid.ColumnDefinitions><ColumnDefinition Width="150"/><ColumnDefinition Width="*"/><ColumnDefinition Width="80"/></Grid.ColumnDefinitions><ComboBox Name="cmbMusicColor" Grid.Column="0" Margin="0,0,10,0"><ComboBoxItem Content="Auto"/><ComboBoxItem Content="White"/><ComboBoxItem Content="Black"/><ComboBoxItem Content="Custom"/><ComboBoxItem Content="Random"/></ComboBox><TextBox Name="txtMusicCustomColor" Grid.Column="1" Margin="0,0,10,0" VerticalContentAlignment="Center"/><Button Name="btnMusicPickColor" Grid.Column="2" Content="Pick Color" Padding="5,2" Cursor="Hand"/></Grid>
                        
                        <!-- NEW TEXT LIMITS -->
                        <Grid Margin="0,0,0,15">
                            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                            <StackPanel Grid.Column="0" Margin="0,0,10,0">
                                <TextBlock Text="Max Title Length (Chars):" FontWeight="Bold" Margin="0,0,0,5"/>
                                <TextBox Name="txtMaxTitle" Width="60" HorizontalAlignment="Left" Padding="2"/>
                            </StackPanel>
                            <StackPanel Grid.Column="1">
                                <TextBlock Text="Max Artist Length (Chars):" FontWeight="Bold" Margin="0,0,0,5"/>
                                <TextBox Name="txtMaxArtist" Width="60" HorizontalAlignment="Left" Padding="2"/>
                            </StackPanel>
                        </Grid>
                    </StackPanel>
                </TabItem>
                <TabItem Header="Button Actions"><Grid><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions><StackPanel Grid.Row="0" Margin="10,10,10,0"><TextBlock Text="Active Buttons (1-10):" FontWeight="Bold" Margin="0,0,0,5"/><Slider Name="sldCount" Minimum="1" Maximum="10" TickFrequency="1" IsSnapToTickEnabled="True" Margin="0,0,0,5"/></StackPanel><TabControl Grid.Row="1" TabStripPlacement="Left" Margin="5">$dynamicTabs</TabControl></Grid></TabItem>
                <TabItem Header="Advanced">
                    <StackPanel Margin="15">
                        <TextBlock Text="Launch WinQL automatically on Windows Startup:" FontWeight="Bold" Margin="0,0,0,5"/>
                        <ComboBox Name="cmbStartup" Margin="0,0,0,25" Width="150" HorizontalAlignment="Left">
                            <ComboBoxItem Content="None"/>
                            <ComboBoxItem Content="Task Manager"/>
                            <ComboBoxItem Content="Registry"/>
                            <ComboBoxItem Content="Service"/>
                        </ComboBox>
                        
                        <TextBlock Text="Taskbar Alignment &amp; Offsets" FontWeight="Bold" Margin="0,0,0,5"/>
                        <TextBlock Text="Widget Alignment:" FontWeight="Bold" Margin="0,0,0,5"/>
                        <ComboBox Name="cmbAlignment" Margin="0,0,0,15" Width="150" HorizontalAlignment="Left"><ComboBoxItem Name="cmbAlignLeft" Content="Left"/><ComboBoxItem Name="cmbAlignCenter" Content="Center"/><ComboBoxItem Name="cmbAlignRight" Content="Right"/></ComboBox>
                        <StackPanel Name="pnlLeftSpacing" Visibility="Collapsed"><TextBlock Text="Left Spacing (px):" Margin="0,0,0,5"/><Slider Name="sldLeftSpacing" Minimum="0" Maximum="2000" TickFrequency="10" IsSnapToTickEnabled="True" Margin="0,0,0,15"/></StackPanel>
                        <StackPanel Name="pnlRightSpacing" Visibility="Collapsed"><TextBlock Text="Right Spacing (px):" Margin="0,0,0,5"/><Slider Name="sldRightSpacing" Minimum="0" Maximum="2000" TickFrequency="10" IsSnapToTickEnabled="True" Margin="0,0,0,15"/></StackPanel>
                        
                        <TextBlock Text="Vertical Offset (Fine-tune centering, px):" Margin="0,0,0,5"/>
                        <Slider Name="sldVerticalOffset" Minimum="-20" Maximum="20" TickFrequency="1" IsSnapToTickEnabled="True" Margin="0,0,0,15"/>
                        <CheckBox Name="chkCompensateBorder" Content="Compensate for Win 11 Silver Line (1px Top Border)" FontWeight="Bold" Margin="0,0,0,15"/>
                        
                        <Border BorderBrush="LightGray" BorderThickness="0,1,0,0" Margin="0,5,0,15"/>
                        
                        <TextBlock Text="Backup &amp; Restore (Settings.json):" FontWeight="Bold" Margin="0,0,0,5"/>
                        <Grid Margin="0,0,0,10">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <Button Name="btnExport" Grid.Column="0" Content="Export" Padding="15,5" Margin="0,0,10,0" Cursor="Hand"/>
                            <Button Name="btnImport" Grid.Column="1" Content="Import" Padding="15,5" Margin="0,0,10,0" Cursor="Hand"/>
                            <Button Name="btnRefresh" Grid.Column="2" Content="Refresh" Padding="15,5" Cursor="Hand"/>
                        </Grid>
                        
                        <TextBlock Text="Note: Window saves automatically and applies instantly." FontStyle="Italic" Foreground="Gray" Margin="0,15,0,0"/>
                    </StackPanel>
                </TabItem>
                <TabItem Header="About">
                    <StackPanel Margin="15">
                        <TextBlock Text="WinQL v1.0.0" FontSize="24" FontWeight="Bold" Margin="0,0,0,5"/>
                        <TextBlock Text="By Detaroxz" FontStyle="Italic" Foreground="Gray" Margin="0,0,0,15"/>
                        <TextBlock Text="WinQL is a customizable, taskbar-integrated utility launcher and media tracking engine. It provides quick access to custom shortcuts, system commands, and adaptive media controls directly from your Windows taskbar." TextWrapping="Wrap" FontSize="14" Margin="0,0,0,20"/>
                        
                        <Border BorderBrush="LightGray" BorderThickness="0,1,0,0" Margin="0,0,0,20"/>
                        
                        <TextBlock Text="Feedback &amp; Support" FontWeight="Bold" FontSize="14" Margin="0,0,0,10"/>
                        <Button Name="btnReportBug" Content="Report a Bug" Padding="15,8" Margin="0,0,0,10" Cursor="Hand" HorizontalAlignment="Left" Width="280"/>
                        <Button Name="btnRequestFeature" Content="Request a Feature / Modification" Padding="15,8" Cursor="Hand" HorizontalAlignment="Left" Width="280"/>
                    </StackPanel>
                </TabItem>
            </TabControl>
        </Window>
"@
        $setStringReader = New-Object System.IO.StringReader($setXAML); $setXmlReader = [System.Xml.XmlReader]::Create($setStringReader); $script:setWindow = [System.Windows.Markup.XamlReader]::Load($setXmlReader)
        
        $script:sldCount = $script:setWindow.FindName("sldCount")
        $script:cmbAlignment = $script:setWindow.FindName("cmbAlignment"); $script:cmbAlignLeft = $script:setWindow.FindName("cmbAlignLeft"); $script:cmbAlignCenter = $script:setWindow.FindName("cmbAlignCenter")
        $script:pnlLeftSpacing = $script:setWindow.FindName("pnlLeftSpacing"); $script:sldLeftSpacing = $script:setWindow.FindName("sldLeftSpacing")
        $script:pnlRightSpacing = $script:setWindow.FindName("pnlRightSpacing"); $script:sldRightSpacing = $script:setWindow.FindName("sldRightSpacing")
        $script:sldVerticalOffset = $script:setWindow.FindName("sldVerticalOffset")
        $script:chkCompensateBorder = $script:setWindow.FindName("chkCompensateBorder")
        $script:cmbStartup = $script:setWindow.FindName("cmbStartup")
        $script:btnGlobalFont = $script:setWindow.FindName("btnGlobalFont"); $script:lblGlobalFont = $script:setWindow.FindName("lblGlobalFont")
        $script:sldSpacing = $script:setWindow.FindName("sldSpacing"); $script:cmbOrientation = $script:setWindow.FindName("cmbOrientation"); $script:cmbColor = $script:setWindow.FindName("cmbColor"); $script:txtCustomColor = $script:setWindow.FindName("txtCustomColor"); $script:btnPickColor = $script:setWindow.FindName("btnPickColor"); $script:txtBtnSize = $script:setWindow.FindName("txtBtnSize"); $script:chkBorders = $script:setWindow.FindName("chkBorders")
        
        $script:btnMusicFont = $script:setWindow.FindName("btnMusicFont"); $script:lblMusicFont = $script:setWindow.FindName("lblMusicFont"); $script:cmbMusicColor = $script:setWindow.FindName("cmbMusicColor"); $script:txtMusicCustomColor = $script:setWindow.FindName("txtMusicCustomColor"); $script:btnMusicPickColor = $script:setWindow.FindName("btnMusicPickColor")
        $script:txtMaxTitle = $script:setWindow.FindName("txtMaxTitle")
        $script:txtMaxArtist = $script:setWindow.FindName("txtMaxArtist")
        $script:btnExport = $script:setWindow.FindName("btnExport")
        $script:btnImport = $script:setWindow.FindName("btnImport")
        $script:btnRefresh = $script:setWindow.FindName("btnRefresh")
        $script:btnReportBug = $script:setWindow.FindName("btnReportBug")
        $script:btnRequestFeature = $script:setWindow.FindName("btnRequestFeature")

        $script:sldCount.Value = $global:Settings.BtnCount; $script:cmbAlignment.Text = $global:Settings.Alignment; $script:sldLeftSpacing.Value = $global:Settings.LeftSpacing; $script:sldRightSpacing.Value = $global:Settings.RightSpacing; $script:sldVerticalOffset.Value = $global:Settings.VerticalOffset
        $w = "Regular"; if ($global:Settings.GlobalBtnFontBold) { $w = "Bold" }; $script:lblGlobalFont.Text = "$($global:Settings.GlobalBtnFontFamily), $($global:Settings.GlobalBtnFontSize)pt, $w"
        $script:sldSpacing.Value = $global:Settings.Spacing; $script:cmbOrientation.Text = $global:Settings.Orientation; $script:cmbColor.Text = $global:Settings.FontColorMode; $script:txtCustomColor.Text = $global:Settings.CustomFontColor; $script:txtBtnSize.Text = $global:Settings.ButtonSize; $script:chkBorders.IsChecked = $global:Settings.ShowBorders
        $script:chkCompensateBorder.IsChecked = $global:Settings.CompensateBorder
        $script:cmbStartup.Text = $global:Settings.StartupMethod
        
        $script:lblMusicFont.Text = $global:Settings.MusicFontFamily; $script:cmbMusicColor.Text = $global:Settings.MusicFontColorMode; $script:txtMusicCustomColor.Text = $global:Settings.MusicCustomColor
        $script:txtMaxTitle.Text = $global:Settings.MaxTitleLength
        $script:txtMaxArtist.Text = $global:Settings.MaxArtistLength
        
        $script:txtCustomColor.IsEnabled = ($script:cmbColor.Text -eq "Custom"); $script:btnPickColor.IsEnabled = ($script:cmbColor.Text -eq "Custom"); $script:txtMusicCustomColor.IsEnabled = ($script:cmbMusicColor.Text -eq "Custom"); $script:btnMusicPickColor.IsEnabled = ($script:cmbMusicColor.Text -eq "Custom")

        for ($i=0; $i -lt 10; $i++) {
            $def = $global:Settings.Buttons[$i]; $tab = $script:setWindow.FindName("tabBtn_$i")
            if ($i -lt $global:Settings.BtnCount) { $tab.Visibility = 'Visible' } else { $tab.Visibility = 'Collapsed' }
            $script:setWindow.FindName("txtChar_$i").Text = $def.Char; $chkL = $script:setWindow.FindName("chkLeft_$i"); $chkL.IsChecked = $def.EnLeft; $chkLD = $script:setWindow.FindName("chkLeftDouble_$i"); $chkLD.IsChecked = $def.EnLeftDouble; $chkR = $script:setWindow.FindName("chkRight_$i"); $chkR.IsChecked = $def.EnRight; $chkRD = $script:setWindow.FindName("chkRightDouble_$i"); $chkRD.IsChecked = $def.EnRightDouble; $chkM = $script:setWindow.FindName("chkMid_$i"); $chkM.IsChecked = $def.EnMid
            $boxL = $script:setWindow.FindName("boxLeft_$i"); if ($def.LeftActions.Count -gt 0) { foreach($p in $def.LeftActions) { Add-ActionTextBox $boxL $p } }
            $boxLD = $script:setWindow.FindName("boxLeftDouble_$i"); if ($def.LeftDoubleActions.Count -gt 0) { foreach($p in $def.LeftDoubleActions) { Add-ActionTextBox $boxLD $p } }
            $boxR = $script:setWindow.FindName("boxRight_$i"); if ($def.RightActions.Count -gt 0) { foreach($p in $def.RightActions) { Add-ActionTextBox $boxR $p } }
            $boxRD = $script:setWindow.FindName("boxRightDouble_$i"); if ($def.RightDoubleActions.Count -gt 0) { foreach($p in $def.RightDoubleActions) { Add-ActionTextBox $boxRD $p } }
            $boxM = $script:setWindow.FindName("boxMid_$i"); if ($def.MidActions.Count -gt 0) { foreach($p in $def.MidActions) { Add-ActionTextBox $boxM $p } }
            $script:setWindow.FindName("btnAddLeft_$i").Tag = $boxL; $script:setWindow.FindName("btnAddLeft_$i").Add_Click({ param($sender, $e) Add-ActionTextBox $sender.Tag ""; & $script:updateAction })
            $script:setWindow.FindName("btnAddLeftDouble_$i").Tag = $boxLD; $script:setWindow.FindName("btnAddLeftDouble_$i").Add_Click({ param($sender, $e) Add-ActionTextBox $sender.Tag ""; & $script:updateAction })
            $script:setWindow.FindName("btnAddRight_$i").Tag = $boxR; $script:setWindow.FindName("btnAddRight_$i").Add_Click({ param($sender, $e) Add-ActionTextBox $sender.Tag ""; & $script:updateAction })
            $script:setWindow.FindName("btnAddRightDouble_$i").Tag = $boxRD; $script:setWindow.FindName("btnAddRightDouble_$i").Add_Click({ param($sender, $e) Add-ActionTextBox $sender.Tag ""; & $script:updateAction })
            $script:setWindow.FindName("btnAddMid_$i").Tag = $boxM; $script:setWindow.FindName("btnAddMid_$i").Add_Click({ param($sender, $e) Add-ActionTextBox $sender.Tag ""; & $script:updateAction })
            $script:setWindow.FindName("txtChar_$i").Add_TextChanged($script:updateAction)
            $chkL.Add_Click($script:updateAction); $chkLD.Add_Click($script:updateAction); $chkR.Add_Click($script:updateAction); $chkRD.Add_Click($script:updateAction); $chkM.Add_Click($script:updateAction)
        }

        $script:btnGlobalFont.Add_Click({
            $dlg = New-Object System.Windows.Forms.FontDialog
            try { $fStyle = [System.Drawing.FontStyle]::Regular; if ($global:Settings.GlobalBtnFontBold) { $fStyle = $fStyle -bor [System.Drawing.FontStyle]::Bold }; if ($global:Settings.GlobalBtnFontItalic) { $fStyle = $fStyle -bor [System.Drawing.FontStyle]::Italic }; $dlg.Font = New-Object System.Drawing.Font($global:Settings.GlobalBtnFontFamily, [float]$global:Settings.GlobalBtnFontSize, $fStyle) } catch {}
            if ($dlg.ShowDialog() -eq 'OK') { $global:Settings.GlobalBtnFontFamily = $dlg.Font.Name; $global:Settings.GlobalBtnFontSize = $dlg.Font.Size; $global:Settings.GlobalBtnFontBold = $dlg.Font.Bold; $global:Settings.GlobalBtnFontItalic = $dlg.Font.Italic; $w = "Regular"; if ($dlg.Font.Bold) { $w = "Bold" }; $script:lblGlobalFont.Text = "$($dlg.Font.Name), $($dlg.Font.Size)pt, $w"; & $script:updateAction }
        })
        $script:btnMusicFont.Add_Click({
            $dlg = New-Object System.Windows.Forms.FontDialog; try { $dlg.Font = New-Object System.Drawing.Font($global:Settings.MusicFontFamily, 12.0) } catch {}
            if ($dlg.ShowDialog() -eq 'OK') { $global:Settings.MusicFontFamily = $dlg.Font.Name; $script:lblMusicFont.Text = $dlg.Font.Name; & $script:updateAction }
        })

        $script:btnExport.Add_Click({
            $fd = New-Object System.Windows.Forms.SaveFileDialog
            $fd.Filter = "JSON Files (*.json)|*.json"
            $fd.FileName = "WinQL_Settings_Backup.json"
            if ($fd.ShowDialog() -eq 'OK') {
                try {
                    Copy-Item -Path $settingsFile -Destination $fd.FileName -Force
                    [System.Windows.Forms.MessageBox]::Show("Settings successfully exported to your chosen location.", "Export Complete", 0, 64)
                } catch { 
                    [System.Windows.Forms.MessageBox]::Show("Failed to export settings.", "Error", 0, 16) 
                }
            }
        })

        $script:btnImport.Add_Click({
            $fd = New-Object System.Windows.Forms.OpenFileDialog
            $fd.Filter = "JSON Files (*.json)|*.json"
            if ($fd.ShowDialog() -eq 'OK') {
                try {
                    $testJson = Get-Content $fd.FileName -Raw | ConvertFrom-Json -ErrorAction Stop
                    if ($null -ne $testJson -and $null -ne $testJson.Buttons -and $null -ne $testJson.BtnCount) {
                        Copy-Item -Path $fd.FileName -Destination $settingsFile -Force
                        $global:Settings = Load-Settings
                        Render-Layout
                        [System.Windows.Forms.MessageBox]::Show("Settings imported successfully! The settings window will now close to refresh the UI cleanly.", "Import Complete", 0, 64)
                        $script:setWindow.Close()
                    } else {
                        [System.Windows.Forms.MessageBox]::Show("The selected file is not a valid WinQL settings format.", "Validation Failed", 0, 16)
                    }
                } catch { 
                    [System.Windows.Forms.MessageBox]::Show("Failed to read the JSON file. It may be corrupted.", "Import Error", 0, 16) 
                }
            }
        })

        $script:btnRefresh.Add_Click({
            $global:Settings = Load-Settings
            Render-Layout
            [System.Windows.Forms.MessageBox]::Show("App refreshed with the current settings file. The window will now close.", "Refresh Complete", 0, 64)
            $script:setWindow.Close()
        })
        
        $script:btnReportBug.Add_Click({ Start-Process "mailto:architm193@gmail.com?subject=WinQL%20Bug%20Report" -ErrorAction SilentlyContinue })
        $script:btnRequestFeature.Add_Click({ Start-Process "mailto:architm193@gmail.com?subject=WinQL%20Feature%20Request" -ErrorAction SilentlyContinue })

        function Update-Alignment-UI {
            $align = Get-ComboText $script:cmbAlignment
            if ($align -eq "Left") { $script:pnlLeftSpacing.Visibility = 'Visible'; $script:pnlRightSpacing.Visibility = 'Collapsed' } elseif ($align -eq "Right") { $script:pnlLeftSpacing.Visibility = 'Collapsed'; $script:pnlRightSpacing.Visibility = 'Visible' } else { $script:pnlLeftSpacing.Visibility = 'Collapsed'; $script:pnlRightSpacing.Visibility = 'Collapsed' }
            $edge = [Native]::GetTaskbarEdge()
            $taskbarAl = 0; try { $taskbarAl = Get-ItemPropertyValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -ErrorAction SilentlyContinue } catch {}
            if ($taskbarAl -eq $null) { $taskbarAl = 0 }
            $script:cmbAlignLeft.IsEnabled = ($edge -ne 0); if (-not $script:cmbAlignLeft.IsEnabled) { $script:cmbAlignLeft.ToolTip = "Unavailable when taskbar is vertically on the left." } else { $script:cmbAlignLeft.ToolTip = $null }
            $script:cmbAlignCenter.IsEnabled = (-not (($edge -eq 1 -or $edge -eq 3) -and $taskbarAl -eq 1)); if (-not $script:cmbAlignCenter.IsEnabled) { $script:cmbAlignCenter.ToolTip = "Unavailable when Windows 11 taskbar icons are Centered." } else { $script:cmbAlignCenter.ToolTip = $null }
        }

        $script:cmbAlignment.Add_SelectionChanged({ Update-Alignment-UI; $script:setWindow.Dispatcher.BeginInvoke([Action]{ & $script:updateAction }, [System.Windows.Threading.DispatcherPriority]::Background) | Out-Null })
        $script:cmbOrientation.Add_SelectionChanged($script:updateAction)
        $script:cmbMusicColor.Add_SelectionChanged({ $mode = Get-ComboText $script:cmbMusicColor; $isCustom = ($mode -eq "Custom"); $script:txtMusicCustomColor.IsEnabled = $isCustom; $script:btnMusicPickColor.IsEnabled = $isCustom; $script:setWindow.Dispatcher.BeginInvoke([Action]{ & $script:updateAction }, [System.Windows.Threading.DispatcherPriority]::Background) | Out-Null })
        $script:cmbColor.Add_SelectionChanged({ $mode = Get-ComboText $script:cmbColor; $isCustom = ($mode -eq "Custom"); $script:txtCustomColor.IsEnabled = $isCustom; $script:btnPickColor.IsEnabled = $isCustom; $script:setWindow.Dispatcher.BeginInvoke([Action]{ & $script:updateAction }, [System.Windows.Threading.DispatcherPriority]::Background) | Out-Null })
        $script:cmbStartup.Add_SelectionChanged({ $script:setWindow.Dispatcher.BeginInvoke([Action]{ & $script:updateAction }, [System.Windows.Threading.DispatcherPriority]::Background) | Out-Null })
        $script:btnPickColor.Add_Click({ $dlg = New-Object System.Windows.Forms.ColorDialog; $dlg.FullOpen = $true; try { $dlg.Color = [System.Drawing.ColorTranslator]::FromHtml($script:txtCustomColor.Text) } catch {}; if ($dlg.ShowDialog() -eq 'OK') { $script:txtCustomColor.Text = "#$($dlg.Color.R.ToString('X2'))$($dlg.Color.G.ToString('X2'))$($dlg.Color.B.ToString('X2'))"; & $script:updateAction }; $dlg.Dispose() })
        $script:btnMusicPickColor.Add_Click({ $dlg = New-Object System.Windows.Forms.ColorDialog; $dlg.FullOpen = $true; try { $dlg.Color = [System.Drawing.ColorTranslator]::FromHtml($script:txtMusicCustomColor.Text) } catch {}; if ($dlg.ShowDialog() -eq 'OK') { $script:txtMusicCustomColor.Text = "#$($dlg.Color.R.ToString('X2'))$($dlg.Color.G.ToString('X2'))$($dlg.Color.B.ToString('X2'))"; & $script:updateAction }; $dlg.Dispose() })
        $script:sldCount.Add_ValueChanged($script:updateAction); $script:sldLeftSpacing.Add_ValueChanged($script:updateAction); $script:sldRightSpacing.Add_ValueChanged($script:updateAction); $script:sldVerticalOffset.Add_ValueChanged($script:updateAction); $script:sldSpacing.Add_ValueChanged($script:updateAction); $script:txtCustomColor.Add_TextChanged($script:updateAction); $script:txtMusicCustomColor.Add_TextChanged($script:updateAction); $script:txtBtnSize.Add_TextChanged($script:updateAction); $script:chkBorders.Add_Click($script:updateAction)
        $script:txtMaxTitle.Add_TextChanged($script:updateAction); $script:txtMaxArtist.Add_TextChanged($script:updateAction); $script:chkCompensateBorder.Add_Click($script:updateAction)
        $script:setWindow.Add_Closed({ $script:isSettingsOpen = $false })
        
        $script:isLoading = $false; Update-Alignment-UI; & $script:updateAction; $script:setWindow.ShowDialog() | Out-Null
    }

    # --- MAIN ENGINE ---
    $global:keepRunning = $true
    
    $global:sysTray = New-Object System.Windows.Forms.NotifyIcon
    try { $global:sysTray.Icon = New-Object System.Drawing.Icon("$appInstallDir\icon.ico") } catch { $global:sysTray.Icon = [System.Drawing.SystemIcons]::Application }
    $global:sysTray.Text = "WinQL v1.0.0"
    $global:sysTray.Visible = $true
    
    $contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
    $itemSettings = $contextMenu.Items.Add("Settings"); $itemSettings.add_Click({ Show-SettingsWindow })
    $itemExit = $contextMenu.Items.Add("Exit"); $itemExit.add_Click({ 
        $global:keepRunning = $false; $global:sysTray.Visible = $false; $global:sysTray.Dispose()
        if ($null -ne $script:window) { $script:window.Close() }
        if ($null -ne $script:dispatcher) { $script:dispatcher.InvokeShutdown() }
    })
    $global:sysTray.ContextMenuStrip = $contextMenu

    $script:UserHidden = $false
    $script:HasEverPlayed = $false
    $script:wasPlaying = $false
    $script:cachedTitle = ""
    $script:cachedArtist = ""
    $script:cachedSource = ""
    $script:renderedTrackId = ""
    $script:usingFallbackMedia = $false
    $script:graceCounter = 0

    while ($global:keepRunning) {
        $hTaskbar = [Native]::FindWindow("Shell_TrayWnd", $null)
        if ($hTaskbar -eq [IntPtr]::Zero) { Start-Sleep -Seconds 2; continue }

        $stringReader = New-Object System.IO.StringReader($uiXAML)
        $script:window = [System.Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create($stringReader))
        $stringReader.Dispose()

        $script:MainGrid = $script:window.FindName("MainGrid"); $script:LayoutStack = $script:window.FindName("LayoutStack"); $script:ButtonPanel = $script:window.FindName("ButtonPanel"); $script:MediaToggleBtn = $script:window.FindName("MediaToggleBtn"); $script:MediaToggleText = $script:window.FindName("MediaToggleText"); $script:MusicContainer = $script:window.FindName("MusicContainer"); $script:SongInfoPanel = $script:window.FindName("SongInfoPanel"); $script:SongTitle = $script:window.FindName("SongTitle"); $script:SongArtist = $script:window.FindName("SongArtist"); $script:ThumbnailWrapper = $script:window.FindName("ThumbnailWrapper"); $script:SongThumbnail = $script:window.FindName("SongThumbnail"); $script:ThumbnailFallbackE = $script:window.FindName("ThumbnailFallbackE"); $script:PauseOverlay = $script:window.FindName("PauseOverlay")

        # MANUAL OVERRIDE (Clicking the hidden pin)
        $script:MediaToggleBtn.Add_PreviewMouseLeftButtonDown({
            param($sender, $e)
            $script:UserHidden = $false
            if ($null -ne $script:tickLogic) { & $script:tickLogic }
            $e.Handled = $true
        })

        # ADVANCED MEDIA CLICK HANDLER LOGIC
        $mediaClickState = @{ Timer = New-Object System.Windows.Threading.DispatcherTimer; ClickCount = 0; BtnType = ""; Target = "" }
        $mediaClickState.Timer.Interval = [TimeSpan]::FromMilliseconds(300)
        $mediaClickState.Timer.Add_Tick({
            $state = $this.Tag; $state.Timer.Stop(); $btnType = $state.BtnType; $count = $state.ClickCount; $target = $state.Target; $state.ClickCount = 0
            
            # Global Middle Click Override - Cycle active OS media session
            if ($btnType -eq 'Middle') {
                if ($count -ge 1) { Execute-Action "<media:cycle>" }
                return
            }

            if ($target -eq 'Thumbnail') {
                if ($btnType -eq 'Left') {
                    if ($count -eq 1) { Execute-Action "<media:play>" }
                    elseif ($count -ge 2) {
                        # Focus App Logic - Optimized App Detection
                        try {
                            $validProcs = [System.Diagnostics.Process]::GetProcesses()
                            $p = $null
                            
                            # 1. Try to find exact window title first (Best for browsers & active media)
                            if (-not [string]::IsNullOrWhiteSpace($script:cachedTitle)) {
                                $safeTitle = [regex]::Escape($script:cachedTitle)
                                foreach ($proc in $validProcs) {
                                    if ($proc.MainWindowHandle -ne 0 -and $proc.MainWindowTitle -match $safeTitle) {
                                        $p = $proc; break
                                    }
                                }
                            }
                            
                            # 2. Fallback to app ID guessing if title search fails
                            if (-not $p -and -not [string]::IsNullOrWhiteSpace($script:cachedSource)) {
                                $appId = $script:cachedSource.ToLower()
                                $searchTerm = $appId -replace '\.exe$','' -replace '!.*$',''
                                if ($searchTerm -match '\.') { $searchTerm = $searchTerm.Split('.')[-1] }
                                
                                $matchStr = ""
                                if ($appId -match "spotify") { $matchStr = "spotify" }
                                elseif ($appId -match "chrome|youtube") { $matchStr = "chrome" }
                                elseif ($appId -match "edge|msedge") { $matchStr = "msedge" }
                                elseif ($appId -match "vlc") { $matchStr = "vlc" }
                                elseif ($appId -match "zen") { $matchStr = "zen" }
                                elseif ($appId -match "firefox") { $matchStr = "firefox" }
                                elseif ($appId -match "brave") { $matchStr = "brave" }
                                elseif ($appId -match "opera") { $matchStr = "opera" }
                                else { $matchStr = $searchTerm }
                                
                                foreach ($proc in $validProcs) {
                                    if ($proc.MainWindowHandle -ne 0 -and $proc.ProcessName.ToLower() -match $matchStr) {
                                        $p = $proc; break
                                    }
                                }
                            }
                            
                            if ($p -and $p.MainWindowHandle -ne [IntPtr]::Zero) { 
                                [Native]::keybd_event(0x12, 0, 0, 0) # Alt down
                                [Native]::keybd_event(0x12, 0, 2, 0) # Alt up
                                [Native]::ShowWindow($p.MainWindowHandle, 9) | Out-Null
                                [Native]::SetForegroundWindow($p.MainWindowHandle) | Out-Null 
                            }

                            foreach ($proc in $validProcs) { $proc.Dispose() }
                        } catch { }
                    }
                } elseif ($btnType -eq 'Right') {
                    # Hide Player
                    $script:UserHidden = $true
                    if ($null -ne $script:tickLogic) { & $script:tickLogic }
                }
            } elseif ($target -eq 'Text') {
                if ($btnType -eq 'Left') {
                    if ($count -eq 1) { Execute-Action "<media:play>" }
                    elseif ($count -ge 2) { Execute-Action "<media:prev>" }
                } elseif ($btnType -eq 'Right') {
                    if ($count -eq 1) {
                        # Hide Player
                        $script:UserHidden = $true
                        if ($null -ne $script:tickLogic) { & $script:tickLogic }
                    } elseif ($count -ge 2) {
                        Execute-Action "<media:next>"
                    }
                }
            }
        })
        $mediaClickState.Timer.Tag = $mediaClickState

        $script:SongInfoPanel.Add_PreviewMouseDown({
            param($sender, $e)
            if ($e.Handled) { return }
            
            $state = $mediaClickState
            $btnTypeStr = $e.ChangedButton.ToString()
            
            # Determine click region based on mouse coordinates relative to the panel
            $pos = $e.GetPosition($script:SongInfoPanel)
            $thumbWidth = $script:ThumbnailWrapper.ActualWidth
            if ($pos.X -le ($thumbWidth + 6)) {
                $targetRegion = 'Thumbnail'
            } else {
                $targetRegion = 'Text'
            }

            if ($state.BtnType -ne $btnTypeStr -and $state.ClickCount -gt 0) { $state.ClickCount = 0 }
            $state.BtnType = $btnTypeStr
            $state.Target = $targetRegion
            $state.ClickCount++
            $state.Timer.Stop()
            $state.Timer.Start()
            
            $e.Handled = $true
        })

        $script:window.Add_Loaded({
            $script:hwnd = (New-Object System.Windows.Interop.WindowInteropHelper($script:window)).Handle
            $style = [Native]::GetWindowLong($script:hwnd, -16)
            $style = $style -band -bnot 0x80000000; $style = $style -bor 0x40000000; $style = $style -bor 0x04000000
            [Native]::SetWindowLong($script:hwnd, -16, $style) | Out-Null
            $exStyle = [Native]::GetWindowLong($script:hwnd, -20)
            $exStyle = $exStyle -bor 0x00000080; $exStyle = $exStyle -bor 0x08000000
            [Native]::SetWindowLong($script:hwnd, -20, $exStyle) | Out-Null
            [Native]::SetParent($script:hwnd, $hTaskbar) | Out-Null
            $script:hookDelegate = [System.Windows.Interop.HwndSourceHook]{
                param([IntPtr]$hwnd, [int]$msg, [IntPtr]$wParam, [IntPtr]$lParam, [ref]$handled)
                if ($msg -eq [Native]::WM_TASKBARCREATED) {
                    if ($null -ne $script:window) { $script:window.Close() }
                    if ($null -ne $script:dispatcher) { $script:dispatcher.InvokeShutdown() }
                }
                return [IntPtr]::Zero
            }
            $source = [System.Windows.Interop.HwndSource]::FromHwnd($script:hwnd); $source.AddHook($script:hookDelegate)
            $script:lastThemeColor = Get-ThemeColor; Render-Layout
        })

        # Helper to avoid massive CPU spikes from Pipeline Get-Process
        $getWindowTitle = {
            param($procName, $titleMatch)
            $title = $null
            try {
                $procs = [System.Diagnostics.Process]::GetProcessesByName($procName)
                foreach ($p in $procs) {
                    $t = $p.MainWindowTitle
                    if (-not [string]::IsNullOrWhiteSpace($t)) {
                        if ([string]::IsNullOrEmpty($titleMatch) -or $t -match $titleMatch) {
                            $title = $t
                            break
                        }
                    }
                }
                foreach ($p in $procs) { $p.Dispose() }
            } catch {}
            return $title
        }

        # STATE MACHINE POLLER
        $script:tickCount = 0
        $script:tickLogic = {
            try {
                $hasMedia = $false; $isPlaying = $false; $title = ""; $artist = ""; $source = ""; $thumbBytes = $null
                $currentUsingFallback = $false
                
                $checkAppAlive = {
                    param($appSource)
                    if ([string]::IsNullOrWhiteSpace($appSource)) { return $true }
                    $appId = $appSource.ToLower()
                    
                    $namesToCheck = @()
                    if ($appId -match "spotify") { $namesToCheck += "spotify" }
                    elseif ($appId -match "vlc") { $namesToCheck += "vlc" }
                    elseif ($appId -match "youtube|chrome|edge|msedge|firefox|brave|zen|opera") {
                        $namesToCheck += @("chrome", "msedge", "firefox", "brave", "zen", "opera")
                    } else {
                        $searchTerm = $appId -replace '\.exe$','' -replace '!.*$',''
                        if ($searchTerm -match '\.') { $searchTerm = $searchTerm.Split('.')[-1] }
                        $namesToCheck += $searchTerm
                    }

                    foreach ($n in $namesToCheck) {
                        try {
                            $procs = [System.Diagnostics.Process]::GetProcessesByName($n)
                            $count = $procs.Length
                            foreach ($p in $procs) { $p.Dispose() }
                            if ($count -gt 0) { return $true }
                        } catch {}
                    }
                    return $false
                }

                # 1. Fetch Audio from SMTC
                if ($global:MediaAPIEnabled) {
                    try {
                        $state = [MediaTracker]::GetState()
                        if ($state[0] -eq $true -and -not [string]::IsNullOrWhiteSpace($state[1])) {
                            $hasMedia = $true; $title = $state[1]; $artist = $state[2]; $source = $state[3]; $isPlaying = $state[4]; $thumbBytes = $state[5]
                        }
                    } catch {}
                }
                
                # Kill Ghost SMTC Sessions
                if ($hasMedia -and -not $isPlaying) {
                    if ($script:tickCount % 3 -eq 0) {
                        if (-not (& $checkAppAlive $source)) {
                            $hasMedia = $false
                        }
                    }
                }
                
                # 2. Fallback Audio Check (Optimized Loop)
                if (-not $hasMedia) {
                    if ($script:tickCount % 2 -eq 0) {
                        
                        $sTitle = & $getWindowTitle "Spotify" "^(?!.*Spotify( Premium)?( Free)?$).*"
                        if ($sTitle) {
                            $hasMedia = $true; $currentUsingFallback = $true
                            if ($sTitle -match "^(.*?) - (.*)$") { 
                                $artist = $matches[1].Trim()
                                $title = $matches[2].Trim() 
                            } else { 
                                $title = $sTitle
                                $artist = "" 
                            }
                            $source = "Spotify"; $isPlaying = $true
                        }

                        if (-not $hasMedia) {
                            $vTitle = & $getWindowTitle "vlc" " - VLC media player$"
                            if ($vTitle) {
                                $hasMedia = $true; $currentUsingFallback = $true
                                $title = $vTitle -replace " - VLC media player$",""; $artist = ""; $source = "VLC"; $isPlaying = $true
                            }
                        }

                        if (-not $hasMedia) {
                            $bTitle = $null
                            foreach ($b in @("chrome", "msedge", "firefox", "zen", "brave", "opera")) {
                                $bTitle = & $getWindowTitle $b " - YouTube"
                                if ($bTitle) { break }
                            }
                            
                            if ($bTitle) { 
                                $currentUsingFallback = $true
                                
                                # 1. Clean the title of notifications and browser suffixes
                                $cleanTitle = $bTitle -replace "^\(\d+\+?\)\s*", ""
                                $rawTitle = $cleanTitle -replace " - YouTube.*","" -replace " - Zen.*","" -replace " - Google Chrome.*","" -replace " - Brave.*","" -replace " - Opera.*",""
                                
                                # 2. Check if we already have high-quality data for this video in cache
                                $isSameVideo = $false
                                if (-not [string]::IsNullOrWhiteSpace($script:cachedTitle)) {
                                    $compareLen = [math]::Min(15, $script:cachedTitle.Length)
                                    if ($rawTitle.StartsWith($script:cachedTitle.Substring(0, $compareLen))) {
                                        $isSameVideo = $true
                                    }
                                }

                                $hasMedia = $true
                                $source = "YouTube"

                                if ($isSameVideo) {
                                    $title = $script:cachedTitle
                                    $artist = $script:cachedArtist
                                    
                                    if (-not $script:usingFallbackMedia) {
                                        $isPlaying = $false
                                    } else {
                                        $isPlaying = $script:wasPlaying
                                    }
                                } else {
                                    $title = $rawTitle
                                    $artist = ""
                                    $isPlaying = $true 
                                }
                            }
                        }
                    }
                }

                if ($hasMedia -and -not [string]::IsNullOrWhiteSpace($title)) {
                    $script:graceCounter = 0
                    $script:HasEverPlayed = $true
                    $script:cachedTitle = $title
                    $script:cachedArtist = $artist
                    $script:cachedSource = $source
                    $script:usingFallbackMedia = $currentUsingFallback
                } else {
                    $script:graceCounter++
                    if ($script:graceCounter -ge 5) {
                        $isPlaying = $false
                        $script:HasEverPlayed = $false
                        $title = ""
                        $artist = ""
                        $source = ""
                        $script:cachedSource = ""
                    } else {
                        $hasMedia = $true
                        $title = $script:cachedTitle
                        $artist = $script:cachedArtist
                        $source = $script:cachedSource
                        $isPlaying = $script:wasPlaying
                    }
                }

                # 4. Final UI State Rendering
                if ($script:HasEverPlayed) {
                    if ($isPlaying -and -not $script:wasPlaying) {
                        $script:UserHidden = $false
                    }
                    $script:wasPlaying = $isPlaying

                    if ($script:UserHidden) {
                        if ($script:MusicContainer.Visibility -ne 'Collapsed') { $script:MusicContainer.Visibility = 'Collapsed' }
                        if ($script:MediaToggleBtn.Visibility -ne 'Visible') { $script:MediaToggleBtn.Visibility = 'Visible' }
                        if ($script:ButtonPanel.Visibility -ne 'Visible') { $script:ButtonPanel.Visibility = 'Visible' }
                    } else {
                        if ($script:MusicContainer.Visibility -ne 'Visible') { $script:MusicContainer.Visibility = 'Visible' }
                        if ($script:MediaToggleBtn.Visibility -ne 'Collapsed') { $script:MediaToggleBtn.Visibility = 'Collapsed' }
                        if ($script:ButtonPanel.Visibility -ne 'Collapsed') { $script:ButtonPanel.Visibility = 'Collapsed' }
                        
                        if (-not $isPlaying) {
                            if ($script:PauseOverlay.Visibility -ne 'Visible') { $script:PauseOverlay.Visibility = 'Visible' }
                        } else {
                            if ($script:PauseOverlay.Visibility -ne 'Collapsed') { $script:PauseOverlay.Visibility = 'Collapsed' }
                        }
                        
                        $dispTitle = $title
                        if (-not [string]::IsNullOrWhiteSpace($dispTitle) -and $dispTitle.Length -gt $global:Settings.MaxTitleLength) { 
                            $dispTitle = $dispTitle.Substring(0, $global:Settings.MaxTitleLength).TrimEnd() + "..." 
                        }
                        
                        $dispArtist = $artist
                        if (-not [string]::IsNullOrWhiteSpace($dispArtist) -and $dispArtist.Length -gt $global:Settings.MaxArtistLength) { 
                            $dispArtist = $dispArtist.Substring(0, $global:Settings.MaxArtistLength).TrimEnd() + "..." 
                        }

                        if ($script:SongTitle.Text -ne $dispTitle) { $script:SongTitle.Text = $dispTitle }
                        if ($script:SongArtist.Text -ne $dispArtist) { $script:SongArtist.Text = $dispArtist }
                        
                        $artistVis = if ([string]::IsNullOrWhiteSpace($dispArtist)) { 'Collapsed' } else { 'Visible' }
                        if ($script:SongArtist.Visibility -ne $artistVis) { $script:SongArtist.Visibility = $artistVis }
                        
                        $tooltipText = $title
                        if (-not [string]::IsNullOrWhiteSpace($artist)) { $tooltipText += "`n$artist" }
                        $tooltipText += "`n[$source]"
                        $script:MusicContainer.ToolTip = $tooltipText

                        # --- FIX: POWERSHELL THUMBNAIL SIGNATURE HASH ---
                        $thumbLen = if ($null -ne $thumbBytes) { $thumbBytes.Length } else { 0 }
                        $currentSignature = "$title|$artist|$thumbLen"

                        if ($currentSignature -ne $script:renderedTrackId) {
                            $script:renderedTrackId = $currentSignature
                            
                            $fallbackBytes = $null
                            $showFallbackLetter = $false
                            
                            if ($null -eq $thumbBytes -or $thumbLen -eq 0) {
                                try {
                                    $procSearch = $source.ToLower() -replace '\.exe$','' -replace '!.*$',''; if ($procSearch -match '\.') { $procSearch = $procSearch.Split('.')[-1] }
                                    if ($procSearch -match 'spotify') { $procSearch = 'Spotify' }
                                    
                                    $p = Get-Process -Name $procSearch -ErrorAction SilentlyContinue | Select-Object -First 1
                                    if (-not $p) { $p = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -match $title } | Select-Object -First 1 }
                                    
                                    if ($p -and $p.MainModule.FileName) {
                                        $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($p.MainModule.FileName)
                                        $bmpIcon = $icon.ToBitmap()
                                        $msIcon = New-Object System.IO.MemoryStream
                                        $bmpIcon.Save($msIcon, [System.Drawing.Imaging.ImageFormat]::Png)
                                        $fallbackBytes = $msIcon.ToArray()
                                        $msIcon.Dispose(); $bmpIcon.Dispose(); $icon.Dispose()
                                    } else {
                                        $showFallbackLetter = $true
                                    }
                                } catch {
                                    $showFallbackLetter = $true
                                }
                            }

                            if ($script:ThumbnailWrapper.Visibility -ne 'Visible') { $script:ThumbnailWrapper.Visibility = 'Visible' }
                            $targetWidth = 40 
                            
                            if (($null -ne $thumbBytes -and $thumbBytes.Length -gt 0) -or ($null -ne $fallbackBytes -and $fallbackBytes.Length -gt 0)) {
                                $bytesToLoad = if ($null -ne $thumbBytes -and $thumbBytes.Length -gt 0) { $thumbBytes } else { $fallbackBytes }
                                try {
                                    $ms = New-Object System.IO.MemoryStream($bytesToLoad, 0, $bytesToLoad.Length)
                                    $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
                                    $bmp.BeginInit()
                                    $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                                    $bmp.StreamSource = $ms
                                    $bmp.EndInit()
                                    $bmp.Freeze()

                                    if (($bmp.PixelWidth / $bmp.PixelHeight) -gt 1.3) {
                                        $targetWidth = 71
                                    }
                                    
                                    $maskBorder = New-Object System.Windows.Controls.Border
                                    $maskBorder.Background = [System.Windows.Media.Brushes]::Black
                                    $maskBorder.CornerRadius = New-Object System.Windows.CornerRadius(4)
                                    $maskBorder.Width = $targetWidth
                                    $maskBorder.Height = 40
                                    $vb = New-Object System.Windows.Media.VisualBrush
                                    $vb.Visual = $maskBorder
                                    
                                    $script:SongThumbnail.OpacityMask = $vb
                                    $script:SongThumbnail.Source = $bmp
                                    $script:SongThumbnail.Visibility = 'Visible'
                                    $script:ThumbnailFallbackE.Visibility = 'Collapsed'
                                    $ms.Dispose()
                                } catch { 
                                    $script:SongThumbnail.Visibility = 'Collapsed'
                                    $script:ThumbnailFallbackE.Visibility = 'Visible'
                                }
                            } else {
                                $script:SongThumbnail.Visibility = 'Collapsed'
                                $script:ThumbnailFallbackE.Visibility = 'Visible'
                            }

                            if ($script:ThumbnailWrapper.Width -ne $targetWidth) { $script:ThumbnailWrapper.Width = $targetWidth }

                            if ($showFallbackLetter -or $script:ThumbnailFallbackE.Visibility -eq 'Visible') {
                                $script:ThumbnailFallbackE.Text = if (-not [string]::IsNullOrWhiteSpace($source)) { $source.Substring(0,1).ToUpper() } else { "M" }
                            }
                        }
                    }
                } else {
                    if ($script:MusicContainer.Visibility -ne 'Collapsed') { $script:MusicContainer.Visibility = 'Collapsed' }
                    if ($script:MediaToggleBtn.Visibility -ne 'Collapsed') { $script:MediaToggleBtn.Visibility = 'Collapsed' }
                    if ($script:ButtonPanel.Visibility -ne 'Visible') { $script:ButtonPanel.Visibility = 'Visible' }
                }
                
                # Theme Colors Sync
                $brushConv = New-Object System.Windows.Media.BrushConverter
                if ($global:Settings.MusicFontColorMode -eq "Random") { $rc = "#$((Get-Random -Min 100 -Max 255).ToString('X2'))$((Get-Random -Min 100 -Max 255).ToString('X2'))$((Get-Random -Min 100 -Max 255).ToString('X2'))"; $brush = $brushConv.ConvertFromString($rc) } 
                elseif ($global:Settings.MusicFontColorMode -eq "White") { $brush = $brushConv.ConvertFromString("#FFFFFF") } 
                elseif ($global:Settings.MusicFontColorMode -eq "Black") { $brush = $brushConv.ConvertFromString("#000000") } 
                elseif ($global:Settings.MusicFontColorMode -eq "Custom") { try { $brush = $brushConv.ConvertFromString($global:Settings.MusicCustomColor) } catch { $brush = [System.Windows.Media.Brushes]::White } } 
                else { try { $brush = $brushConv.ConvertFromString((Get-ThemeColor)) } catch { $brush = [System.Windows.Media.Brushes]::White } }
                
                $script:SongTitle.Foreground = $brush; $script:SongArtist.Foreground = $brush; $script:MediaToggleText.Foreground = $brush
                $script:ThumbnailFallbackE.Foreground = $brush

                Update-Window-Position
            } catch { $_ | Out-File "$env:APPDATA\Detaroxz\WinQL\tick_error.log" -Append }
        }

        $updateTimer = New-Object System.Windows.Threading.DispatcherTimer
        $updateTimer.Interval = [TimeSpan]::FromMilliseconds(400) 
        
        $updateTimer.Add_Tick({
            $script:tickCount++
            
            if ($script:tickCount % 10 -eq 0 -and $global:Settings.FontColorMode -eq "Auto") { 
                $currTheme = Get-ThemeColor
                if ($currTheme -ne $script:lastThemeColor) { 
                    $script:lastThemeColor = $currTheme
                    Render-Layout 
                }
            }
            
            & $script:tickLogic

            # Aggressive RAM management: Flush working set down to 10-15MB roughly every 10 seconds
            if ($script:tickCount % 25 -eq 0) { 
                [System.GC]::Collect()
                [System.GC]::WaitForPendingFinalizers()
                [Native]::SetProcessWorkingSetSize([System.Diagnostics.Process]::GetCurrentProcess().Handle, -1, -1) | Out-Null
            }
        })
        
        $updateTimer.Start()

        $script:window.Show()
        $script:dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher
        [System.Windows.Threading.Dispatcher]::Run()

        $updateTimer.Stop()
        if ($null -ne $script:window) { $script:window.Close() }
        if ($null -ne $script:dispatcher) { $script:dispatcher.InvokeShutdown() }
    }
} catch {
    $errMsg = "Exception: $($_.Exception.Message)`nStackTrace: $($_.Exception.StackTrace)"
    $errMsg | Out-File "$env:APPDATA\Detaroxz\WinQL\crash.log"
}
'@

# --- 6. WRITE REMAINING FILES & START MENU ---
[System.IO.File]::WriteAllText("$installDir\WinQL.ps1", $mainContent, [System.Text.Encoding]::UTF8)

$uninstallContent = @"
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { Start-Process powershell.exe -ArgumentList "-Sta -NoProfile -ExecutionPolicy Bypass -File `"`$PSCommandPath`"" -Verb RunAs; Exit }
Write-Host "Uninstalling WinQL..." -ForegroundColor Cyan
Get-CimInstance Win32_Process | Where-Object { (`$_.CommandLine -match "wscript.*Invisible\.vbs" -or `$_.Name -match "WinQL\.exe" -or (`$_.CommandLine -match "powershell.*WinQL\.ps1" -and `$_.CommandLine -notmatch "code\.exe|devenv\.exe|notepad")) -and `$_.ProcessId -ne `$PID } | Invoke-CimMethod -MethodName Terminate | Out-Null
`$installDir = "$installDir"; `$appDataDir = "`$env:APPDATA\Detaroxz\WinQL"; `$commonPrograms = [Environment]::GetFolderPath('CommonPrograms')
if (Test-Path `$installDir) { Remove-Item -Path `$installDir -Recurse -Force -ErrorAction SilentlyContinue }
if (Test-Path `$appDataDir) { Remove-Item -Path `$appDataDir -Recurse -Force -ErrorAction SilentlyContinue }
`$mainShortcutPath = Join-Path `$commonPrograms "WinQL.lnk"
if (Test-Path `$mainShortcutPath) { Remove-Item `$mainShortcutPath -Force -ErrorAction SilentlyContinue }
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WinQL" -ErrorAction SilentlyContinue
`$shortcutPath = Join-Path ([Environment]::GetFolderPath('Startup')) "WinQL.lnk"
if (Test-Path `$shortcutPath) { Remove-Item `$shortcutPath -Force -ErrorAction SilentlyContinue }
Unregister-ScheduledTask -TaskName "WinQL_Service" -Confirm:`$false -ErrorAction SilentlyContinue
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WinQL" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Uninstallation Complete!" -ForegroundColor Green; Start-Sleep -Seconds 2
"@
[System.IO.File]::WriteAllText("$installDir\Uninstall.ps1", $uninstallContent, [System.Text.Encoding]::UTF8)

$WshShell = New-Object -ComObject WScript.Shell
$mainShortcutPath = Join-Path $commonPrograms "WinQL.lnk"
$shortcutStart = $WshShell.CreateShortcut($mainShortcutPath)
$shortcutStart.TargetPath = "wscript.exe"
$shortcutStart.Arguments = "`"$installDir\Invisible.vbs`""
$shortcutStart.IconLocation = "$installDir\icon.ico"
$shortcutStart.Save()

# --- 7. REGISTRY & LAUNCH ---
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WinQL"
if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
Set-ItemProperty -Path $regPath -Name "DisplayName" -Value "WinQL"
Set-ItemProperty -Path $regPath -Name "DisplayVersion" -Value "1.0.0"
Set-ItemProperty -Path $regPath -Name "Publisher" -Value "Detaroxz"
Set-ItemProperty -Path $regPath -Name "DisplayIcon" -Value "$installDir\icon.ico"
Set-ItemProperty -Path $regPath -Name "UninstallString" -Value "powershell.exe -Sta -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$installDir\Uninstall.ps1`""
Set-ItemProperty -Path $regPath -Name "NoModify" -Value 1; Set-ItemProperty -Path $regPath -Name "NoRepair" -Value 1

if ($global:Settings.StartupMethod -eq "Task Manager") {
    $WshShell = New-Object -ComObject WScript.Shell
    $shortcutStart = $WshShell.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Startup')) "WinQL.lnk"))
    $shortcutStart.TargetPath = "wscript.exe"
    $shortcutStart.Arguments = "`"$installDir\Invisible.vbs`""
    $shortcutStart.WindowStyle = 0
    $shortcutStart.Save()
} elseif ($global:Settings.StartupMethod -eq "Registry") {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WinQL" -Value "wscript.exe `"$installDir\Invisible.vbs`""
} elseif ($global:Settings.StartupMethod -eq "Service") {
    try {
        $action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$installDir\Invisible.vbs`""
        $trigger = New-ScheduledTaskTrigger -AtLogOn
        Register-ScheduledTask -TaskName "WinQL_Service" -Action $action -Trigger $trigger -Force | Out-Null
    } catch {}
}

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host " Installation Complete! Launching WinQL...       " -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Cyan
Start-Process -FilePath "explorer.exe" -ArgumentList "`"$installDir\Invisible.vbs`""
Start-Sleep -Seconds 2
