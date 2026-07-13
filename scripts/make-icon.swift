// Generates the app icon (dark theme) at 1024×1024 using CoreGraphics.
// Run: swift scripts/make-icon.swift
// Writes IntervalTimer/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let S = 1024.0
let cs = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(
    data: nil, width: Int(S), height: Int(S), bitsPerComponent: 8, bytesPerRow: 0,
    space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

func color(_ hex: String, _ a: Double = 1) -> CGColor {
    var s = hex; if s.hasPrefix("#") { s.removeFirst() }
    let n = Int(s, radix: 16) ?? 0
    return CGColor(colorSpace: cs, components: [
        CGFloat((n >> 16) & 255) / 255, CGFloat((n >> 8) & 255) / 255,
        CGFloat(n & 255) / 255, CGFloat(a)])!
}

// Dark gradient wash (ink → near-black, top-left to bottom-right).
let grad = CGGradient(colorsSpace: cs,
    colors: [color("#28224A"), color("#161228")] as CFArray,
    locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: S), end: CGPoint(x: S, y: 0), options: [])

// Three interval pills — the workout itself: width encodes duration
// (long work / short rest / medium work). Coords are top-down (y flipped for CG).
let pills: [(x: Double, topY: Double, w: Double, hex: String)] = [
    (212, 307, 600, "#F26D6D"), // work — long
    (212, 457, 340, "#45C583"), // rest — short
    (212, 607, 480, "#FCD34D"), // work — medium
]
for p in pills {
    let rect = CGRect(x: p.x, y: S - p.topY - 110, width: p.w, height: 110)
    let path = CGPath(roundedRect: rect, cornerWidth: 55, cornerHeight: 55, transform: nil)
    ctx.addPath(path)
    ctx.setFillColor(color(p.hex))
    ctx.fillPath()
}

let image = ctx.makeImage()!
let out = URL(fileURLWithPath: "IntervalTimer/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png")
let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("wrote \(out.path)")
