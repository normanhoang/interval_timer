import SwiftUI

private let prerollSeconds = 3

/// Condensed watch mirror of the phone RunScreen: two horizontally paged
/// screens (controls | timer), same engine, cues, and finish behavior.
struct WatchRunView: View {
    let workout: WorkoutDTO

    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings

    @State private var engine: TimerEngine
    @State private var encouragement = Encouragements.random()
    @State private var recorded = false
    @State private var showEndConfirm = false
    @State private var page = 1

    private let segments: [Segment]
    private let totalWorkout: Int

    init(workout: WorkoutDTO) {
        self.workout = workout
        let segs = TimerEngineMath.flattenWorkout(
            intervals: workout.intervals, repeats: workout.repeats, prerollSeconds: prerollSeconds,
            warmupSeconds: workout.warmupSeconds, cooldownSeconds: workout.cooldownSeconds)
        self.segments = segs
        self.totalWorkout = TimerEngineMath.totalDuration(
            intervals: workout.intervals, repeats: workout.repeats,
            warmupSeconds: workout.warmupSeconds, cooldownSeconds: workout.cooldownSeconds)
        _engine = State(initialValue: TimerEngine(segments: segs))
    }

    private var done: Bool { engine.phase == .done }
    private var paused: Bool { engine.phase == .paused }

    var body: some View {
        Group {
            if done {
                finishView
            } else {
                TabView(selection: $page) {
                    controlsPage.tag(0)
                    timerPage.tag(1)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            Cues.shared.initialize()
            WorkoutSessionController.shared.start()
            attachEngineCallbacks()
            engine.start()
        }
        .onDisappear {
            engine.stop()
            Cues.shared.release()
            WorkoutSessionController.shared.end()
        }
        .confirmationDialog("End workout?", isPresented: $showEndConfirm, titleVisibility: .visible) {
            Button("End", role: .destructive) { dismiss() }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("Progress won't be saved to history.")
        }
    }

    // MARK: timer page

    private var timerPage: some View {
        let segment = engine.segment
        let next = segments.indices.contains(engine.index + 1) ? segments[engine.index + 1] : nil
        return VStack(spacing: 6) {
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: paused || done)) { _ in
                ring(segment)
            }
            nextLine(next)
            Text("\(TimerEngineMath.formatSeconds(engine.totalRemaining)) left")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
        }
    }

    private func ring(_ segment: Segment?) -> some View {
        ProgressRing(size: 118, strokeWidth: 9, progress: engine.fractionNow(),
                     color: Color(hex: segment?.color ?? Palette.preroll)) {
            VStack(spacing: 0) {
                Text(ringTopLabel(segment))
                    .font(.system(size: 10, weight: .semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                Text(TimerEngineMath.formatSeconds(engine.remaining))
                    .font(.system(size: 30, weight: .bold))
                    .monospacedDigit()
                Text(segment?.label ?? "")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: 90)
        }
    }

    private func ringTopLabel(_ segment: Segment?) -> String {
        if paused { return "Paused" }
        if let segment, segment.round > 0 { return "Round \(segment.round)/\(segment.rounds)" }
        return " "
    }

    private func nextLine(_ next: Segment?) -> some View {
        HStack(spacing: 5) {
            if let next {
                Circle().fill(Color(hex: next.color)).frame(width: 6, height: 6)
                Text("Next: \(next.label) · \(TimerEngineMath.formatSeconds(next.seconds))")
            } else {
                Text("Last interval")
            }
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }

    // MARK: controls page

    private var controlsPage: some View {
        @Bindable var settings = settings
        return VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button { showEndConfirm = true } label: {
                    Text("End").fontWeight(.semibold)
                }
                .tint(.red)
                Button { settings.soundEnabled.toggle() } label: {
                    Image(systemName: settings.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                }
                .tint(settings.soundEnabled ? .accentColor : .gray)
            }
            Button { paused ? engine.resume() : engine.pause() } label: {
                Image(systemName: paused ? "play.fill" : "pause.fill")
                    .font(.system(size: 22, weight: .bold))
            }
            HStack(spacing: 10) {
                Button { engine.skipPrev() } label: {
                    Image(systemName: "backward.end.fill")
                }
                .accessibilityIdentifier("runPrev")
                Button { engine.skipNext() } label: {
                    Image(systemName: "forward.end.fill")
                }
                .accessibilityIdentifier("runNext")
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: finish

    private var finishView: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("🎉").font(.system(size: 36))
                Text(encouragement)
                    .font(.system(size: 15, weight: .bold))
                    .multilineTextAlignment(.center)
                Text("\(workout.name) · \(TimerEngineMath.formatSeconds(totalWorkout))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("runDone")
                Button {
                    restart()
                } label: {
                    Label("Repeat", systemImage: "arrow.counterclockwise")
                }
            }
        }
    }

    private func attachEngineCallbacks() {
        engine.onSegmentChange = { index, _ in if index > 0 { Cues.shared.segmentChange() } }
        engine.onCountdownTick = { _ in Cues.shared.countdown() }
        engine.onFinish = {
            Cues.shared.finishCue()
            recordSession()
        }
    }

    /// Run the same workout again without leaving the screen (pre-roll included).
    private func restart() {
        engine.stop()
        engine = TimerEngine(segments: segments)
        attachEngineCallbacks()
        recorded = false
        encouragement = Encouragements.random()
        page = 1
        engine.start()
    }

    private func recordSession() {
        guard !recorded else { return }
        recorded = true
        WatchSync.shared.sendSession(SessionDTO(
            workoutId: workout.uuid, workoutName: workout.name, totalSeconds: totalWorkout))
    }
}
