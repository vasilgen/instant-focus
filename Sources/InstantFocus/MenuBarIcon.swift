import AppKit

enum IconStyle: String, CaseIterable, Identifiable {
    case blackOnWhite, whiteOnBlack

    var id: Self { self }
    var title: String { self == .blackOnWhite ? "Black on white" : "White on black" }
    var foreground: NSColor { self == .blackOnWhite ? .black : .white }
    var background: NSColor { self == .blackOnWhite ? .white : .black }
}

/// The menu bar icon: ⚡ on a two-color tile.
enum MenuBarIcon {
    static func make(style: IconStyle, side: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
            style.background.setFill()
            NSBezierPath(roundedRect: rect, xRadius: side / 4, yRadius: side / 4).fill()
            let config = NSImage.SymbolConfiguration(pointSize: side * 11 / 18, weight: .bold)
                .applying(.init(paletteColors: [style.foreground]))
            let bolt = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: nil)!
                .withSymbolConfiguration(config)!
            bolt.draw(in: NSRect(x: (side - bolt.size.width) / 2, y: (side - bolt.size.height) / 2,
                                 width: bolt.size.width, height: bolt.size.height))
            return true
        }
        image.accessibilityDescription = "InstantFocus"
        return image
    }
}
