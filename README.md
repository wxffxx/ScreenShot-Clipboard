# ScreenShot & Clipboard

A lightweight, native macOS menu bar application that supercharges your screenshot and clipboard workflow. Built entirely with Swift and AppKit, it runs silently in the background with zero Dock icon clutter.

## ✨ Features

- **Global Shortcuts**: Trigger screenshots or open the clipboard history anywhere using customizable global hotkeys.
- **Auto-Paste History**: Instantly pop up your clipboard history right at your mouse cursor. Click or use number keys to automatically paste the item into your active window.
- **Smart Image History**: Perfectly handles multiple consecutive screenshots or image copies by recording them with accurate timestamps.
- **Native Customization**: 
  - Change your global hotkeys instantly by pressing your desired key combinations.
  - Set custom clipboard history capacity (up to 50 items).
  - One-click native macOS "Launch at Login" integration (`SMAppService`).
- **One-Click Build System**: No Xcode required! Run `./build.sh` to compile the app directly into a native `.app` bundle.
- **Automated Icon Generation**: Just drop a `logo.png` or `logo.jpeg` into the folder and `./build.sh` will automatically cut, format, and package it into a perfect Apple `.icns` file.

## 🚀 Getting Started

1. Clone this repository.
2. Open your Terminal and navigate to the project directory.
3. Run the build script:
   ```bash
   chmod +x build.sh
   ./build.sh
   ```
4. The script will generate a `ScreenShot&Clipboard.app` bundle in the same folder.
5. Open the app. You will see a camera icon (📸) appear in your macOS menu bar.

> **Note on Permissions**: macOS requires Accessibility permissions to intercept global hotkeys and perform the auto-paste command (`Cmd+V`). 
> Go to **System Settings > Privacy & Security > Accessibility** and enable `ScreenShot&Clipboard`. Restart the app from the menu bar if necessary.

## ⚙️ Configuration (Preferences)

Click the menu bar icon and select **Preferences...** to open the native settings window:
- **General**: Toggle *Launch at Login* and adjust your *Clipboard Capacity*.
- **Global Shortcuts**: Click on a recording button and press your new keys (e.g., `Option + C`) to instantly bind a new global shortcut.

## 🎨 Customizing the App Icon

Want a custom icon in your Launchpad or Applications folder?
1. Find any square image (e.g., `1024x1024`).
2. Rename it to `logo.png` or `logo.jpg` and place it in the project directory.
3. Run `./build.sh`. The script will automatically parse your image, convert the formats, generate all necessary Apple sizes, and package it into your app bundle.

## 📝 License

Distributed under the MIT License.
