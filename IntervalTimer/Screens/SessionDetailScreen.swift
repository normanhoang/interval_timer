import SwiftUI
import SwiftData

/// One finished session, pushed from a History row.
struct SessionDetailScreen: View {
    let session: Session

    @Environment(\.colorScheme) private var scheme
    @Query(sort: \Workout.order) private var workouts: [Workout]

    private var workout: Workout? { workouts.first { $0.uuid == session.workoutId } }
    private var displayIntervals: [Interval]? { session.workoutIntervals ?? workout?.intervals }
    private var displayRepeats: Int? { session.workoutRepeats ?? workout?.repeats }
    private var usesCurrentWorkout: Bool { session.workoutIntervals == nil && workout != nil }

    var body: some View {
        let theme = ThemeColors.for(scheme)
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(session.workoutName)
                        .font(.system(size: 28, weight: .bold)).foregroundStyle(theme.ink)
                    Text(session.completedAt.formatted(date: .complete, time: .shortened))
                        .font(.system(size: 14)).foregroundStyle(theme.inkMuted)
                }
                .padding(.bottom, 4)

                VStack(spacing: 0) {
                    detailRow("Duration", TimerEngineMath.formatSeconds(session.totalSeconds), theme)
                    if let completed = session.completedIntervals, let total = session.totalIntervals {
                        Divider().opacity(0.4).padding(.horizontal, 16)
                        detailRow("Intervals", "\(completed)/\(total)", theme)
                    }
                    if let pauses = session.pauseCount {
                        Divider().opacity(0.4).padding(.horizontal, 16)
                        detailRow("Pauses", "\(pauses)", theme)
                    }
                }
                .card()

                if let intervals = displayIntervals, let repeats = displayRepeats {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(usesCurrentWorkout ? "CURRENT INTERVAL MIX" : "INTERVAL MIX")
                            .font(.system(size: 11, weight: .semibold)).tracking(1.5)
                            .foregroundStyle(theme.inkLabel)
                        IntervalMixBar(intervals: intervals, height: 8)
                        Text("\(repeats) \(repeats == 1 ? "round" : "rounds") · "
                             + intervals.map(\.label).joined(separator: " / "))
                            .font(.system(size: 13)).foregroundStyle(theme.inkMuted)
                        if usesCurrentWorkout {
                            Text("This session predates workout snapshots, so this is the workout’s current setup.")
                                .font(.system(size: 12)).foregroundStyle(theme.inkFaint)
                        }
                    }
                    .padding(16).card()
                } else {
                    Text("This workout has since been deleted.")
                        .font(.system(size: 13)).foregroundStyle(theme.inkMuted)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 40)
        }
        .appBackground()
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailRow(_ label: String, _ value: String, _ theme: ThemeColors) -> some View {
        HStack {
            Text(label).font(.system(size: 16)).foregroundStyle(theme.inkMuted)
            Spacer()
            Text(value).font(.system(size: 16, weight: .semibold)).monospacedDigit()
                .foregroundStyle(theme.ink)
        }
        .padding(16)
    }
}
