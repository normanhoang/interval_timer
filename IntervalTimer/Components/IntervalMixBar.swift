import SwiftUI

/// Proportional stacked color bar — one pill, split into a band per interval with
/// width proportional to its seconds. A workout's visual fingerprint at a glance.
struct IntervalMixBar: View {
    var intervals: [Interval]
    var height: CGFloat = 5

    var body: some View {
        let visible = intervals.filter { $0.seconds > 0 }
        let total = max(1, visible.reduce(0) { $0 + $1.seconds })
        if !visible.isEmpty {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(visible) { interval in
                        Color(hex: interval.color)
                            .frame(width: geo.size.width * CGFloat(interval.seconds) / CGFloat(total))
                    }
                }
                .clipShape(Capsule())
            }
            .frame(height: height)
        }
    }
}
