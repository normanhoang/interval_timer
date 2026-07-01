import SwiftUI

/// Proportional stacked color bar — one rounded sliver per interval, width
/// proportional to its seconds. A workout's visual fingerprint at a glance.
struct IntervalMixBar: View {
    var intervals: [Interval]
    var height: CGFloat = 6

    var body: some View {
        let visible = intervals.filter { $0.seconds > 0 }
        let total = max(1, visible.reduce(0) { $0 + $1.seconds })
        let gap: CGFloat = 3

        if !visible.isEmpty {
            GeometryReader { geo in
                let available = geo.size.width - gap * CGFloat(max(0, visible.count - 1))
                HStack(spacing: gap) {
                    ForEach(visible) { interval in
                        Color(hex: interval.color)
                            .frame(width: available * CGFloat(interval.seconds) / CGFloat(total))
                            .clipShape(RoundedRectangle(cornerRadius: height / 2, style: .continuous))
                    }
                }
            }
            .frame(height: height)
        }
    }
}
