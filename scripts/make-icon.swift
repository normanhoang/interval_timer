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

// Dark gradient wash (matches the app's dark theme: plum → indigo → navy).
let grad = CGGradient(colorsSpace: cs,
    colors: [color("#241B3A"), color("#1C2038"), color("#13202E")] as CFArray,
    locations: [0, 0.5, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: S), end: CGPoint(x: S, y: 0), options: [])

let center = CGPoint(x: S / 2, y: S / 2)

// Six interval segments — vivid pastels pop on the dark ground.
let segColors = ["#F38181", "#FCE38A", "#EAFFD0", "#95E1D3", "#A8D8EA", "#C9B6E4"]
let R = 300.0, lineWidth = 76.0, sweep = 46.0
ctx.setLineCap(.round)
ctx.setLineWidth(lineWidth)
for i in 0..<6 {
    let centerDeg = 90.0 + Double(i) * 60.0
    let a0 = (centerDeg - sweep / 2) * .pi / 180
    let a1 = (centerDeg + sweep / 2) * .pi / 180
    ctx.setStrokeColor(color(segColors[i]))
    ctx.beginPath()
    ctx.addArc(center: center, radius: R, startAngle: a0, endAngle: a1, clockwise: false)
    ctx.strokePath()
}

// Center play triangle ("Go" green), rounded corners via round-join stroke + fill.
let purple = color("#34C759")
let p1 = CGPoint(x: center.x - 84, y: center.y + 112)
let p2 = CGPoint(x: center.x - 84, y: center.y - 112)
let p3 = CGPoint(x: center.x + 138, y: center.y)
ctx.setFillColor(purple)
ctx.setStrokeColor(purple)
ctx.setLineJoin(.round)
ctx.setLineWidth(52)
ctx.beginPath()
ctx.move(to: p1)
ctx.addLine(to: p2)
ctx.addLine(to: p3)
ctx.closePath()
ctx.drawPath(using: .fillStroke)

let image = ctx.makeImage()!
let out = URL(fileURLWithPath: "IntervalTimer/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png")
let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("wrote \(out.path)")
