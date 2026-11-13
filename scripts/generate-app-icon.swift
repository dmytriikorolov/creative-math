import AppKit
import Foundation

// Vector geometry/color from the original Triangle Study, on the existing surface token.
// No desktop, Metal device or generated imagery is needed to reproduce this asset.
let destination = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "Assets")
let iconset = destination.appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at: iconset,withIntermediateDirectories: true)
let variants: [(String,Int)] = [
    ("icon_16x16.png",16),("icon_16x16@2x.png",32),("icon_32x32.png",32),("icon_32x32@2x.png",64),
    ("icon_128x128.png",128),("icon_128x128@2x.png",256),("icon_256x256.png",256),("icon_256x256@2x.png",512),
    ("icon_512x512.png",512),("icon_512x512@2x.png",1024)
]
for (filename,pixels) in variants {
    let color = CGColorSpace(name: CGColorSpace.sRGB)!
    guard let context = CGContext(data: nil,width: pixels,height: pixels,bitsPerComponent: 8,bytesPerRow: 0,
                                  space: color,bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { fatalError("Icon bitmap allocation failed") }
    context.clear(CGRect(x: 0,y: 0,width: pixels,height: pixels))
    let scale = CGFloat(pixels)/1024
    context.scaleBy(x: scale,y: scale)
    context.setFillColor(CGColor(srgbRed: 20/255,green: 22/255,blue: 26/255,alpha: 1))
    context.addPath(CGPath(roundedRect: CGRect(x: 64,y: 64,width: 896,height: 896),cornerWidth: 180,cornerHeight: 180,transform: nil))
    context.fillPath()
    context.setFillColor(CGColor(srgbRed: 145/255,green: 169/255,blue: 232/255,alpha: 1))
    context.move(to: CGPoint(x: 512,y: 819)); context.addLine(to: CGPoint(x: 243,y: 320))
    context.addLine(to: CGPoint(x: 781,y: 320)); context.closePath(); context.fillPath()
    guard let image = context.makeImage(), let png = NSBitmapImageRep(cgImage: image).representation(using: .png,properties: [:]) else { fatalError("Icon PNG encoding failed") }
    try png.write(to: iconset.appendingPathComponent(filename))
}
print(iconset.path)

// Standard PNG-backed ICNS chunks; deterministic packaging also works in restricted
// CLT sessions where iconutil rejects an otherwise valid iconset.
func word(_ value: Int) -> Data {
    Data([UInt8((value >> 24)&255),UInt8((value >> 16)&255),UInt8((value >> 8)&255),UInt8(value&255)])
}
let entries = [("icp4","icon_16x16.png"),("icp5","icon_32x32.png"),("icp6","icon_32x32@2x.png"),
               ("ic07","icon_128x128.png"),("ic08","icon_256x256.png"),("ic09","icon_512x512.png"),
               ("ic10","icon_512x512@2x.png"),("ic11","icon_16x16@2x.png"),("ic12","icon_32x32@2x.png"),
               ("ic13","icon_128x128@2x.png"),("ic14","icon_256x256@2x.png")]
var chunks = Data()
for (tag,file) in entries {
    let png = try Data(contentsOf: iconset.appendingPathComponent(file))
    chunks.append(Data(tag.utf8)); chunks.append(word(png.count+8)); chunks.append(png)
}
var icon = Data("icns".utf8); icon.append(word(chunks.count+8)); icon.append(chunks)
let iconURL = destination.appendingPathComponent("AppIcon.icns")
try icon.write(to: iconURL)
guard let decoded = NSImage(contentsOf: iconURL), decoded.isValid else { fatalError("ICNS decode validation failed") }
print("Validated ICNS: \(iconURL.path)")
