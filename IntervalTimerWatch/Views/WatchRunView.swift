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
    @State private var pauseCount = 0

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
    private var segmentColor: String { engine.segment?.color ?? Palette.preroll }
    /// Repeated intervals only — pre-roll, warm up and cool down aren't counted.
    private var intervalCount: Int { segments.filter { $0.intervalIndex >= 0 }.count }

    var body: some View {
        ZStack {
            if !done { floodBackground }
            if done { finishView } else { runningPage }
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

        return VStack(spacing: 0) {
            // Four equal spacers: the free width splits into two margins and two
            // gaps, so the trio stays centred and the gaps are half what pushing
            // the buttons to the edges gave — spread enough to be hard to mistap.
            HStack(spacing: 0) {
                Spacer(minLength: 3)
                Button { showEndConfirm = true } label: {
                    Text("End").font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14).frame(height: 34)
                        .background(Capsule().fill(.black.opacity(0.25)))
                }
                Spacer(minLength: 3)
                Button { settings.soundEnabled.toggle() } label: {
                    Image(systemName: settings.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(settings.soundEnabled ? 1 : 0.5))
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(.black.opacity(0.25)))
                }
                Spacer(minLength: 3)
                Button { togglePause() } label: {
                    Image(systemName: paused ? "play.fill" : "pause.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(.black.opacity(0.25)))
                }
                Spacer(minLength: 3)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 2)

            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: paused || done)) { _ in
                centerBlock(segment, next: next)
            }

            Spacer(minLength: 2)

            LinearProgressBar(progress: 1 - engine.fractionNow(),
                              color: .white.opacity(0.95), track: .white.opacity(0.3))
                .frame(height: 7)
                .padding(.horizontal, 6)
            Text("\(TimerEngineMath.formatSeconds(engine.totalRemaining)) left")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.top, 4)

            HStack(spacing: 10) {
                skipPill("backward.end.fill") { engine.skipPrev() }
                    .accessibilityIdentifier("runPrev")
                skipPill("forward.end.fill") { engine.skipNext() }
                    .accessibilityIdentifier("runNext")
            }
            .padding(.top, 6)
        }
        .padding(.horizontal, 4)
        .padding(.top, 10)
    }

    /// Interval color as the whole watch face; cross-fades on segment change.
    private var floodBackground: some View {
        ZStack {
            LinearGradient(
                stops: zip(Palette.floodStops(segmentColor), [0.0, 0.62, 1.0]).map {
                    Gradient.Stop(color: $0, location: $1)
                },
                startPoint: .top, endPoint: .bottom)
            .id(segmentColor)
            .transition(.opacity)
        }
        .ignoresSafeArea()
        .animation(.easeOut(duration: 0.3), value: segmentColor)
    }

    private func skipPill(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 14))
                .foregroundStyle(.white)
                .frame(width: 56, height: 38)
                .background(RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .fill(.black.opacity(0.25)))
        }
        .buttonStyle(.plain)
    }

    private func centerBlock(_ segment: Segment?, next: Segment?) -> some View {
        VStack(spacing: 0) {
            Text(segmentTopLabel(segment))
                .font(.system(size: 11, weight: .bold)).tracking(2)
                .foregroundStyle(.white.opacity(0.7))
            Text(TimerEngineMath.formatSeconds(engine.remaining))
                .font(.system(size: 62, weight: .bold))
                .monospacedDigit().minimumScaleFactor(0.5).lineLimit(1)
                .foregroundStyle(.white)
            Text(segment?.label ?? "")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
            nextLine(next).padding(.top, 6)
        }
    }

    private func togglePause() {
        if paused {
            engine.resume()
        } else {
            engine.pause()
            pauseCount += 1
        }
    }

    private func segmentTopLabel(_ segment: Segment?) -> String {
        if paused { return "PAUSED" }
        if let segment, segment.round > 0 { return "ROUND \(segment.round)/\(segment.rounds)" }
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
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(.white)
        .lineLimit(1)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Capsule().fill(.black.opacity(0.25)))
    }

    // MARK: finish

    private var finishView: some View {
        ScrollView {
            VStack(spacing: 8) {
                Image(systemName: "checkmark")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color(hex: Palette.rest))
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(Color(hex: Palette.rest).opacity(0.17)))
                    .overlay(Circle().strokeBorder(Color(hex: Palette.rest).opacity(0.55), lineWidth: 1))
                Text(encouragement)
                    .font(.system(size: 19, weight: .bold))
                    .multilineTextAlignment(.center)
                Text("\(workout.name) · \(TimerEngineMath.formatSeconds(totalWorkout)) · \(intervalCount)/\(intervalCount)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button { dismiss() } label: {
                    Text("Done").font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color(hex: "#2A2140"))
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .background(Capsule().fill(Color(hex: Palette.primary)))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("runDone")
                Button { restart() } label: {
                    Text("Repeat").font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 40)
                        .background(Capsule().fill(.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
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
        pauseCount = 0
        encouragement = Encouragements.random()
        engine.start()
    }

    private func recordSession() {
        guard !recorded else { return }
        recorded = true
        WatchSync.shared.sendSession(SessionDTO(
            workoutId: workout.uuid, workoutName: workout.name, totalSeconds: totalWorkout,
            completedIntervals: intervalCount, totalIntervals: intervalCount, pauseCount: pauseCount,
            workoutIntervals: workout.intervals, workoutRepeats: workout.repeats))
    }
}
