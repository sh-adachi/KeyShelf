import AppKit

let output = URL(fileURLWithPath: CommandLine.arguments[1])
let iconset = output.appendingPathComponent("KeyShelf.iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
var chunks = Data()
func be32(_ number: UInt32) -> Data { var value = number.bigEndian; return Data(bytes: &value, count: 4) }
let types = [16: ["icp4", "ic11"], 32: ["icp5", "ic12"], 128: ["ic07", "ic13"], 256: ["ic08", "ic14"], 512: ["ic09", "ic10"]]
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                  colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        let n = CGFloat(pixels)
        NSColor(calibratedRed: 0.08, green: 0.24, blue: 0.22, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: n * 0.06, y: n * 0.06, width: n * 0.88, height: n * 0.88), xRadius: n * 0.20, yRadius: n * 0.20).fill()
        NSColor(calibratedRed: 0.79, green: 0.89, blue: 0.78, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: n * 0.20, y: n * 0.20, width: n * 0.60, height: n * 0.07), xRadius: n * 0.025, yRadius: n * 0.025).fill()
        let text = "⌘" as NSString
        let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: n * 0.51, weight: .medium), .foregroundColor: NSColor(calibratedRed: 0.93, green: 0.97, blue: 0.88, alpha: 1)]
        let textSize = text.size(withAttributes: attributes)
        text.draw(at: NSPoint(x: (n - textSize.width) / 2, y: n * 0.34), withAttributes: attributes)
        NSGraphicsContext.restoreGraphicsState()
        guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("Icon rendering failed") }
        let suffix = scale == 2 ? "@2x" : ""
        try png.write(to: iconset.appendingPathComponent("icon_\(size)x\(size)\(suffix).png"))
        chunks.append(contentsOf: types[size]![scale - 1].utf8)
        chunks.append(be32(UInt32(png.count + 8)))
        chunks.append(png)
    }
}
var icns = Data("icns".utf8)
icns.append(be32(UInt32(chunks.count + 8)))
icns.append(chunks)
try icns.write(to: output.appendingPathComponent("KeyShelf.icns"))
