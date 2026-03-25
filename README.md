# ScreenShot & Clipboard

A lightweight, native macOS menu bar application that supercharges your screenshot and clipboard workflow. Built entirely with Swift and AppKit, it runs silently in the background with zero Dock icon clutter.

## AI Usage Declaration

Over 90% of this project was built entirely by Gemini. The original intent behind this tool was to resolve the issues I encountered—specifically, the lack of a seamless screenshot utility and the absence of clipboard functionality—while transitioning from Windows to Mac.

## Features

- **Global Shortcuts**: Trigger screenshots or open the clipboard history anywhere using customizable global hotkeys.
- **Auto-Paste History**: Instantly pop up your clipboard history right at your mouse cursor. Click or use number keys to automatically paste the item into your active window.
- **Smart Image History**: Perfectly handles multiple consecutive screenshots or image copies by recording them with accurate timestamps.
- **Native Customization**: 
  - Change your global hotkeys instantly by pressing your desired key combinations.
  - Set custom clipboard history capacity (up to 50 items).
  - One-click native macOS "Launch at Login" integration (`SMAppService`).
- **One-Click Build System**: No Xcode required! Run `./build.sh` to compile the app directly into a native `.app` bundle.
- **Automated Icon Generation**: Just drop a `logo.png` or `logo.jpeg` into the folder and `./build.sh` will automatically cut, format, and package it into a perfect Apple `.icns` file.

## Configuration

Click the menu bar icon and select **Preferences...** to open the native settings window:
- **General**: Toggle *Launch at Login* and adjust your *Clipboard Capacity*.
- **Global Shortcuts**: Click on a recording button and press your new keys (e.g., `Option + C`) to instantly bind a new global shortcut.

## License

Distributed under the MIT License.
