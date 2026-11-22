import AppKit
import ISS

enum Focuser {
    /// Bring `item`'s app forward. First jump to the Space holding its window via ISS,
    /// so by the time macOS activates the app there's nothing to animate.
    static func focus(_ item: AppShortcut) {
        let app = item.bundleID.flatMap { NSRunningApplication.runningApplications(withBundleIdentifier: $0).first }
        if !jump(to: app, then: { activate(item.url) }) { activate(item.url) }
    }

    /// An app came forward some other way (⌘Tab, Dock, …) and macOS didn't switch Spaces
    /// (that's turned off): switch to its window's Space instantly and keep it in front.
    static func reveal(_ app: NSRunningApplication) {
        guard let url = app.bundleURL else { return }
        jump(to: app) { activate(url) }
    }

    /// Instantly switch to the Space holding `app`'s frontmost window, then run `done` once it shows.
    /// False when no switch is needed (a window is already on screen) or possible.
    @discardableResult
    private static func jump(to app: NSRunningApplication?, then done: @escaping () -> Void) -> Bool {
        guard let app, let target = Spaces.target(for: app.processIdentifier) else { return false }

        // ISS switches the Space on the display under the cursor, so put the cursor
        // on the target window's display first (mouse follows focus).
        if Spaces.display(at: Spaces.cursor) != Spaces.display(at: target.center) {
            CGWarpMouseCursorPosition(target.center)
            CGAssociateMouseAndMouseCursorPosition(1)
        }
        guard iss_switch_to_index(UInt32(target.index)) else { return false }

        // Continue as soon as the Space is showing. Poll off the main thread: ISS's event tap
        // runs on the main run loop and must keep processing during the switch.
        DispatchQueue.global(qos: .userInteractive).async {
            let start = Date()
            while !Spaces.isVisible(target.space), Date().timeIntervalSince(start) < 0.5 {
                usleep(2_000)
            }
            DispatchQueue.main.async(execute: done)
        }
        return true
    }

    /// Same as `open -a`: launches the app if needed, unhides it, brings it forward.
    private static func activate(_ url: URL) {
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: config)
    }
}
