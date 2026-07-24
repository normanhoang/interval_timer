import SwiftUI

/// Soft interval palette — mirrors the RN lib/colors.ts hexes.
enum Palette {
    static let intervalColors: [String] = [
        "#F38181", // coral red
        "#FFB27A", // orange
        "#FCD34D", // amber
        "#B4E062", // lime
        "#5FC98A", // green
        "#3FC7B7", // teal
        "#5FB8E0", // sky
        "#6B8FE0", // blue
        "#9B8CEC", // indigo
        "#B87BDC", // purple
        "#DB86C9", // orchid
        "#F191B4", // pink
    ]

    static let work = "#F38181"
    static let rest = "#5FC98A"
    static let preroll = "#FCD34D"
    static let warmup = "#FCD34D"
    static let cooldown = "#5FB8E0"
    static let ink = "#3B3556"
    static let primary = "#A78BFA"
    static let start = "#5FC98A" // "Go" mint — Start/play button, tuned to the interval palette

    /// Darker step of an interval color, for text on a light background
    /// (work #F38181 → #E05B5B). Pastels alone don't carry enough contrast.
    static func darkStep(_ hex: String) -> Color {
        Color(hex: shade(hex, brightness: 0.92, saturation: 1.27))
    }

    /// Hand-tuned flood grounds from the design for the two colors that carry
    /// almost every run; other interval colors derive theirs in `floodStops`.
    private static let floodOverrides: [String: [String]] = [
        "#F38181": ["#DE7272", "#B14F57", "#8E3F4B"],
        "#5FC98A": ["#57B57F", "#3E8F66", "#2F7355"],
    ]

    /// Three-stop gradient filling the whole Run screen in "Flood" style:
    /// base → ~25% darker at 62% → ~40% darker at 100%, slightly deeper each step.
    static func floodStops(_ hex: String) -> [Color] {
        floodHexes(hex).map { Color(hex: $0) }
    }

    /// The flood's darkest tone — used for glyphs sitting on a white control.
    static func floodDeep(_ hex: String) -> Color {
        Color(hex: floodHexes(hex)[2])
    }

    /// The three flood stops as hexes (overrides applied) — the testable half of `floodStops`.
    static func floodHexes(_ hex: String) -> [String] {
        if let fixed = floodOverrides[hex.uppercased()] { return fixed }
        return derivedFloodHexes(hex)
    }

    private static func derivedFloodHexes(_ hex: String) -> [String] {
        [(0.90, 1.03), (0.71, 1.10), (0.57, 1.13)].map { shade(hex, brightness: $0.0, saturation: $0.1) }
    }

    /// Scale a hex color's HSB brightness/saturation, keeping its hue.
    static func shade(_ hex: String, brightness: Double, saturation: Double) -> String {
        let (r, g, b) = rgb(hex)
        var (h, s, v) = hsb(r: Double(r) / 255, g: Double(g) / 255, b: Double(b) / 255)
        s = min(1, s * saturation)
        v = min(1, v * brightness)
        let (nr, ng, nb) = rgb(h: h, s: s, v: v)
        return String(format: "#%02X%02X%02X", Int((nr * 255).rounded()), Int((ng * 255).rounded()), Int((nb * 255).rounded()))
    }

    private static func hsb(r: Double, g: Double, b: Double) -> (Double, Double, Double) {
        let maxV = max(r, g, b), minV = min(r, g, b)
        let delta = maxV - minV
        var h = 0.0
        if delta > 0 {
            if maxV == r { h = 60 * ((g - b) / delta).truncatingRemainder(dividingBy: 6) }
            else if maxV == g { h = 60 * ((b - r) / delta + 2) }
            else { h = 60 * ((r - g) / delta + 4) }
        }
        if h < 0 { h += 360 }
        return (h, maxV == 0 ? 0 : delta / maxV, maxV)
    }

    private static func rgb(h: Double, s: Double, v: Double) -> (Double, Double, Double) {
        let c = v * s
        let x = c * (1 - abs((h / 60).truncatingRemainder(dividingBy: 2) - 1))
        let m = v - c
        let (r, g, b): (Double, Double, Double)
        switch h {
        case ..<60: (r, g, b) = (c, x, 0)
        case ..<120: (r, g, b) = (x, c, 0)
        case ..<180: (r, g, b) = (0, c, x)
        case ..<240: (r, g, b) = (0, x, c)
        case ..<300: (r, g, b) = (x, 0, c)
        default: (r, g, b) = (c, 0, x)
        }
        return (r + m, g + m, b + m)
    }

    /// Perceived-luminance check for picking a readable foreground on a swatch.
    static func isLight(_ hex: String) -> Bool {
        let (r, g, b) = rgb(hex)
        return 0.299 * Double(r) + 0.587 * Double(g) + 0.114 * Double(b) > 150
    }

    static func rgb(_ hex: String) -> (Int, Int, Int) {
        var s = hex
        if s.hasPrefix("#") { s.removeFirst() }
        let n = Int(s, radix: 16) ?? 0
        return ((n >> 16) & 255, (n >> 8) & 255, n & 255)
    }
}

extension Color {
    /// Build a Color from a "#RRGGBB" hex string.
    init(hex: String) {
        let (r, g, b) = Palette.rgb(hex)
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}
