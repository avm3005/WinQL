# WinQL ⚡
### A taskbar-integrated utility launcher & media control engine for Windows

WinQL is a lightweight, highly customizable Windows taskbar utility built with **PowerShell and C#**. It brings shortcuts, system controls, window management, application launching, and adaptive media controls directly to your Windows taskbar.

Designed to stay out of your way while remaining instantly accessible, WinQL lets you build a taskbar workflow tailored to the way you use your PC.

> **Current Version:** `v1.0.0` 
> **Built With:** PowerShell + C#

---

## ✨ Features
### 🎵 Adaptive Media Controller
<img width="1920" height="1080" alt="Screenshot (48)" src="https://github.com/user-attachments/assets/7a144f47-72e1-48f1-adc9-57ffb25fb15b" />

WinQL provides an intelligent media control system that automatically detects and interacts with active media sessions.
* Integrates with **Windows System Media Transport Controls (SMTC)**.
* Displays:
  * Currently playing track
  * Artist
  * Album artwork
* Browser support includes:
  * Chrome
  * Microsoft Edge
  * Firefox
  * Brave
  * Opera
  * Zen
* Automatically switches to the player that starts playing a new track.
* Use **Middle-Click** to cycle between active media sessions.


### ⚡ Customizable Shortcut Hub: 
<img width="1920" height="1080" alt="Screenshot (49)" src="https://github.com/user-attachments/assets/aadf4ea1-6cec-4493-87a8-7392407f60a5" />

Turn your taskbar into a personalized command center.
* Configure up to **10 custom taskbar buttons**.
* Assign a custom **single-character icon or label** to each button.
* Each button can have completely independent actions.


### 🖱️ Multi-Action Mouse Controls
<img width="351" height="236" alt="{B7C23C7F-638E-4D67-8C26-A1D4575F6C04}" src="https://github.com/user-attachments/assets/f273d98c-3176-4c70-a63a-24339392d90f" />

Every button can respond differently depending on how you interact with it.
Supported inputs:
* Left Click
* Left Double-Click
* Right Click
* Right Double-Click
* Middle Click
This allows a single taskbar button to perform multiple functions without taking up additional space.


### 🛠️ Extensive Action Library
WinQL includes a broad collection of actions for everyday Windows workflows.
#### System
* Toggle Wi-Fi
* Toggle Bluetooth
* Adjust volume
* Adjust brightness
#### Navigation & Clipboard
* Back
* Forward
* Copy
* Cut
* Paste
#### Application & Command Execution
* Launch applications
* Open websites
* Execute PowerShell scripts
* Execute CMD commands
* Run scripts visibly or silently
#### Window Management
* Switch to open windows
* Terminate processes
#### Personalization
* Change wallpapers
* Toggle Windows Light/Dark mode


### 🎨 Highly Customizable UI
Customize WinQL to match your desktop and workflow.
Available options include:
* Taskbar alignment:
  * Left
  * Center
  * Right
* Element spacing
* Button hitboxes
* Fonts
* Text and UI colors
* Automatic Windows theme synchronization


### 💾 Portable Configuration
Your entire WinQL configuration can be exported and imported through `settings.json`.
This makes it easy to:
* Back up your configuration
* Move your setup to another PC
* Restore your preferred workflow
* Share configurations

---

# 🚀 Installation
## Requirements
Before installing WinQL, make sure you have:
* Windows 10 or Windows 11
* PowerShell
* Administrator privileges
> The installer will request administrator privileges automatically when required.

## Install
1. Open terminal(powershell) as administrator 
2. Enter the following command
   ```
   irm "https://raw.githubusercontent.com/avm3005/WinQL/main/Setup/setup.ps1" | iex
   ```
3. The installer will:
   * Remove previous WinQL installations when applicable.
   * Set up the required components.
   * Compile required assets.
   * Configure taskbar integration.
   * Launch WinQL.
Once installation is complete, WinQL will appear on your taskbar.

---

# 🎮 Usage
## 🎵 Media Controls
WinQL provides multiple interaction methods for controlling your currently playing media.

### Album Artwork / Thumbnail
| Action            | Function                                      |
| ----------------- | --------------------------------------------- |
| Left Click        | Play / Pause                                  |
| Left Double-Click | Bring the media application to the foreground |
| Middle Click | Cycle between active media sessions |
| Right Click  | Temporarily hide the media player   |

### Track Information / Title
| Action             | Function       |
| ------------------ | -------------- |
| Left Click         | Play / Pause   |
| Left Double-Click  | Previous Track |
| Right Double-Click | Next Track     |
| Middle Click | Cycle between active media sessions |
| Right Click  | Temporarily hide the media player   |

When the media player is hidden, a small pin remains available to restore it.

---

# ⚙️ Customizing Buttons
WinQL can be configured entirely through its settings interface.
### 1. Open Settings
Right-click the **WinQL system tray icon** in the bottom-right corner of Windows and select **Settings**.
### 2. Configure Buttons
Navigate to:
**Button Actions → Buttons**
From here you can:
* Enable between **1 and 10 buttons**.
* Assign an icon or one-character label to each button.
### 3. Configure Mouse Actions
Open the **Clicks** sub-tab.
Enable whichever interactions you want to use:
* Left Click
* Left Double-Click
* Right Click
* Right Double-Click
* Middle Click
### 4. Assign Actions
Open the **Actions** sub-tab and use the **Action Builder** to determine what each interaction does.
For example:
```text
Button 1
├── Left Click       → Open Spotify
├── Left Double-Click → Play/Pause
├── Right Click      → Next Track
└── Middle Click     → Open Music Folder
```
This allows a single button to become a compact multi-purpose shortcut.

---


# 💾 Configuration & Backup
WinQL stores its configuration in:
```text
settings.json
```
Use the built-in **Export** and **Import** functionality to back up or restore your setup.

---


# 🗑️ Uninstallation
WinQL includes its own cleanup process.
<img width="1319" height="369" alt="{73C009D6-BBE9-4A74-A8E7-263A44BAA7FC}" src="https://github.com/user-attachments/assets/20fe8beb-d400-457e-b336-27feddf73dda" />
To uninstall:
1. Open **Windows Settings**.
2. Go to **Apps → Installed apps**.
3. Search for **WinQL**.
4. Click **Uninstall**.

The uninstaller will clean up WinQL's associated:
* Registry entries
* Scheduled tasks
* Application data
* Installation files

---


# 📋 Roadmap
Potential future improvements may include:
* Additional media-player integrations
* More Windows system controls
* Additional taskbar customization
* More automation actions
* Expanded configuration options
* Additional media metadata providers
* If-else scripts

---


# 🤝 Contributing
Contributions, bug reports, and feature requests are welcome.
If you find a problem:
1. Check the existing issues.
2. Create a new issue if the problem has not already been reported.
3. Include:
   * Windows version
   * WinQL version
   * Steps to reproduce
   * Expected behavior
   * Actual behavior
   * Relevant screenshots or logs
For feature requests, describe the problem you're trying to solve and how you would like WinQL to behave.

---


# 👨‍💻 Author
Created by **Detaroxz**.
If you encounter a bug or want to request a feature, use the integrated options in the **About** tab of the WinQL settings to get in touch.
<div align="center">
WinQL: Your taskbar. Your workflow.
  
Made for Windows users who want more from their taskbar.
</div>
