import AppKit

// Renders the 1024×1024 base app icon (two keycaps: ⌃ › X) to a PNG.
// Usage: swift Scripts/render_icon.swift <output.png>

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_1024x1024.png"
let W: CGFloat = 1024

func color(_ hex: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(W), pixelsHigh: Int(W),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Background squircle, inset like standard macOS icons, with a subtle vertical gradient.
let inset = W * 0.098
let bgRect = NSRect(x: inset, y: inset, width: W - 2 * inset, height: W - 2 * inset)
let bg = NSBezierPath(roundedRect: bgRect, xRadius: bgRect.width * 0.225, yRadius: bgRect.width * 0.225)
NSGradient(starting: color(0x2A2F45), ending: color(0x14161C))!.draw(in: bg, angle: -90)

// A keycap: lighter top face over a darker base, label centered.
func keycap(_ rect: NSRect, _ label: String, labelColor: NSColor) {
    let r = rect.width * 0.2
    color(0x0B0C10).setFill()
    NSBezierPath(roundedRect: rect, xRadius: r, yRadius: r).fill()
    let top = NSRect(x: rect.minX + rect.width * 0.06, y: rect.minY + rect.height * 0.14,
                     width: rect.width * 0.88, height: rect.height * 0.80)
    let topPath = NSBezierPath(roundedRect: top, xRadius: r * 0.8, yRadius: r * 0.8)
    NSGradient(starting: color(0xF4F5FA), ending: color(0xC9CCDA))!.draw(in: topPath, angle: -90)

    let font = NSFont.systemFont(ofSize: top.height * 0.58, weight: .bold)
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: labelColor]
    let size = (label as NSString).size(withAttributes: attrs)
    (label as NSString).draw(at: NSPoint(x: top.midX - size.width / 2, y: top.midY - size.height / 2),
                             withAttributes: attrs)
}

let cap: CGFloat = W * 0.30
let y = W / 2 - cap / 2
keycap(NSRect(x: W * 0.17, y: y, width: cap, height: cap), "⌃", labelColor: color(0x3D59A1))
keycap(NSRect(x: W * 0.53, y: y, width: cap, height: cap), "X", labelColor: color(0x1D1F2B))

// Accent chevron between the keys.
let chevron = NSBezierPath()
chevron.move(to: NSPoint(x: W * 0.485, y: W * 0.545))
chevron.line(to: NSPoint(x: W * 0.515, y: W * 0.50))
chevron.line(to: NSPoint(x: W * 0.485, y: W * 0.455))
chevron.lineWidth = W * 0.022
chevron.lineCapStyle = .round
chevron.lineJoinStyle = .round
color(0x7AA2F7).setStroke()
chevron.stroke()

// Accent underline: "shown on screen".
color(0x7AA2F7).setFill()
NSBezierPath(roundedRect: NSRect(x: W * 0.30, y: W * 0.24, width: W * 0.40, height: W * 0.03),
             xRadius: W * 0.015, yRadius: W * 0.015).fill()

NSGraphicsContext.current = nil
guard let png = rep.representation(using: .png, properties: [:]),
      (try? png.write(to: URL(fileURLWithPath: outputPath))) != nil else {
    FileHandle.standardError.write(Data("failed to write PNG\n".utf8))
    exit(1)
}
print("Wrote \(outputPath)")
