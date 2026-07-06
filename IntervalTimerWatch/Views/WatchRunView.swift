import SwiftUI

private let prerollSeconds = 3

/// Condensed watch mirror of the phone RunScreen: a single combined page with
/// controls and timer, same engine, cues, and finish behavior.
struct WatchRunView: View {
    let workout: WorkoutDTO

    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings

    @State private var engine: TimerEngine
    @State private var encouragement = Encouragements.random()
    @State private var recorded = false
    @State private var showEndConfirm = false

    private let segments: [Segment]
    private let totalWorkout: Int

    init(workout: WorkoutDTO) {
        self.workout = workout
        let segs = TimerEngineMath.flattenWorkout(
            intervals: workout.intervals, repeats: workout.repeats, prerollSeconds: prerollSeconds,
            warmupSeconds: workout.warmupSeconds, cooldownSeconds: workout.cooldownSeconds,
            warmupColor: workout.warmupColor, cooldownColor: workout.cooldownColor)
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
                runningPage
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            Cues.shared.initialize()
            WorkoutSessionController.shared.start()
            attachEngineCallbacks()
            engine.start()
            // Warm the phone-audio flag during the pre-roll so the first beep
            // already knows which device should make it.
            WatchSync.shared.sendCue(kind: "status", alertId: "")
        }
        .onDisappear {
            engine.stop()
            Cues.shared.phoneAudioActive = false
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

    // MARK: running page (combined controls + timer)

    private var runningPage: some View {
        @Bindable var settings = settings
        let segment = engine.segment
        let next = segments.indices.contains(engine.index + 1) ? segments[engine.index + 1] : nil

        return VStack(spacing: 4) {
            HStack(spacing: 6) {
                Button { showEndConfirm = true } label: {
                    Text("End").font(.system(size: 13, weight: .semibold))
                }
                .tint(.red)

                Button { settings.soundEnabled.toggle() } label: {
                    Image(systemName: settings.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.system(size: 13))
                }
                .tint(settings.soundEnabled ? .accentColor : .gray)

                Button { paused ? engine.resume() : engine.pause() } label: {
                    Image(systemName: paused ? "play.fill" : "pause.fill")
                        .font(.system(size: 13, weight: .bold))
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: paused || done)) { _ in
                barBlock(segment)
            }

            nextLine(next)

            Text("\(TimerEngineMath.formatSeconds(engine.totalRemaining)) left")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)

            HStack(spacing: 14) {
                Button { engine.skipPrev() } label: {
                    Image(systemName: "backward.end.fill").font(.system(size: 14))
                }
                .accessibilityIdentifier("runPrev")

                Button { engine.skipNext() } label: {
                    Image(systemName: "forward.end.fill").font(.system(size: 14))
                }
                .accessibilityIdentifier("runNext")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 4)
        .padding(.top, 2)
    }

    private func barBlock(_ segment: Segment?) -> some View {
        VStack(spacing: 2) {
            Text(segmentTopLabel(segment))
                .font(.system(size: 9, weight: .semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .frame(minHeight: 11)

            HStack(spacing: 6) {
                LinearProgressBar(progress: 1 - engine.fractionNow(),
                                   color: Color(hex: segment?.color ?? Palette.preroll))
                    .frame(height: 14)
                Text(TimerEngineMath.formatSeconds(engine.remaining))
                    .font(.system(size: 16, weight: .bold))
                    .monospacedDigit()
                    .fixedSize()
            }

            Text(segment?.label ?? "")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private func segmentTopLabel(_ segment: Segment?) -> String {
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
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(.secondary)
        .lineLimit(1)
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
        // Relay each cue to the phone too: when music streams phone→AirPods the
        // watch speaker can't be heard, but the phone can mix the beep in.
        let settings = settings
        engine.onSegmentChange = { index, _ in
            if index > 0 {
                Cues.shared.segmentChange()
                if settings.soundEnabled { WatchSync.shared.sendCue(kind: "segment", alertId: settings.alertSound) }
            }
        }
        engine.onCountdownTick = { _ in
            Cues.shared.countdown()
            if settings.soundEnabled { WatchSync.shared.sendCue(kind: "countdown", alertId: settings.alertSound) }
        }
        engine.onFinish = {
            Cues.shared.finishCue()
            if settings.soundEnabled { WatchSync.shared.sendCue(kind: "finish", alertId: settings.alertSound) }
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
        engine.start()
    }

    private func recordSession() {
        guard !recorded else { return }
        recorded = true
        WatchSync.shared.sendSession(SessionDTO(
            workoutId: workout.uuid, workoutName: workout.name, totalSeconds: totalWorkout))
    }
}
