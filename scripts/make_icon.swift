import AppKit

let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

let directory = URL(fileURLWithPath: CommandLine.arguments[1])

for (name, pixels) in sizes {
    let image = NSImage(size: NSSize(width: pixels, height: pixels))
    image.lockFocus()
    NSColor(srgbRed: 0.08, green: 0.075, blue: 0.065, alpha: 1).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: pixels, height: pixels)).fill()
    let scale = CGFloat(pixels)
    func card(_ rect: NSRect, color: NSColor) {
        color.setFill()
        NSBezierPath(roundedRect: rect, xRadius: scale * 0.03, yRadius: scale * 0.03).fill()
    }
    card(NSRect(x: scale * 0.16, y: scale * 0.22, width: scale * 0.46, height: scale * 0.5), color: NSColor(srgbRed: 0.16, green: 0.2, blue: 0.24, alpha: 1))
    card(NSRect(x: scale * 0.4, y: scale * 0.34, width: scale * 0.44, height: scale * 0.36), color: NSColor(srgbRed: 0.91, green: 0.63, blue: 0.29, alpha: 1))
    image.unlockFocus()
    guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) else {
        fputs("failed \(name)\n", stderr)
        exit(1)
    }
    try png.write(to: directory.appendingPathComponent(name))
}
