import SwiftUI
import SwiftData

private let prerollSeconds = 3

struct RunScreen: View {
    let workout: Workout

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @Environment(AppSettings.self) private var settings

    @State private var engine: TimerEngine
    @State private var encouragement = Encouragements.random()
    @State private var pulse: CGFloat = 1
    @State private var recorded = false
    @State private var showEndConfirm = false

    private let segments: [Segment]
    private let totalWorkout: Int
    private let totalAll: Int

    init(workout: Workout) {
        self.workout = workout
        let segs = TimerEngineMath.flattenWorkout(
            intervals: workout.intervals, repeats: workout.repeats, prerollSeconds: prerollSeconds)
        self.segments = segs
        self.totalWorkout = TimerEngineMath.totalDuration(intervals: workout.intervals, repeats: workout.repeats)
        self.totalAll = segs.isEmpty ? 0 : totalWorkout + prerollSeconds
        _engine = State(initialValue: TimerEngine(segments: segs))
    }

    private var done: Bool { engine.phase == .done }
    private var paused: Bool { engine.phase == .paused }

    var body: some View {
        let theme = ThemeColors.for(scheme)
        ZStack {
            AppBackground()
            VStack(spacing: 0) {
                if !done { header(theme) }
                if done { finishView(theme) } else { runningView(theme) }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            Cues.shared.initialize()
            engine.onSegmentChange = { index, _ in if index > 0 { Cues.shared.segmentChange() } }
            engine.onCountdownTick = { _ in Cues.shared.countdown() }
            engine.onFinish = {
                Cues.shared.finishCue()
                recordSession()
            }
            engine.start()
        }
        .onDisappear {
            engine.stop()
            Cues.shared.release()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: engine.remaining) { _, new in
            if engine.phase == .running, new > 0, new <= 3 {
                pulse = 1.08
                withAnimation(.easeOut(duration: 0.34)) { pulse = 1 }
            }
        }
        .confirmationDialog("End workout?", isPresented: $showEndConfirm, titleVisibility: .visible) {
            Button("End", role: .destructive) { dismiss() }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("Progress won't be saved to history.")
        }
    }

    // MARK: header

    private func header(_ theme: ThemeColors) -> some View {
        @Bindable var settings = settings
        return HStack {
            Button { showEndConfirm = true } label: {
                Text("End").fontWeight(.semibold).foregroundStyle(theme.ink)
                    .padding(.horizontal, 16).padding(.vertical, 8).glassChrome(radius: 20)
            }
            Spacer()
            Text(workout.name).font(.body.weight(.semibold))
                .foregroundStyle(theme.ink.opacity(0.6)).lineLimit(1)
            Spacer()
            Button { settings.soundEnabled.toggle() } label: {
                Image(systemName: settings.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(settings.soundEnabled ? theme.ink : theme.inkMuted)
                    .frame(width: 40, height: 40).glassChrome(radius: 20)
            }
        }
        .buttonStyle(.pressableScale)
    }

    // MARK: running

    private func runningView(_ theme: ThemeColors) -> some View {
        let segment = engine.segment
        let next = segments.indices.contains(engine.index + 1) ? segments[engine.index + 1] : nil
        return VStack(spacing: 0) {
            Spacer()
            ProgressRing(size: 320, strokeWidth: 16, progress: engine.fraction,
                         color: Color(hex: segment?.color ?? Palette.preroll)) {
                VStack(spacing: 6) {
                    Text(ringTopLabel(segment))
                        .font(.caption.weight(.semibold)).tracking(2).textCase(.uppercase)
                        .foregroundStyle(theme.ink.opacity(0.4))
                    Text(TimerEngineMath.formatSeconds(engine.remaining))
                        .font(.system(size: 72, weight: .bold)).monospacedDigit()
                        .foregroundStyle(theme.ink)
                        .scaleEffect(pulse)
                    Text(segment?.label ?? "")
                        .font(.title3.weight(.semibold)).foregroundStyle(theme.ink.opacity(0.6))
                }
            }
            nextPill(next, theme).padding(.top, 24)
            Spacer()
            progressBar(theme).padding(.bottom, 24)
            controls(theme)
        }
    }

    private func ringTopLabel(_ segment: Segment?) -> String {
        if paused { return "Paused" }
        if let segment, segment.round > 0 { return "Round \(segment.round)/\(segment.rounds)" }
        return ""
    }

    private func nextPill(_ next: Segment?, _ theme: ThemeColors) -> some View {
        HStack(spacing: 8) {
            if let next {
                Circle().fill(Color(hex: next.color)).frame(width: 10, height: 10)
                Text("Next: \(next.label) · \(TimerEngineMath.formatSeconds(next.seconds))")
                    .font(.body.weight(.medium)).foregroundStyle(theme.ink.opacity(0.6))
            } else {
                Text("Last interval").font(.body.weight(.medium)).foregroundStyle(theme.ink.opacity(0.6))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(Capsule().fill(theme.glassFill))
        .overlay(Capsule().strokeBorder(theme.glassBorder, lineWidth: 1))
    }

    private func progressBar(_ theme: ThemeColors) -> some View {
        let elapsedFraction = totalAll > 0 ? 1 - engine.totalRemaining / Double(totalAll) : 1
        let remainingFraction = max(0, min(1, 1 - elapsedFraction))
        return VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .trailing) {
                    HStack(spacing: 0) {
                        ForEach(Array(segments.enumerated()), id: \.offset) { _, s in
                            Color(hex: s.color)
                                .frame(width: geo.size.width * CGFloat(s.seconds) / CGFloat(max(1, totalAll)))
                        }
                    }
                    Rectangle().fill(theme.dark ? Color.black.opacity(0.4) : Color.white.opacity(0.6))
                        .frame(width: geo.size.width * remainingFraction)
                }
                .clipShape(Capsule())
            }
            .frame(height: 10)
            Text("\(TimerEngineMath.formatSeconds(engine.totalRemaining)) left")
                .font(.caption.weight(.medium)).foregroundStyle(theme.ink.opacity(0.4))
        }
    }

    private func controls(_ theme: ThemeColors) -> some View {
        HStack(spacing: 20) {
            controlButton("backward.end.fill", size: 52, theme) { engine.skipPrev() }
            Button { paused ? engine.resume() : engine.pause() } label: {
                Image(systemName: paused ? "play.fill" : "pause.fill")
                    .font(.system(size: 30)).foregroundStyle(theme.ink)
                    .offset(x: paused ? 2 : 0)
                    .frame(width: 80, height: 80).glassChrome(radius: 40)
            }
            controlButton("forward.end.fill", size: 52, theme) { engine.skipNext() }
        }
        .buttonStyle(.pressableScale)
    }

    private func controlButton(_ icon: String, size: CGFloat, _ theme: ThemeColors, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(theme.ink)
                .frame(width: size, height: size).glassChrome(radius: size / 2)
        }
    }

    // MARK: finish

    private func finishView(_ theme: ThemeColors) -> some View {
        VStack(spacing: 0) {
            Spacer()
            Text("🎉").font(.system(size: 64))
                .frame(width: 96, height: 96)
                .background(
                    Confetti()
                        .frame(width: 700, height: 700)
                        .allowsHitTesting(false)
                )
            Text(encouragement).font(.system(size: 28, weight: .bold))
                .foregroundStyle(theme.ink).multilineTextAlignment(.center).padding(.top, 24)
            Text("\(workout.name) · \(TimerEngineMath.formatSeconds(totalWorkout))")
                .font(.body).foregroundStyle(theme.ink.opacity(0.5)).padding(.top, 12)
            Button { dismiss() } label: {
                Text("Done").font(.title2.weight(.bold)).foregroundStyle(theme.ink)
                    .padding(.horizontal, 48).padding(.vertical, 18).glassChrome(radius: 32)
            }
            .buttonStyle(.pressableScale).padding(.top, 48)
            Spacer()
        }
    }

    private func recordSession() {
        guard !recorded else { return }
        recorded = true
        context.insert(Session(workoutId: workout.uuid, workoutName: workout.name, totalSeconds: totalWorkout))
        try? context.save()
    }
}
