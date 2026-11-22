import AppKit

// Private CoreGraphics (SkyLight) calls, the same ones yabai and ISS use. Looked up at
// runtime rather than linked: if a macOS update drops one, the app still launches and
// focuses apps, just with macOS's normal animation.
private typealias MainConnectionFn = @convention(c) () -> Int32
private typealias CopyDisplaySpacesFn = @convention(c) (Int32, CFString?) -> Unmanaged<CFArray>?
private typealias CopyWindowSpacesFn = @convention(c) (Int32, Int32, CFArray) -> Unmanaged<CFArray>?

private func lookup<T>(_ name: String, _: T.Type) -> T? {
    let defaultHandle = UnsafeMutableRawPointer(bitPattern: -2)  // RTLD_DEFAULT
    return dlsym(defaultHandle, name).map { unsafeBitCast($0, to: T.self) }
}
private let mainConnectionID = lookup("CGSMainConnectionID", MainConnectionFn.self)
private let copyManagedDisplaySpaces = lookup("CGSCopyManagedDisplaySpaces", CopyDisplaySpacesFn.self)
private let copySpacesForWindows = lookup("CGSCopySpacesForWindows", CopyWindowSpacesFn.self)

enum Spaces {
    struct Target {
        let index: Int        // zero-based, Mission Control order on its display (what ISS expects)
        let space: UInt64
        let center: CGPoint   // window center, global coordinates
    }

    /// Where `pid`'s frontmost window is, or nil when no switch is needed (no usable
    /// windows, or one is already on screen) or possible (private calls unavailable).
    static func target(for pid: pid_t) -> Target? {
        guard let cid = mainConnectionID?(), let copySpacesForWindows else { return nil }
        var indexOf: [UInt64: Int] = [:]
        var visible = Set<UInt64>()
        for display in managedDisplays() {
            if let current = spaceID(display["Current Space"]) { visible.insert(current) }
            for (i, id) in (display["Spaces"] as? [Any] ?? []).compactMap(spaceID).enumerated() {
                indexOf[id] = i
            }
        }

        // The app's real windows, front to back, including ones on other Spaces.
        let windows = CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], kCGNullWindowID)
            as? [[String: Any]] ?? []
        var best: Target?
        for w in windows {
            guard (w[kCGWindowOwnerPID as String] as? pid_t) == pid,
                  (w[kCGWindowLayer as String] as? Int) == 0,
                  let wid = w[kCGWindowNumber as String] as? Int,
                  let b = w[kCGWindowBounds as String] as? [String: CGFloat],
                  let width = b["Width"], let height = b["Height"], width >= 100, height >= 100
            else { continue }
            let spaces = (copySpacesForWindows(cid, 0x7, [wid] as CFArray)?.takeRetainedValue()
                as? [NSNumber] ?? []).map(\.uint64Value)
            if spaces.contains(where: visible.contains) { return nil }
            if best == nil, let space = spaces.first(where: { indexOf[$0] != nil }) {
                let center = CGPoint(x: (b["X"] ?? 0) + width / 2, y: (b["Y"] ?? 0) + height / 2)
                best = Target(index: indexOf[space]!, space: space, center: center)
            }
        }
        return best
    }

    static func isVisible(_ space: UInt64) -> Bool {
        managedDisplays().contains { spaceID($0["Current Space"]) == space }
    }

    static var cursor: CGPoint { CGEvent(source: nil)?.location ?? .zero }

    static func display(at point: CGPoint) -> CGDirectDisplayID? {
        var id: CGDirectDisplayID = 0, count: UInt32 = 0
        return CGGetDisplaysWithPoint(point, 1, &id, &count) == .success && count > 0 ? id : nil
    }

    private static func managedDisplays() -> [[String: Any]] {
        guard let cid = mainConnectionID?(), let copyManagedDisplaySpaces else { return [] }
        return copyManagedDisplaySpaces(cid, nil)?.takeRetainedValue() as? [[String: Any]] ?? []
    }

    private static func spaceID(_ dict: Any?) -> UInt64? {
        guard let d = dict as? [String: Any] else { return nil }
        return ((d["id64"] ?? d["ManagedSpaceID"]) as? NSNumber)?.uint64Value
    }
}
