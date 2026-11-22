import AppKit
import Carbon.HIToolbox
import ServiceManagement
import UniformTypeIdentifiers

/// One app and its shortcut. `modifiers` holds the ⌘⌥⌃⇧ bits of NSEvent.ModifierFlags
/// (identical to CGEventFlags); `keyCode` is a virtual key code, nil = no shortcut yet.
struct AppShortcut: Codable, Identifiable {
    var id = UUID()
    var name: String
    var path: String
    var keyCode: UInt16?
    var modifiers: UInt = 0

    var url: URL { URL(fileURLWithPath: path) }
    var bundleID: String? { Bundle(url: url)?.bundleIdentifier }
}

/// Settings, persisted in UserDefaults (domain io.github.vasilgen.InstantFocus).
/// `shortcuts` is a JSON string so it stays readable with `defaults read`.
final class Store: ObservableObject {
    static let shared = Store()
    private let defaults = UserDefaults.standard

    @Published var shortcuts: [AppShortcut] { didSet { saveShortcuts() } }
    /// The shortcut that opens the app list (default ⌘⇧Space); nil = none.
    @Published var menuKeyCode: UInt16? {
        didSet { defaults.set(menuKeyCode.map(Int.init) ?? -1, forKey: "menuKeyCode") }
    }
    @Published var menuModifiers: UInt { didSet { defaults.set(menuModifiers, forKey: "menuModifiers") } }
    @Published var iconStyle: IconStyle { didSet { defaults.set(iconStyle.rawValue, forKey: "iconStyle") } }
    /// Also make ⌘Tab, Dock, … switching instant (see `Spaces.setSwitchOnActivate`).
    @Published var instantEverywhere: Bool {
        didSet {
            defaults.set(instantEverywhere, forKey: "instantEverywhere")
            Spaces.setSwitchOnActivate(!instantEverywhere)
        }
    }
    /// Both event taps are installed (i.e. Accessibility is granted).
    @Published var tapsReady = false
    /// A shortcut recorder is listening; shortcuts shouldn't fire meanwhile.
    var recording = false

    private init() {
        defaults.register(defaults: [
            "menuKeyCode": kVK_Space,
            "menuModifiers": NSEvent.ModifierFlags([.command, .shift]).rawValue,
        ])
        let json = Data((defaults.string(forKey: "shortcuts") ?? "[]").utf8)
        shortcuts = (try? JSONDecoder().decode([AppShortcut].self, from: json)) ?? []
        let menuKey = defaults.integer(forKey: "menuKeyCode")
        menuKeyCode = menuKey >= 0 ? UInt16(menuKey) : nil
        menuModifiers = UInt(defaults.integer(forKey: "menuModifiers"))
        iconStyle = IconStyle(rawValue: defaults.string(forKey: "iconStyle") ?? "") ?? .blackOnWhite
        instantEverywhere = defaults.bool(forKey: "instantEverywhere")
    }

    private func saveShortcuts() {
        guard let data = try? JSONEncoder().encode(shortcuts) else { return }
        defaults.set(String(decoding: data, as: UTF8.self), forKey: "shortcuts")
    }

    /// Assign a shortcut to the app with `id`, or to the app list when `id` is nil.
    /// Whatever else had the same combo loses it: one combo, one action.
    func setShortcut(_ id: UUID?, keyCode: UInt16?, modifiers: UInt) {
        let isTaken = { (code: UInt16?, mods: UInt) in keyCode != nil && code == keyCode && mods == modifiers }
        var items = shortcuts
        for i in items.indices {
            if items[i].id == id {
                items[i].keyCode = keyCode
                items[i].modifiers = modifiers
            } else if isTaken(items[i].keyCode, items[i].modifiers) {
                items[i].keyCode = nil
                items[i].modifiers = 0
            }
        }
        shortcuts = items
        if id == nil {
            menuKeyCode = keyCode
            menuModifiers = modifiers
        } else if isTaken(menuKeyCode, menuModifiers) {
            menuKeyCode = nil
        }
    }

    func remove(_ id: UUID) { shortcuts.removeAll { $0.id == id } }

    /// Move an app up (-1) or down (+1). The app list menu uses this order.
    func move(_ id: UUID, by offset: Int) {
        guard let i = shortcuts.firstIndex(where: { $0.id == id }), shortcuts.indices.contains(i + offset)
        else { return }
        shortcuts.swapAt(i, i + offset)
    }

    func addApps() {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = true
        panel.prompt = "Add"
        guard panel.runModal() == .OK else { return }
        shortcuts += panel.urls
            .filter { url in !shortcuts.contains { $0.path == url.path } }
            .map { AppShortcut(name: $0.deletingPathExtension().lastPathComponent, path: $0.path) }
    }

    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            objectWillChange.send()
            do {
                if newValue { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            } catch {
                NSLog("InstantFocus: launch at login: \(error)")
            }
        }
    }
}
