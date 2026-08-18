import AppKit
import Foundation

let outputs = CommandLine.arguments.dropFirst()
guard !outputs.isEmpty else {
    fputs("Pass at least one output PNG path.\n", stderr)
    exit(2)
}

let canvas = NSSize(width: 1024, height: 1024)
let image = NSImage(size: canvas)
image.lockFocus()

NSColor.white.setFill()
NSRect(origin: .zero, size: canvas).fill()

let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
let attributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 205, weight: .black),
    .foregroundColor: NSColor.black,
    .paragraphStyle: paragraph,
    .kern: -7
]

NSString(string: "CATCH").draw(
    in: NSRect(x: 60, y: 505, width: 904, height: 260),
    withAttributes: attributes
)
NSString(string: "UP").draw(
    in: NSRect(x: 60, y: 255, width: 904, height: 260),
    withAttributes: attributes
)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Could not render app icon.\n", stderr)
    exit(1)
}

for path in outputs {
    let url = URL(fileURLWithPath: String(path))
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try png.write(to: url, options: .atomic)
}

