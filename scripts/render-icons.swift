// Renders the ⚡ icon artwork into docs/screenshots, using the app's own
// MenuBarIcon code. Run it via scripts/render-icons.sh.
import AppKit

@main enum RenderIcons {
    static func main() throws {
        let out = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        for style in IconStyle.allCases {
            let name = style == .blackOnWhite ? "black-on-white" : "white-on-black"
            try save(MenuBarIcon.make(style: style, side: 512),
                     to: out.appendingPathComponent("icon-\(name).png"))
        }
    }

    static func save(_ image: NSImage, to url: URL) throws {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(image.size.width), pixelsHigh: Int(image.size.height),
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
