import SwiftUI

/// Circular ring whose stroke depletes as `progress` (fraction remaining, 1 = full)
/// drops. No implicit animation: the run screen feeds timestamp-exact values every
/// frame via TimelineView, and an animation here would retarget on each update and
/// fight it (visible stutter). Discrete jumps (skips) snap, which is intended.
struct ProgressRing<Content: View>: View {
    var size: CGFloat
    var strokeWidth: CGFloat
    /// Fraction remaining (0–1).
    var progress: Double
    var color: Color
    @ViewBuilder var content: () -> Content

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let theme = ThemeColors.for(scheme)
        ZStack {
            Circle()
                .stroke(theme.ringTrack, lineWidth: strokeWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                // -90° puts the trim start at 12 o'clock, but the round cap paints
                // strokeWidth/2 past it (counterclockwise). Rotate by the cap's arc
                // angle ((strokeWidth/2) / (size/2) radians) so the visible edge —
                // where the ring starts depleting — sits exactly at top center.
                .rotationEffect(.radians(-.pi / 2 + Double(strokeWidth / size)))
            content()
        }
        .frame(width: size, height: size)
    }
}
