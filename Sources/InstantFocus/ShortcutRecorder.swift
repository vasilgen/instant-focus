import AppKit
import Carbon
import SwiftUI

/// Click, then press a combo. Esc cancels, Delete clears. A modifier is required
/// unless it's a function key.
struct ShortcutRecorder: View {
    let keyCode: UInt16?
    let modifiers: UInt
    let onChange: (UInt16?, UInt) -> Void
    @State private var monitor: Any?

    var body: some View {
        Button(action: { monitor == nil ? start() : stop() }) {
            Text(label)
                .frame(minWidth: 120)
                .foregroundStyle(keyCode == nil && monitor == nil ? .secondary : .primary)
        }
        .onDisappear(perform: stop)
    }

    private var label: String {
        if monitor != nil { return "Type shortcut…" }
        guard let keyCode else { return "Record Shortcut" }
        return KeyNames.describe(keyCode, modifiers)
    }

    private func start() {
        Store.shared.recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let mods = event.modifierFlags.intersection(HotKeys.modifierMask)
            let key = event.keyCode
            if mods.isEmpty && key == UInt16(kVK_Escape) {
                stop()
            } else if mods.isEmpty && (key == UInt16(kVK_Delete) || key == UInt16(kVK_ForwardDelete)) {
                onChange(nil, 0)
                stop()
            } else if mods.isEmpty && !KeyNames.isFunctionKey(key) {
                NSSound.beep()
            } else {
                onChange(key, mods.rawValue)
                stop()
            }
            return nil
        }
    }

    private func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        Store.shared.recording = false
    }
}

enum KeyNames {
    private static let special: [Int: String] = [
        kVK_Return: "↩", kVK_Tab: "⇥", kVK_Space: "Space", kVK_Delete: "⌫", kVK_Escape: "⎋",
        kVK_ForwardDelete: "⌦", kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_DownArrow: "↓",
        kVK_UpArrow: "↑", kVK_Home: "↖", kVK_End: "↘", kVK_PageUp: "⇞", kVK_PageDown: "⇟",
    ]
    private static let functionKeys: [Int] = [
        kVK_F1, kVK_F2, kVK_F3, kVK_F4, kVK_F5, kVK_F6, kVK_F7, kVK_F8, kVK_F9, kVK_F10,
        kVK_F11, kVK_F12, kVK_F13, kVK_F14, kVK_F15, kVK_F16, kVK_F17, kVK_F18, kVK_F19, kVK_F20,
    ]

    static func isFunctionKey(_ code: UInt16) -> Bool { functionKeys.contains(Int(code)) }

    /// e.g. "⌥1", "⌃⌘T"
    static func describe(_ code: UInt16, _ modifiers: UInt) -> String {
        let m = NSEvent.ModifierFlags(rawValue: modifiers)
        var s = ""
        if m.contains(.control) { s += "⌃" }
        if m.contains(.option) { s += "⌥" }
        if m.contains(.shift) { s += "⇧" }
        if m.contains(.command) { s += "⌘" }
        if let i = functionKeys.firstIndex(of: Int(code)) { return s + "F\(i + 1)" }
        return s + (special[Int(code)] ?? character(for: code) ?? "Key \(code)")
    }

    /// The key's character on the current keyboard layout, ignoring modifiers.
    static func character(for code: UInt16) -> String? {
        guard let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
              let ptr = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else { return nil }
        let layout = Unmanaged<CFData>.fromOpaque(ptr).takeUnretainedValue() as Data
        var deadKeys: UInt32 = 0
        var length = 0
        var chars = [UniChar](repeating: 0, count: 4)
        let status = layout.withUnsafeBytes { buffer in
            UCKeyTranslate(
                buffer.bindMemory(to: UCKeyboardLayout.self).baseAddress, code,
                UInt16(kUCKeyActionDisplay), 0, UInt32(LMGetKbdType()),
                OptionBits(kUCKeyTranslateNoDeadKeysMask), &deadKeys, chars.count, &length, &chars)
        }
        guard status == noErr, length > 0 else { return nil }
        return String(utf16CodeUnits: chars, count: length).uppercased()
    }
}
