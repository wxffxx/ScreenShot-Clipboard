import Cocoa
import ApplicationServices
import SwiftUI
import ServiceManagement

struct HotkeyConfig: Equatable, Codable {
    var keyCode: UInt16
    var modifiers: UInt
    
    static let defaultClipboard = HotkeyConfig(keyCode: 9, modifiers: NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue)
    static let defaultScreenshot = HotkeyConfig(keyCode: 0, modifiers: NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue)
    
    var displayString: String {
        var str = ""
        let flags = NSEvent.ModifierFlags(rawValue: modifiers)
        if flags.contains(.control) { str += "⌃" }
        if flags.contains(.option) { str += "⌥" }
        if flags.contains(.shift) { str += "⇧" }
        if flags.contains(.command) { str += "⌘" }
        
        let keyMap: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0", 30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "Return", 37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".", 48: "Tab", 49: "Space", 50: "`", 51: "Delete", 53: "Esc"
        ]
        if let char = keyMap[keyCode] {
            str += char
        } else {
            str += "Key(\(keyCode))"
        }
        return str
    }
}

class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    
    @Published var clipboardHotkey: HotkeyConfig {
        didSet {
            if let data = try? JSONEncoder().encode(clipboardHotkey) {
                UserDefaults.standard.set(data, forKey: "clipboardHotkey")
            }
        }
    }
    
    @Published var screenshotHotkey: HotkeyConfig {
        didSet {
            if let data = try? JSONEncoder().encode(screenshotHotkey) {
                UserDefaults.standard.set(data, forKey: "screenshotHotkey")
            }
        }
    }
    
    @Published var maxHistoryItems: Int {
        didSet {
            UserDefaults.standard.set(maxHistoryItems, forKey: "maxHistoryItems")
            NotificationCenter.default.post(name: NSNotification.Name("MaxHistoryUpdated"), object: nil)
        }
    }
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "clipboardHotkey"), let decoded = try? JSONDecoder().decode(HotkeyConfig.self, from: data) {
            self.clipboardHotkey = decoded
        } else {
            self.clipboardHotkey = .defaultClipboard
        }
        
        if let data = UserDefaults.standard.data(forKey: "screenshotHotkey"), let decoded = try? JSONDecoder().decode(HotkeyConfig.self, from: data) {
            self.screenshotHotkey = decoded
        } else {
            self.screenshotHotkey = .defaultScreenshot
        }
        
        let maxItems = UserDefaults.standard.integer(forKey: "maxHistoryItems")
        self.maxHistoryItems = maxItems > 0 ? maxItems : 15
    }
}

struct SettingsView: View {
    @StateObject var store = SettingsStore.shared
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    
    @State private var recordingClipboard = false
    @State private var recordingScreenshot = false
    @State private var localEventMonitor: Any?
    
    var body: some View {
        Form {
            Section(header: Text("General")) {
                HStack {
                    Text("Launch at Login:")
                    Spacer()
                    Toggle("", isOn: $launchAtLogin)
                        .labelsHidden()
                        .onChange(of: launchAtLogin) { newValue in
                            do {
                                if newValue { try SMAppService.mainApp.register() }
                                else { try SMAppService.mainApp.unregister() }
                            } catch {
                                print("Failed to toggle login item: \(error)")
                            }
                        }
                }
                
                HStack {
                    Text("Clipboard Capacity:")
                    Spacer()
                    Picker("", selection: $store.maxHistoryItems) {
                        ForEach([5, 10, 15, 20, 25, 30, 40, 50], id: \.self) { num in
                            Text("\(num) items").tag(num)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }
            }
            
            Section(header: Text("Global Shortcuts")) {
                HStack {
                    Text("Clipboard History:")
                    Spacer()
                    Button(action: { startRecording(isClipboard: true) }) {
                        Text(recordingClipboard ? "Recording..." : store.clipboardHotkey.displayString)
                            .frame(minWidth: 100, alignment: .trailing)
                    }
                }
                
                HStack {
                    Text("Take Screenshot:")
                    Spacer()
                    Button(action: { startRecording(isClipboard: false) }) {
                        Text(recordingScreenshot ? "Recording..." : store.screenshotHotkey.displayString)
                            .frame(minWidth: 100, alignment: .trailing)
                    }
                }
            }
            .padding(.top, 10)
            
            Text(recordingClipboard || recordingScreenshot ? "Press any key combination to record..." : "Click a shortcut button and press your new key combination to record.")
                .font(.caption)
                .foregroundColor(recordingClipboard || recordingScreenshot ? .red : .gray)
                .padding(.top, 20)
        }
        .padding()
        .frame(width: 450, height: 260)
        .onDisappear {
            stopRecording()
        }
    }
    
    func startRecording(isClipboard: Bool) {
        stopRecording()
        recordingClipboard = isClipboard
        recordingScreenshot = !isClipboard
        
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let keyCode = event.keyCode
            switch keyCode {
            case 54, 55, 56, 59, 60, 61, 62: // Modifier keys alone
                return event
            case 53: // Esc to cancel
                stopRecording()
                return nil
            default:
                let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                let newConfig = HotkeyConfig(keyCode: keyCode, modifiers: modifiers.rawValue)
                if recordingClipboard {
                    store.clipboardHotkey = newConfig
                } else {
                    store.screenshotHotkey = newConfig
                }
                stopRecording()
                return nil // swallow the keystroke
            }
        }
    }
    
    func stopRecording() {
        recordingClipboard = false
        recordingScreenshot = false
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }
}

struct HistoryItem {
    let timestamp: Date
    let typesAndData: [(NSPasteboard.PasteboardType, Data)]
    var displayString: String
}

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem!
    
    var history: [HistoryItem] = []
    var lastChangeCount: Int = 0
    var timer: Timer?
    
    var eventTap: CFMachPort?
    var runLoopSource: CFRunLoopSource?
    var floatingWindow: NSWindow?
    var previousForegroundApp: NSRunningApplication?
    
    var settingsWindowController: NSWindowController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "Screenshot") {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "📸"
            }
        }
        
        lastChangeCount = NSPasteboard.general.changeCount
        updateMenu()
        
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(checkPasteboard), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: .common)
        
        setupEventTap()
        
        // Re-build menu when hotkeys are updated
        NotificationCenter.default.addObserver(self, selector: #selector(updateMenu), name: NSNotification.Name("HotkeysUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(trimHistory), name: NSNotification.Name("MaxHistoryUpdated"), object: nil)
    }
    
    @objc func trimHistory() {
        let maxItems = SettingsStore.shared.maxHistoryItems
        if history.count > maxItems {
            history = Array(history.prefix(maxItems))
            updateMenu()
        }
    }

    func setupEventTap() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        if !accessEnabled {
            print("Accessibility not granted yet.")
        }
        
        let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        eventTap = CGEvent.tapCreate(tap: .cghidEventTap,
                                     place: .headInsertEventTap,
                                     options: .defaultTap,
                                     eventsOfInterest: CGEventMask(mask),
                                     callback: { proxy, type, event, refcon in
                                         
                                         if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                                             if let refcon = refcon {
                                                 let appDelegate = Unmanaged<AppDelegate>.fromOpaque(refcon).takeUnretainedValue()
                                                 if let tap = appDelegate.eventTap {
                                                     CGEvent.tapEnable(tap: tap, enable: true)
                                                 }
                                             }
                                             return Unmanaged.passRetained(event)
                                         }
                                         
                                         if type != .keyDown {
                                             return Unmanaged.passRetained(event)
                                         }
                                         
                                         let flags = event.flags
                                         let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                                         
                                         let userCmd = flags.contains(.maskCommand)
                                         let userShift = flags.contains(.maskShift)
                                         let userOpt = flags.contains(.maskAlternate)
                                         let userCtrl = flags.contains(.maskControl)
                                         
                                         let cbConf = SettingsStore.shared.clipboardHotkey
                                         let cbFlags = NSEvent.ModifierFlags(rawValue: cbConf.modifiers)
                                         let matchCb = (userCmd == cbFlags.contains(.command)) && (userShift == cbFlags.contains(.shift)) && (userOpt == cbFlags.contains(.option)) && (userCtrl == cbFlags.contains(.control)) && (keyCode == Int64(cbConf.keyCode))
                                         
                                         let scConf = SettingsStore.shared.screenshotHotkey
                                         let scFlags = NSEvent.ModifierFlags(rawValue: scConf.modifiers)
                                         let matchSc = (userCmd == scFlags.contains(.command)) && (userShift == scFlags.contains(.shift)) && (userOpt == scFlags.contains(.option)) && (userCtrl == scFlags.contains(.control)) && (keyCode == Int64(scConf.keyCode))
                                         
                                         if matchCb {
                                             if let refcon = refcon {
                                                 let appDelegate = Unmanaged<AppDelegate>.fromOpaque(refcon).takeUnretainedValue()
                                                 DispatchQueue.main.async { appDelegate.showFloatingMenu() }
                                             }
                                             return nil
                                         } else if matchSc {
                                             if let refcon = refcon {
                                                 let appDelegate = Unmanaged<AppDelegate>.fromOpaque(refcon).takeUnretainedValue()
                                                 DispatchQueue.main.async { appDelegate.captureScreen() }
                                             }
                                             return nil
                                         }
                                         
                                         return Unmanaged.passRetained(event)
                                     }, userInfo: Unmanaged.passUnretained(self).toOpaque())
                                     
        if let tap = eventTap {
            runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource!, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
        } else {
            // If we failed to create the tap, Accessibility is likely denied.
            // In a UI app, we should alert the user explicitly.
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Accessibility Permission Required"
                alert.informativeText = "macOS requires you to grant Accessibility permissions to this app so it can listen for global hotkeys (like Cmd+Shift+V).\n\nPlease go to System Settings > Privacy & Security > Accessibility and enable it for ScreenshotApp. Then RESTART the app from the menu bar."
                alert.alertStyle = .critical
                alert.addButton(withTitle: "Understood")
                alert.runModal()
            }
        }
    }

    @objc func checkPasteboard() {
        let currentChangeCount = NSPasteboard.general.changeCount
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount
        
        if let item = captureCurrentPasteboard() {
            if let first = history.first, first.displayString == item.displayString { return }
            
            history.insert(item, at: 0)
            let maxItems = SettingsStore.shared.maxHistoryItems
            if history.count > maxItems {
                history.removeLast()
            }
            updateMenu()
        }
    }
    
    func captureCurrentPasteboard() -> HistoryItem? {
        let pb = NSPasteboard.general
        let types = pb.types ?? []
        guard !types.isEmpty else { return nil }
        
        var displayString = "[Unknown Item]"
        if let str = pb.string(forType: .string) {
            let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                 displayString = "[Empty Text]"
            } else {
                 displayString = String(trimmed.prefix(30))
                 if trimmed.count > 30 { displayString += "..." }
            }
        } else if types.contains(.tiff) || types.contains(.png) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            displayString = "[Image] \(formatter.string(from: Date()))"
        } else if types.contains(.fileURL) {
            if let urlStr = pb.string(forType: .fileURL), let url = URL(string: urlStr) {
                displayString = "[File] " + url.lastPathComponent
            } else {
                displayString = "[File]"
            }
        }
        
        var typesAndData: [(NSPasteboard.PasteboardType, Data)] = []
        for type in types {
            if let data = pb.data(forType: type) {
                typesAndData.append((type, data))
            }
        }
        
        if typesAndData.isEmpty { return nil }
        return HistoryItem(timestamp: Date(), typesAndData: typesAndData, displayString: displayString)
    }

    func buildDynamicMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        
        let scShortcut = SettingsStore.shared.screenshotHotkey.displayString
        menu.addItem(NSMenuItem(title: "Take Screenshot (\(scShortcut))", action: #selector(captureScreen), keyEquivalent: ""))
        
        if !history.isEmpty {
            menu.addItem(NSMenuItem.separator())
            let cbShortcut = SettingsStore.shared.clipboardHotkey.displayString
            let historyHeader = NSMenuItem(title: "Clipboard History (\(cbShortcut))", action: nil, keyEquivalent: "")
            historyHeader.isEnabled = false
            menu.addItem(historyHeader)
            
            for (index, item) in history.enumerated() {
                var shortcut = ""
                if index < 9 { shortcut = "\(index + 1)" } else if index == 9 { shortcut = "0" }
                
                let menuItem = NSMenuItem(title: "\(index + 1). \(item.displayString)", action: #selector(selectHistoryItem(_:)), keyEquivalent: shortcut)
                menuItem.target = self
                menuItem.tag = index
                menu.addItem(menuItem)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }

    @objc func updateMenu() {
        statusItem.menu = buildDynamicMenu()
    }
    
    @objc func showSettings() {
        if let wc = settingsWindowController {
            wc.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let hostingController = NSHostingController(rootView: SettingsView())
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 450, height: 260),
                              styleMask: [.titled, .closable, .miniaturizable],
                              backing: .buffered,
                              defer: false)
        window.center()
        window.title = "ScreenShot&Clipboard Preferences"
        window.contentViewController = hostingController
        window.level = .normal
        
        let windowController = NSWindowController(window: window)
        settingsWindowController = windowController
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func showFloatingMenu() {
        previousForegroundApp = NSWorkspace.shared.frontmostApplication
        
        let menu = buildDynamicMenu()
        let mouseLoc = NSEvent.mouseLocation
        
        let window = NSWindow(contentRect: NSRect(x: mouseLoc.x, y: mouseLoc.y, width: 1, height: 1),
                              styleMask: .borderless,
                              backing: .buffered,
                              defer: false)
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.level = .popUpMenu
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        self.floatingWindow = window
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: 0), in: window.contentView)
    }

    func menuDidClose(_ menu: NSMenu) {
        if let window = floatingWindow {
            window.orderOut(nil)
            floatingWindow = nil
        }
        if let prevApp = previousForegroundApp {
            prevApp.activate(options: .activateIgnoringOtherApps)
        }
    }
    
    @objc func selectHistoryItem(_ sender: NSMenuItem) {
        let index = sender.tag
        guard index >= 0 && index < history.count else { return }
        
        let item = history[index]
        let pb = NSPasteboard.general
        pb.clearContents()
        for (type, data) in item.typesAndData {
            pb.setData(data, forType: type)
        }
        
        lastChangeCount = pb.changeCount
        
        history.remove(at: index)
        history.insert(item, at: 0)
        updateMenu()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.simulatePaste()
        }
    }
    
    func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)
        let vKeyCode: CGKeyCode = 9 // 'v'
        
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true) {
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)
        }
        
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) {
            keyUp.flags = .maskCommand
            keyUp.post(tap: .cghidEventTap)
        }
    }

    @objc func captureScreen() {
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "-c"]
        task.launch()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
