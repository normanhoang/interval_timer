import SwiftUI

/// Whole-workout progress: one sliver per flattened segment, width proportional
/// to its duration. Past segments read full, future ones washed out, and the
/// current one fills as it runs.
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

    var body: some View {
        let total = max(1, segments.reduce(0) { $0 + $1.seconds })
        GeometryReader { geo in
            let available = geo.size.width - gap * CGFloat(max(0, segments.count - 1))
            HStack(spacing: gap) {
                ForEach(Array(segments.enumerated()), id: \.offset) { i, segment in
                    let width = available * CGFloat(segment.seconds) / CGFloat(total)
                    Capsule()
                        .fill(fill(i, segment, past: false))
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(fill(i, segment, past: true))
                                .frame(width: width * doneFraction(i))
                        }
                        .frame(width: width)
                }
            }
        }
        .frame(height: height)
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
