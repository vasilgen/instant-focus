import AppKit

enum IconStyle: String, CaseIterable, Identifiable {
    case blackOnWhite, whiteOnBlack

    var id: Self { self }
    var title: String { self == .blackOnWhite ? "Black on white" : "White on black" }
    var foreground: NSColor { self == .blackOnWhite ? .black : .white }
    var background: NSColor { self == .blackOnWhite ? .white : .black }
}

/// The menu bar icon: a two-color tile showing the focused app's icon, or ⚡ when there's none.
enum MenuBarIcon {
    static func make(style: IconStyle, app: NSImage?, side: CGFloat = 18) -> NSImage {
        let mask = app.flatMap { luminanceMask($0, pixels: Int(side * 4)) }
        let image = NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
            let tile = NSBezierPath(roundedRect: rect, xRadius: side / 4, yRadius: side / 4)
            style.background.setFill()
            tile.fill()
            style.foreground.setFill()

            if let mask, let cg = NSGraphicsContext.current?.cgContext {
                tile.addClip()
                cg.clip(to: rect, mask: mask)
                rect.fill()
            } else {
                let config = NSImage.SymbolConfiguration(pointSize: side * 11 / 18, weight: .bold)
                    .applying(.init(paletteColors: [style.foreground]))
                let bolt = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: nil)!
                    .withSymbolConfiguration(config)!
                bolt.draw(in: NSRect(x: (side - bolt.size.width) / 2, y: (side - bolt.size.height) / 2,
                                     width: bolt.size.width, height: bolt.size.height))
            }
            return true
        }
        image.accessibilityDescription = "InstantFocus"
        return image
    }

    /// The app icon's brightness as a mask: its glyph (bright on the dark-style icon) gets
    /// painted in the foreground color, its dark backdrop lets the tile show through.
    private static func luminanceMask(_ icon: NSImage, pixels px: Int) -> CGImage? {
        guard let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpaceCreateDeviceGray(),
                                  bitmapInfo: CGImageAlphaInfo.none.rawValue)
        else { return nil }
        let crop = CGFloat(px) * 0.12  // trim the icon's built-in margin and rim
        let rect = NSRect(x: 0, y: 0, width: px, height: px).insetBy(dx: -crop, dy: -crop)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSAppearance(named: .darkAqua)!.performAsCurrentDrawingAppearance { icon.draw(in: rect) }
        NSGraphicsContext.restoreGraphicsState()

        // Stretch contrast so the backdrop drops out fully and the glyph is solid.
        if let pixels = ctx.data?.assumingMemoryBound(to: UInt8.self) {
            for i in 0..<ctx.bytesPerRow * px {
                let level = (Double(pixels[i]) / 255 - 0.22) / 0.33
                pixels[i] = UInt8(max(0, min(1, level)) * 255)
            }
        }
        return ctx.makeImage()
    }
}
