import SwiftUI

/// Circular ring whose stroke depletes as `progress` (fraction remaining, 1 = full)
/// drops. The short linear timing smooths discrete updates (skips, 100ms ticks);
/// frame-rate callers (TimelineView) barely engage it.
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
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.14), value: progress)
            content()
        }
        .frame(width: size, height: size)
    }
}
