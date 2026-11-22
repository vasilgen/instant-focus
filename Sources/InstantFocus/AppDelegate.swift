import AppKit
import Combine
import ISS
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let store = Store.shared
    private var statusItem: NSStatusItem!
    private var settingsWindow: NSWindow?
    private var storeChanges: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Permissions.promptIfNeeded()
        setUpStatusItem()
        HotKeys.shared.onMenuShortcut = { [weak self] in self?.toggleMenu() }
        startEventTaps()

        let workspace = NSWorkspace.shared.notificationCenter
        // A Space change we didn't make invalidates ISS's index predictions.
        workspace.addObserver(forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main) { _ in
            iss_reset_predictions()
        }
        workspace.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) {
            [weak self] note in
            self?.updateIcon()
            // ⌘Tab, Dock, …: macOS activated the app without switching Spaces; do that switch, instantly.
            if self?.store.instantEverywhere == true,
               let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                Focuser.reveal(app)
            }
        }
        if store.instantEverywhere { Spaces.setSwitchOnActivate(false) }  // in case it was switched back on
        storeChanges = store.objectWillChange
            .receive(on: DispatchQueue.main)  // run after the change has landed
            .sink { [weak self] in self?.updateIcon() }

        if store.shortcuts.isEmpty || !store.tapsReady { showSettings() }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return false
    }

    /// Our shortcut tap and ISS's switching tap both need Accessibility;
    /// retry every second until it's granted.
    private func startEventTaps() {
        let hotkeys = HotKeys.shared.start()
        let iss = iss_init()
        store.tapsReady = hotkeys && iss
        if !store.tapsReady {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in self?.startEventTaps() }
        }
    }

    // MARK: Menu bar

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let menu = NSMenu()
        menu.delegate = self
        menuNeedsUpdate(menu)
        statusItem.menu = menu  // a click opens it; so does the app-list shortcut (toggleMenu)
        updateIcon()
    }

    /// Open the menu under the menu bar icon, or close it if it's open. Positioned
    /// explicitly rather than by "clicking" the icon, so it also shows over full-screen
    /// apps, where the menu bar is hidden.
    private func toggleMenu() {
        guard let menu = statusItem.menu else { return }
        if HotKeys.shared.menuOpen { return menu.cancelTracking() }
        let iconWindow = statusItem.button?.window
        let screen = iconWindow?.screen ?? NSScreen.main
        let top = (screen?.frame.maxY ?? 0) - NSStatusBar.system.thickness
        _ = menu.popUp(positioning: nil, at: NSPoint(x: iconWindow?.frame.minX ?? 0, y: top), in: nil)
    }

    /// Rebuilt on every open: your apps (✓ on the focused one), then Settings and Quit.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let frontID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        for app in store.shortcuts {
            let item = menu.addItem(withTitle: app.name, action: #selector(focusFromMenu), keyEquivalent: "")
            item.target = self
            item.representedObject = app.id
            item.state = app.bundleID == frontID ? .on : .off
            item.image = NSWorkspace.shared.icon(forFile: app.path)
            item.image?.size = NSSize(width: 16, height: 16)
            if let keyCode = app.keyCode, let key = KeyNames.character(for: keyCode) {
                item.keyEquivalent = key.lowercased()
                item.keyEquivalentModifierMask = NSEvent.ModifierFlags(rawValue: app.modifiers)
            }
        }
        if !store.shortcuts.isEmpty { menu.addItem(.separator()) }
        menu.addItem(withTitle: "Settings…", action: #selector(showSettings), keyEquivalent: ",").target = self
        menu.addItem(withTitle: "Quit InstantFocus", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }

    func menuWillOpen(_ menu: NSMenu) { HotKeys.shared.menuOpen = true }
    func menuDidClose(_ menu: NSMenu) { HotKeys.shared.menuOpen = false }

    @objc private func focusFromMenu(_ sender: NSMenuItem) {
        if let app = store.shortcuts.first(where: { $0.id == sender.representedObject as? UUID }) {
            Focuser.focus(app)
        }
    }

    /// The frontmost app's icon when that app has a shortcut, otherwise ⚡.
    private func updateIcon() {
        let front = NSWorkspace.shared.frontmostApplication
        let hasShortcut = front?.bundleIdentifier.map { id in store.shortcuts.contains { $0.bundleID == id } } ?? false
        statusItem.button?.image = MenuBarIcon.make(style: store.iconStyle, app: hasShortcut ? front?.icon : nil)
    }

    @objc func showSettings() {
        if settingsWindow == nil {
            let window = NSWindow(contentViewController: NSHostingController(
                rootView: SettingsView().environmentObject(store)))
            window.title = "InstantFocus"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}
