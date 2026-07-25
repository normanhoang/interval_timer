import ActivityKit
import WidgetKit
import SwiftUI

struct RunLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RunActivityAttributes.self) { context in
            LockScreenView(state: context.state, name: context.attributes.workoutName)
                .activityBackgroundTint(Color.black.opacity(0.55))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let s = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(s.label).font(.system(size: 16, weight: .semibold)).lineLimit(1)
                    } icon: {
                        Circle().fill(Color(hex: s.colorHex)).frame(width: 12, height: 12)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if s.round > 0 {
                        Text("R\(s.round)/\(s.rounds)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        countdown(s, font: .system(size: 38, weight: .bold, design: .rounded),
                                  alignment: .leading)
                            .foregroundStyle(Color(hex: s.colorHex))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        segmentProgress(s)
                        nextLine(s)
                    }
                }
            } compactLeading: {
                Circle().fill(Color(hex: s.colorHex)).frame(width: 12, height: 12)
            } compactTrailing: {
                countdown(s, font: .system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: s.colorHex))
                    .frame(maxWidth: 44)
            } minimal: {
                Circle().fill(Color(hex: s.colorHex)).frame(width: 12, height: 12)
            }
            .keylineTint(Color(hex: s.colorHex))
        }
    }
}

private struct LockScreenView: View {
    let state: RunActivityAttributes.ContentState
    let name: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Circle().fill(Color(hex: state.colorHex)).frame(width: 14, height: 14)
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.label).font(.system(size: 17, weight: .semibold)).lineLimit(1)
                    Text(subtitle).font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.55)).lineLimit(1)
                }
                Spacer()
                countdown(state, font: .system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(state.frozenRemaining == nil
                                     ? Color(hex: state.colorHex) : .white.opacity(0.6))
            }
            if state.frozenRemaining == nil {
                segmentProgress(state)
                nextLine(state)
            } else {
                Text("Paused").font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .padding()
    }

    private var subtitle: String {
        state.round > 0 ? "Round \(state.round) of \(state.rounds) · \(name)" : name
    }
}

/// Segment progress, rendered by the OS from the segment's date range.
@ViewBuilder
private func segmentProgress(_ s: RunActivityAttributes.ContentState) -> some View {
    ProgressView(timerInterval: s.segmentStart...s.segmentEnd, countsDown: false) {
        EmptyView()
    } currentValueLabel: { EmptyView() }
    .tint(Color(hex: s.colorHex))
}

/// Next-up on the left, whole-workout remainder on the right.
@ViewBuilder
private func nextLine(_ s: RunActivityAttributes.ContentState) -> some View {
    HStack(spacing: 6) {
        if let label = s.nextLabel {
            Circle().fill(Color(hex: s.nextColorHex ?? "#FFFFFF")).frame(width: 7, height: 7)
            Text("Next: \(label)\(s.nextSeconds.map { " · " + mmss(Double($0)) } ?? "")")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
        }
        Spacer(minLength: 4)
        if let total = s.totalRemaining {
            Text("\(mmss(Double(total))) left")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.45))
                .lineLimit(1)
                .fixedSize()
        }
    }
    .padding(.trailing, 6)
}

/// Ticking countdown while running; static clock while paused.
@ViewBuilder
private func countdown(_ s: RunActivityAttributes.ContentState, font: Font,
                       alignment: TextAlignment = .trailing) -> some View {
    if let frozen = s.frozenRemaining {
        Text(mmss(frozen)).font(font).monospacedDigit().multilineTextAlignment(alignment)
    } else {
        Text(timerInterval: s.segmentStart...s.segmentEnd, countsDown: true)
            .font(font).monospacedDigit().multilineTextAlignment(alignment)
    }
}

private func mmss(_ total: Double) -> String {
    let t = max(0, Int(total.rounded()))
    return String(format: "%d:%02d", t / 60, t % 60)
}
