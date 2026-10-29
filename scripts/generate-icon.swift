// Run from the repository root: swift scripts/generate-icon.swift
// The icon is drawn from the same simple geometry as the app's dial.
import AppKit

func color(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: Double((hex >> 16) & 255) / 255,
            green: Double((hex >> 8) & 255) / 255,
            blue: Double(hex & 255) / 255, alpha: 1)
}

func drawIcon() {
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.14)
    shadow.shadowBlurRadius = 24
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.set()
    let tile = NSBezierPath(roundedRect: NSRect(x: 64, y: 64, width: 896, height: 896), xRadius: 194, yRadius: 194)
    color(0xF7F6F2).setFill()
    tile.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    let dialShadow = NSShadow()
    dialShadow.shadowColor = color(0xA9A695).withAlphaComponent(0.25)
    dialShadow.shadowBlurRadius = 30
    dialShadow.shadowOffset = NSSize(width: 0, height: -14)
    dialShadow.set()
    color(0xECEAE3).setFill()
    NSBezierPath(ovalIn: NSRect(x: 168, y: 168, width: 688, height: 688)).fill()
    NSGraphicsContext.restoreGraphicsState()

    let rim = NSBezierPath(ovalIn: NSRect(x: 168, y: 168, width: 688, height: 688))
    NSGradient(starting: color(0xE5E3DC), ending: .white)!.draw(in: rim, angle: 70)
    color(0xF0EFE9).setFill()
    NSBezierPath(ovalIn: NSRect(x: 210, y: 210, width: 604, height: 604)).fill()

    let center = NSPoint(x: 512, y: 512)
    let sector = NSBezierPath()
    sector.move(to: center)
    sector.appendArc(withCenter: center, radius: 302, startAngle: 90, endAngle: -180, clockwise: true)
    sector.close()
    NSGradient(starting: color(0x648A94), ending: color(0x8CAEB5))!.draw(in: sector, angle: 90)

    color(0xF7F6F2).setStroke()
    let hand = NSBezierPath()
    hand.move(to: center)
    hand.line(to: NSPoint(x: 210, y: 512))
    hand.lineWidth = 5
    hand.stroke()
    color(0xF7F6F2).setFill()
    NSBezierPath(ovalIn: NSRect(x: 490, y: 490, width: 44, height: 44)).fill()
    color(0x7199A2).setFill()
    NSBezierPath(ovalIn: NSRect(x: 505, y: 505, width: 14, height: 14)).fill()
}

let destination = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Zime/Assets.xcassets/AppIcon.appiconset")
var images: [[String: String]] = []
for pointSize in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = pointSize * scale
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                      isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        NSGraphicsContext.current?.imageInterpolation = .high
        NSGraphicsContext.current?.cgContext.scaleBy(x: Double(pixels) / 1024, y: Double(pixels) / 1024)
        drawIcon()
        NSGraphicsContext.restoreGraphicsState()
        let filename = "icon_\(pointSize)x\(pointSize)@\(scale)x.png"
        try bitmap.representation(using: .png, properties: [:])!.write(to: destination.appendingPathComponent(filename))
        images.append(["idiom": "mac", "size": "\(pointSize)x\(pointSize)", "scale": "\(scale)x", "filename": filename])
    }
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: destination.appendingPathComponent("Contents.json"))
print("Generated all 10 macOS app icon sizes")
