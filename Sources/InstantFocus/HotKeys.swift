import AppKit
import Carbon.HIToolbox

/// Global shortcuts via a keyboard event tap (like ISS and skhd). Carbon's
/// RegisterEventHotKey would need no permission, but since macOS 15 it refuses
/// ⌥-only and ⌥⇧-only combos, which rules out shortcuts like ⌥1.
final class HotKeys {
    static let shared = HotKeys()
    /// The modifier bits that count; NSEvent.ModifierFlags and CGEventFlags agree on these.
    static let modifierMask: NSEvent.ModifierFlags = [.command, .option, .control, .shift]

    /// Runs on the main thread when the app-list shortcut is pressed.
    var onMenuShortcut: (() -> Void)?
    /// The app list is open: keys go to it, with Space acting as Return.
    var menuOpen = false

    private var tap: CFMachPort?

    /// Installs the tap. Fails until Accessibility access is granted.
    func start() -> Bool {
        if let tap, CFMachPortIsValid(tap) { return true }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
            callback: { _, type, event, _ in HotKeys.shared.handle(type, event) },
            userInfo: nil
        ) else { return false }
        self.tap = tap
        CFRunLoopAddSource(CFRunLoopGetMain(), CFMachPortCreateRunLoopSource(nil, tap, 0), .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    private func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }
        let store = Store.shared
        guard type == .keyDown, !store.recording else { return Unmanaged.passUnretained(event) }

        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let modifiers = UInt(event.flags.rawValue) & HotKeys.modifierMask.rawValue
        let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0

        if keyCode == store.menuKeyCode && modifiers == store.menuModifiers {
            if !isRepeat { DispatchQueue.main.async { self.onMenuShortcut?() } }
            return nil
        }
        if menuOpen {
            if Int(keyCode) == kVK_Space && modifiers == 0 {
                event.setIntegerValueField(.keyboardEventKeycode, value: Int64(kVK_Return))
                event.keyboardSetUnicodeString(stringLength: 1, unicodeString: [0x0D])
            }
            return Unmanaged.passUnretained(event)  // the menu handles it (app shortcuts too)
        }
        guard let item = store.shortcuts.first(where: { $0.keyCode == keyCode && $0.modifiers == modifiers })
        else { return Unmanaged.passUnretained(event) }

        if !isRepeat { DispatchQueue.main.async { Focuser.focus(item) } }
        return nil  // swallow it (auto-repeats too), so the frontmost app doesn't also get it
    }
}
