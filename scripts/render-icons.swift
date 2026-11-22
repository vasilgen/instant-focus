// Renders the menu bar icon artwork into docs/screenshots, using the app's own
// MenuBarIcon code. Run it via scripts/render-icons.sh.
import AppKit

@main enum RenderIcons {
    static let apps = ["Ghostty", "Visual Studio Code", "Google Chrome", "Microsoft Edge"]

    static func main() throws {
        let out = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        for style in IconStyle.allCases {
            let name = style == .blackOnWhite ? "black-on-white" : "white-on-black"
            try save(MenuBarIcon.make(style: style, app: nil, side: 512), scale: 1,
                     to: out.appendingPathComponent("icon-\(name).png"))
        }
        for dark in [false, true] {
            try save(overview(dark: dark), scale: 2,
                     to: out.appendingPathComponent("menubar-\(dark ? "dark" : "light").png"))
        }
    }

    /// Both styles × (no shortcut app, then each app), on a light or dark menu bar.
    static func overview(dark: Bool) -> NSImage {
        let columns: [(label: String, icon: NSImage?)] = [("No shortcut app", nil)] + apps.map {
            ($0.replacingOccurrences(of: "Visual Studio ", with: "VS ")
                .replacingOccurrences(of: "Google ", with: "")
                .replacingOccurrences(of: "Microsoft ", with: ""),
             NSWorkspace.shared.icon(forFile: "/Applications/\($0).app"))
        }
        let tile: CGFloat = 36, column: CGFloat = 104, row: CGFloat = 60, rowLabel: CGFloat = 124, pad: CGFloat = 24
        let size = NSSize(width: pad * 2 + rowLabel + column * CGFloat(columns.count),
                          height: pad * 2 + row * CGFloat(IconStyle.allCases.count) + 20)
        let ink = dark ? NSColor(white: 0.85, alpha: 1) : NSColor(white: 0.25, alpha: 1)

        return NSImage(size: size, flipped: false) { rect in
            (dark ? NSColor(white: 0.12, alpha: 1) : NSColor(white: 0.93, alpha: 1)).setFill()
            NSBezierPath(roundedRect: rect, xRadius: 16, yRadius: 16).fill()
            for (r, style) in IconStyle.allCases.enumerated() {
                let y = size.height - pad - tile - CGFloat(r) * row
                text(style.title, ink, NSRect(x: pad, y: y + tile / 2 - 9, width: rowLabel, height: 18), .left)
                for (c, entry) in columns.enumerated() {
                    let x = pad + rowLabel + CGFloat(c) * column + (column - tile) / 2
                    MenuBarIcon.make(style: style, app: entry.icon, side: tile)
                        .draw(in: NSRect(x: x, y: y, width: tile, height: tile))
                }
            }
            for (c, entry) in columns.enumerated() {
                text(entry.label, ink.withAlphaComponent(0.7),
                     NSRect(x: pad + rowLabel + CGFloat(c) * column, y: pad, width: column, height: 16), .center)
            }
            return true
        }
    }

    static func text(_ string: String, _ color: NSColor, _ rect: NSRect, _ alignment: NSTextAlignment) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        NSAttributedString(string: string, attributes: [
            .font: NSFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: color,
            .paragraphStyle: paragraph,
        ]).draw(in: rect)
    }

    static func save(_ image: NSImage, scale: CGFloat, to url: URL) throws {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(image.size.width * scale), pixelsHigh: Int(image.size.height * scale),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        rep.size = image.size
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: NSRect(origin: .zero, size: image.size))
        NSGraphicsContext.restoreGraphicsState()
        try rep.representation(using: .png, properties: [:])!.write(to: url)
        print("wrote \(url.lastPathComponent) (\(rep.pixelsWide)×\(rep.pixelsHigh))")
    }
}
