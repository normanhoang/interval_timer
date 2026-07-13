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
                        Text(s.label).font(.headline).lineLimit(1)
                    } icon: {
                        Circle().fill(Color(hex: s.colorHex)).frame(width: 12, height: 12)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if s.round > 0 {
                        Text("R\(s.round)/\(s.rounds)").font(.headline).foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    countdown(s, font: .system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: s.colorHex))
                }
            } compactLeading: {
                Circle().fill(Color(hex: s.colorHex)).frame(width: 12, height: 12)
            } compactTrailing: {
                countdown(s, font: .caption.bold()).frame(maxWidth: 44)
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
                    Text(state.label).font(.headline).lineLimit(1)
                    Text(state.round > 0 ? "Round \(state.round) of \(state.rounds)" : name)
                        .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer()
                countdown(state, font: .system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: state.colorHex))
            }
            if state.frozenRemaining == nil {
                ProgressView(timerInterval: state.segmentStart...state.segmentEnd, countsDown: false) {
                    EmptyView()
                } currentValueLabel: { EmptyView() }
                .tint(Color(hex: state.colorHex))
            } else {
                Text("Paused").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

/// Ticking countdown while running; static clock while paused.
@ViewBuilder
private func countdown(_ s: RunActivityAttributes.ContentState, font: Font) -> some View {
    if let frozen = s.frozenRemaining {
        Text(mmss(frozen)).font(font).monospacedDigit()
    } else {
        Text(timerInterval: s.segmentStart...s.segmentEnd, countsDown: true)
            .font(font).monospacedDigit().multilineTextAlignment(.trailing)
    }
}

private func mmss(_ total: Double) -> String {
    let t = max(0, Int(total.rounded()))
    return String(format: "%d:%02d", t / 60, t % 60)
}
