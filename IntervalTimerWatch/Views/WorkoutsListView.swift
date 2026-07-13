import SwiftUI

struct WorkoutsListView: View {
    private let store = WorkoutStore.shared

    var body: some View {
        Group {
            if store.workouts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "iphone.and.arrow.forward")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("Create workouts on your iPhone.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                List(store.workouts) { workout in
                    NavigationLink(value: workout) {
                        row(workout)
                    }
                }
            }
        }
        .navigationTitle("Workouts")
        .navigationDestination(for: WorkoutDTO.self) { workout in
            WatchRunView(workout: workout)
        }
    }

    private func row(_ workout: WorkoutDTO) -> some View {
        let total = TimerEngineMath.totalDuration(
            intervals: workout.intervals, repeats: workout.repeats,
            warmupSeconds: workout.warmupSeconds, cooldownSeconds: workout.cooldownSeconds)
        return VStack(alignment: .leading, spacing: 4) {
            Text(workout.name)
                .font(.headline)
                .lineLimit(1)
            HStack(spacing: 6) {
                HStack(spacing: 3) {
                    ForEach(workout.intervals.prefix(6)) { interval in
                        Circle().fill(Color(hex: interval.color)).frame(width: 5, height: 5)
                    }
                }
                Text("\(TimerEngineMath.formatSeconds(total)) · \(workout.repeats)x")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
