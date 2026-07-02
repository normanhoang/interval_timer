import SwiftUI

/// Soft interval palette — mirrors the RN lib/colors.ts hexes.
enum Palette {
    static let intervalColors: [String] = [
        "#F38181", // coral
        "#FCE38A", // yellow
        "#EAFFD0", // pale green
        "#95E1D3", // aqua
        "#A8D8EA", // sky
        "#C9B6E4", // lavender
    ]

    static let work = "#F38181"
    static let rest = "#95E1D3"
    static let preroll = "#FCE38A"
    static let warmup = "#FCE38A"
    static let cooldown = "#A8D8EA"
    static let ink = "#3B3556"
    static let primary = "#A78BFA"
    static let start = "#34C759" // "Go" green — Start/play button and icon triangle

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
