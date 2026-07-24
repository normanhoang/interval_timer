import SwiftUI

/// Whole-workout progress: one pill, divided into a slice per flattened segment
/// with the slice width proportional to its duration. Past slices read full,
/// future ones washed out, and the current one fills from its leading edge.
/// Only the bar's outer ends are rounded — the slices are square and abut. Ring
/// splits them with hairline seams showing the background through; flood, whose
/// slices are all one colour on a bright ground, paints darker dividers on top.
struct SegmentBar: View {
    var segments: [Segment]
    /// Index of the running segment.
    var index: Int
    /// Fraction of the current segment already elapsed (0–1).
    var elapsedFraction: Double
    /// Flood draws in white over the interval ground; ring draws in the segment colors.
    var flood: Bool
    var height: CGFloat = 10

    private let dividerWidth: CGFloat = 2

    var body: some View {
        let total = max(1, segments.reduce(0) { $0 + $1.seconds })
        GeometryReader { geo in
            let gap = flood ? 0 : seamWidth(in: geo.size.width, total: total)
            let available = geo.size.width - gap * CGFloat(max(0, segments.count - 1))
            let widths = segments.map { available * CGFloat($0.seconds) / CGFloat(total) }
            HStack(spacing: gap) {
                ForEach(Array(segments.enumerated()), id: \.offset) { i, segment in
                    slice(track: fill(i, segment, past: false),
                          lit: fill(i, segment, past: true),
                          width: widths[i],
                          litFraction: doneFraction(i))
                }
            }
            .overlay(alignment: .leading) { if flood { dividers(widths) } }
            .clipShape(Capsule())
        }
        .frame(height: height)
    }

    /// One square slice: washed-out track with its leading portion lit.
    private func slice(track: Color, lit: Color, width: CGFloat, litFraction: CGFloat) -> some View {
        Rectangle()
            .fill(track)
            .overlay(alignment: .leading) {
                Rectangle().fill(lit).frame(width: width * litFraction)
            }
            .frame(width: width)
    }

    /// Flood's dividers sit *on* the bar rather than between the slices, so they
    /// never eat into a slice's width — at 353pt (an iPhone 15's bar) a 3s pre-roll
    /// slice is under 4pt, and seams that cost width had to be dropped there.
    /// They're hidden only when the median slice itself gets that thin.
    private func dividers(_ widths: [CGFloat]) -> some View {
        let median = widths.sorted()[widths.count / 2]
        return ZStack(alignment: .leading) {
            if median >= 2 * dividerWidth {
                ForEach(Array(widths.dropLast().indices), id: \.self) { i in
                    Rectangle()
                        .fill(.black.opacity(0.6))
                        .frame(width: dividerWidth)
                        .offset(x: widths[0...i].reduce(0, +) - dividerWidth / 2)
                }
            }
        }
    }

    /// Ring's seams cost slice width, so they're dropped once the slices get thin
    /// enough that the seams would eat them.
    private func seamWidth(in width: CGFloat, total: Int) -> CGFloat {
        guard let shortest = segments.map(\.seconds).min(), width > 0 else { return 0 }
        let seam: CGFloat = 1
        let available = width - seam * CGFloat(max(0, segments.count - 1))
        return available * CGFloat(shortest) / CGFloat(total) >= 2 * seam ? seam : 0
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
