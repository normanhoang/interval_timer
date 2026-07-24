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
        HStack(alignment: .center) {
            Text("Workouts")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(theme.ink)
            Spacer()
            HStack(spacing: 10) {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18))
                        .foregroundStyle(theme.ink)
                        .frame(width: 44, height: 44)
                        .glassChrome(radius: 22)
                }
                .accessibilityIdentifier("settings")
                Button { editorTarget = .new } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus").font(.system(size: 15, weight: .semibold))
                        Text("New").font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundStyle(theme.accentText)
                    .padding(.horizontal, 18)
                    .frame(height: 44)
                    .background(Capsule().fill(theme.accentTint))
                    .overlay(Capsule().strokeBorder(theme.accentTintBorder, lineWidth: 1))
                }
            }
            .buttonStyle(.pressableScale)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    private var list: some View {
        List {
            ForEach(workouts) { workout in
                WorkoutCard(
                    workout: workout,
                    onPlay: { runTarget = workout },
                    onDuplicate: { duplicate(workout) },
                    onEdit: { editorTarget = .edit(workout) },
                    onDelete: { delete(workout) })
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
            }
            .onMove(perform: move)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 0)
        .contentMargins(.bottom, 72, for: .scrollContent)
    }

    private func emptyState(_ theme: ThemeColors) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "bolt.slash")
                .font(.system(size: 26))
                .foregroundStyle(theme.inkMuted)
                .frame(width: 56, height: 56)
                .background(Circle().fill(theme.cardFill))
            Text("No workouts yet")
                .font(.body.weight(.medium))
                .foregroundStyle(theme.ink.opacity(0.6))
            Text("Tap “New” to build your first interval workout.")
                .font(.subheadline)
                .foregroundStyle(theme.inkLabel)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .panel()
        .padding(.horizontal, 20)
        .padding(.top, 40)
    }

    private func move(_ offsets: IndexSet, _ destination: Int) {
        var ordered = workouts
        ordered.move(fromOffsets: offsets, toOffset: destination)
        for (i, workout) in ordered.enumerated() { workout.order = i }
        try? context.save()
        PhoneSync.shared.pushWorkouts()
    }

    /// Overflow-menu action: copy a workout onto the end of the list.
    private func duplicate(_ workout: Workout) {
        let copy = Workout(
            name: "\(workout.name) copy",
            intervals: workout.intervals.map {
                Interval(label: $0.label, seconds: $0.seconds, color: $0.color)
            },
            repeats: workout.repeats,
            warmupSeconds: workout.warmupSeconds,
            cooldownSeconds: workout.cooldownSeconds,
            warmupColor: workout.warmupColor,
            cooldownColor: workout.cooldownColor,
            order: (workouts.map(\.order).max() ?? 0) + 1)
        context.insert(copy)
        try? context.save()
        PhoneSync.shared.pushWorkouts()
    }

    private func delete(_ workout: Workout) {
        context.delete(workout)
        try? context.save()
        PhoneSync.shared.pushWorkouts()
    }
}

private struct WorkoutCard: View {
    let workout: Workout
    let onPlay: () -> Void
    let onDuplicate: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let theme = ThemeColors.for(scheme)
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(workout.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(theme.ink)
                    Text(metaLine)
                        .font(.system(size: 13))
                        .foregroundStyle(theme.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Menu {
                    Button { onDuplicate() } label: { Label("Duplicate", systemImage: "plus.square.on.square") }
                    Button { onEdit() } label: { Label("Edit", systemImage: "pencil") }
                    Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(theme.inkMuted)
                        .frame(width: 30, height: 44)
                        .contentShape(Rectangle())
                }
                Button(action: onPlay) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(theme.onAccent)
                        .offset(x: 1)
                        .frame(width: 48, height: 48)
                        .background(Circle().fill(theme.accent))
                        .shadow(color: theme.accent.opacity(0.35), radius: 9, y: 6)
                }
                .buttonStyle(.pressableScale)
                .accessibilityIdentifier("play")
            }
            IntervalMixBar(intervals: workout.intervals)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .card()
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
    }

    /// `4:00 · 8 rounds · Work 0:20 / Rest 0:10` — or just the exercise names
    /// once there are more than two intervals to list.
    private var metaLine: String {
        let total = TimerEngineMath.totalDuration(
            intervals: workout.intervals, repeats: workout.repeats,
            warmupSeconds: workout.warmupSeconds, cooldownSeconds: workout.cooldownSeconds)
        var parts = [TimerEngineMath.formatSeconds(total),
                     "\(workout.repeats) \(workout.repeats == 1 ? "round" : "rounds")"]
        let visible = workout.intervals.filter { $0.seconds > 0 }
        if visible.count > 2 {
            parts.append(visible.map(\.label).joined(separator: " / "))
        } else if !visible.isEmpty {
            parts.append(visible.map { "\($0.label) \(TimerEngineMath.formatSeconds($0.seconds))" }
                .joined(separator: " / "))
        }
        return parts.joined(separator: " · ")
    }
}
