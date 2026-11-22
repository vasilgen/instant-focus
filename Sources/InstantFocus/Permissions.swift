import AppKit

enum Permissions {
    /// Ask for Accessibility, which both event taps need. An ad-hoc–signed rebuild no longer
    /// matches its old entry (it still looks enabled but isn't), so clear that first, as ISS does.
    static func promptIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        if let id = Bundle.main.bundleIdentifier {
            let reset = Process()
            reset.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
            reset.arguments = ["reset", "Accessibility", id]
            if (try? reset.run()) != nil { reset.waitUntilExit() }
        }
        let prompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([prompt: true] as CFDictionary)
    }

    static func openSettings() {
        NSWorkspace.shared.open(
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
}
