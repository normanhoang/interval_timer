import SwiftUI

/// Whole-workout progress: one sliver per flattened segment, width proportional
/// to its duration. Past segments read full, future ones washed out, and the
/// current one fills from its leading edge.
struct SegmentBar: View {
    var segments: [Segment]
    /// Index of the running segment.
    var index: Int
    /// Fraction of the current segment already elapsed (0–1).
    var elapsedFraction: Double
    /// Flood draws in white over the interval ground; ring draws in the segment colors.
    var flood: Bool
    var height: CGFloat = 10
    var gap: CGFloat = 3

    /// Under this a pill is too thin to read as a pill at all.
    private let minPillWidth: CGFloat = 4

    var body: some View {
        let total = max(1, segments.reduce(0) { $0 + $1.seconds })
        GeometryReader { geo in
            if let spacing = spacing(in: geo.size.width, total: total) {
                pills(width: geo.size.width, spacing: spacing, total: total)
            } else {
                continuousBar(width: geo.size.width, total: total)
            }
        }
        .frame(height: height)
    }

    private func pills(width: CGFloat, spacing: CGFloat, total: Int) -> some View {
        let available = width - spacing * CGFloat(max(0, segments.count - 1))
        return HStack(spacing: spacing) {
            ForEach(Array(segments.enumerated()), id: \.offset) { i, segment in
                bar(track: fill(i, segment, past: false),
                    lit: fill(i, segment, past: true),
                    width: available * CGFloat(segment.seconds) / CGFloat(total),
                    litFraction: doneFraction(i))
            }
        }
    }

    /// A capsule track with its leading portion lit. The lit part is masked with a
    /// *rectangle* so it keeps the track's left cap and gets a flat leading edge —
    /// a capsule here collapses into a blob that slides right instead of filling.
    private func bar(track: Color, lit: Color, width: CGFloat, litFraction: CGFloat) -> some View {
        Capsule()
            .fill(track)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(lit)
                    .mask(alignment: .leading) { Rectangle().frame(width: width * litFraction) }
            }
            .frame(width: width)
    }

    /// One capsule for the whole run, used when there are too many segments to
    /// draw as pills. Tinted by the segment currently running.
    private func continuousBar(width: CGFloat, total: Int) -> some View {
        let current = segments.indices.contains(index) ? segments[index] : segments.last
        let color = flood ? Color.white : Color(hex: current?.color ?? Palette.preroll)
        return bar(track: color.opacity(flood ? 0.35 : 0.3),
                   lit: color.opacity(flood ? 0.95 : 1),
                   width: width, litFraction: overallFraction(total: total))
    }

    /// The gap that keeps the narrowest pill legible, or nil when even a hairline
    /// gap can't — then the bar degrades to `continuousBar`.
    private func spacing(in width: CGFloat, total: Int) -> CGFloat? {
        guard let shortest = segments.map(\.seconds).min(), width > 0 else { return nil }
        func narrowest(_ gap: CGFloat) -> CGFloat {
            let available = width - gap * CGFloat(max(0, segments.count - 1))
            return available * CGFloat(shortest) / CGFloat(total)
        }
        if narrowest(gap) >= height { return gap }
        if narrowest(1) >= minPillWidth { return 1 }
        return nil
    }

    /// Elapsed share of the whole run (0–1).
    private func overallFraction(total: Int) -> CGFloat {
        let before = segments.prefix(max(0, index)).reduce(0) { $0 + $1.seconds }
        let current = segments.indices.contains(index) ? Double(segments[index].seconds) : 0
        let elapsed = Double(before) + current * max(0, min(1, elapsedFraction))
        return CGFloat(min(1, elapsed / Double(total)))
    }

    private func doneFraction(_ i: Int) -> CGFloat {
        if i < index { return 1 }
        if i > index { return 0 }
        return CGFloat(max(0, min(1, elapsedFraction)))
    }

    private func fill(_ i: Int, _ segment: Segment, past: Bool) -> Color {
        if flood {
            return past ? .white.opacity(0.95) : .white.opacity(0.35)
        }
        let color = Color(hex: segment.color)
        return past ? color : color.opacity(0.3)
    }
}
