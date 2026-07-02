import SwiftUI
import SwiftData

struct WorkoutsScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @Query(sort: \Workout.order) private var workouts: [Workout]

    @State private var editorTarget: EditorTarget?
    @State private var runTarget: Workout?
    @State private var showSettings = false

    var body: some View {
        let theme = ThemeColors.for(scheme)
        NavigationStack {
            VStack(spacing: 0) {
                header(theme)
                if workouts.isEmpty {
                    emptyState(theme)
                    Spacer()
                } else {
                    list
                }
            }
            .appBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(item: $editorTarget) { target in
            WorkoutEditorScreen(target: target)
        }
        .sheet(isPresented: $showSettings) {
            SettingsScreen()
        }
        .fullScreenCover(item: $runTarget) { workout in
            RunScreen(workout: workout)
        }
    }

    private func header(_ theme: ThemeColors) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("INTERVAL PULSE TIMER")
                    .font(.caption.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(theme.ink.opacity(0.4))
                Text("Workouts")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(theme.ink)
            }
            Spacer()
            HStack(spacing: 8) {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 17))
                        .foregroundStyle(theme.ink)
                        .frame(width: 44, height: 44)
                        .glassChrome(radius: 22)
                }
                Button { editorTarget = .new } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("New").fontWeight(.semibold)
                    }
                    .foregroundStyle(theme.ink)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .glassChrome(radius: 22)
                }
            }
            .buttonStyle(.pressableScale)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    private var list: some View {
        List {
            ForEach(workouts) { workout in
                WorkoutCard(workout: workout) { runTarget = workout }
                    .contentShape(Rectangle())
                    .onTapGesture { editorTarget = .edit(workout) }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 24, bottom: 6, trailing: 24))
            }
            .onMove(perform: move)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 0)
        .contentMargins(.bottom, 72, for: .scrollContent)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { EditButton() } }
    }

    private func emptyState(_ theme: ThemeColors) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "bolt.slash")
                .font(.system(size: 26))
                .foregroundStyle(theme.inkMuted)
                .frame(width: 56, height: 56)
                .background(Circle().fill(theme.glassFill))
            Text("No workouts yet")
                .font(.body.weight(.medium))
                .foregroundStyle(theme.ink.opacity(0.6))
            Text("Tap “New” to build your first interval workout.")
                .font(.subheadline)
                .foregroundStyle(theme.ink.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .panel()
        .padding(.horizontal, 24)
        .padding(.top, 40)
    }

    private func move(_ offsets: IndexSet, _ destination: Int) {
        var ordered = workouts
        ordered.move(fromOffsets: offsets, toOffset: destination)
        for (i, workout) in ordered.enumerated() { workout.order = i }
        try? context.save()
    }
}

private struct WorkoutCard: View {
    let workout: Workout
    let onPlay: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let theme = ThemeColors.for(scheme)
        let total = TimerEngineMath.totalDuration(intervals: workout.intervals, repeats: workout.repeats)
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(theme.ink)
                    Text("\(TimerEngineMath.formatSeconds(total)) · \(workout.repeats) \(workout.repeats == 1 ? "round" : "rounds")")
                        .font(.subheadline)
                        .foregroundStyle(theme.ink.opacity(0.5))
                }
                Spacer()
                Button(action: onPlay) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                        .offset(x: 1)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color(hex: Palette.start)))
                }
                .buttonStyle(.pressableScale)
            }
            IntervalMixBar(intervals: workout.intervals)
            FlowChips(intervals: workout.intervals, theme: theme)
        }
        .padding(16)
        .panel()
    }
}

/// Wrapping row of interval label chips.
private struct FlowChips: View {
    let intervals: [Interval]
    let theme: ThemeColors

    var body: some View {
        FlexWrap(spacing: 6) {
            ForEach(intervals) { interval in
                HStack(spacing: 6) {
                    Circle().fill(Color(hex: interval.color)).frame(width: 10, height: 10)
                    Text("\(interval.label) \(TimerEngineMath.formatSeconds(interval.seconds))")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(theme.ink.opacity(0.7))
                }
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Capsule().fill(theme.glassFill))
                .overlay(Capsule().strokeBorder(theme.glassBorder, lineWidth: 1))
            }
        }
    }
}
