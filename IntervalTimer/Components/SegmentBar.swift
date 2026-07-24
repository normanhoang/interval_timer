import SwiftUI

/// Whole-workout progress: one pill, divided into a slice per flattened segment
/// with the slice width proportional to its duration. Past slices read full,
/// future ones washed out, and the current one fills from its leading edge.
/// Only the bar's outer ends are rounded — the slices are square and abut, split
/// by seams showing the trough beneath.
struct SegmentBar: View {
    var segments: [Segment]
    /// Index of the running segment.
    var index: Int
    /// Fraction of the current segment already elapsed (0–1).
    var elapsedFraction: Double
    /// Flood draws in white over the interval ground; ring draws in the segment colors.
    var flood: Bool
    var height: CGFloat = 10

    /// Flood's slices are all one colour, so its seams have to carry the division on
    /// their own: they need the extra width and the darkened trough to read on a
    /// bright ground. Ring's seams fall between differently coloured slices already.
    private var seam: CGFloat { flood ? 2 : 1 }

    var body: some View {
        let total = max(1, segments.reduce(0) { $0 + $1.seconds })
        GeometryReader { geo in
            let gap = seamWidth(in: geo.size.width, total: total)
            let available = geo.size.width - gap * CGFloat(max(0, segments.count - 1))
            HStack(spacing: gap) {
                ForEach(Array(segments.enumerated()), id: \.offset) { i, segment in
                    slice(track: fill(i, segment, past: false),
                          lit: fill(i, segment, past: true),
                          width: available * CGFloat(segment.seconds) / CGFloat(total),
                          litFraction: doneFraction(i))
                }
            }
            .background(flood ? Color.black.opacity(0.45) : .clear)
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

    /// Seams are dropped once the slices get so thin that the seams would eat
    /// them — a 50-round workout then reads as a solid bar split only by color.
    private func seamWidth(in width: CGFloat, total: Int) -> CGFloat {
        guard let shortest = segments.map(\.seconds).min(), width > 0 else { return 0 }
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
