import SwiftUI
import SwiftData

private let prerollSeconds = 3

struct RunScreen: View {
    let workout: Workout

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(AppSettings.self) private var settings
    @Query private var sessions: [Session]

    @State private var engine: TimerEngine
    @State private var encouragement = Encouragements.random()
    @State private var pulse: CGFloat = 1
    @State private var recorded = false
    @State private var showEndConfirm = false
    @State private var pauseCount = 0

    private let segments: [Segment]
    private let totalWorkout: Int
    private let totalAll: Int

    init(workout: Workout) {
        self.workout = workout
        let segs = TimerEngineMath.flattenWorkout(
            intervals: workout.intervals, repeats: workout.repeats, prerollSeconds: prerollSeconds,
            warmupSeconds: workout.warmupSeconds, cooldownSeconds: workout.cooldownSeconds,
            warmupColor: workout.warmupColor, cooldownColor: workout.cooldownColor)
        self.segments = segs
        self.totalWorkout = TimerEngineMath.totalDuration(
            intervals: workout.intervals, repeats: workout.repeats,
            warmupSeconds: workout.warmupSeconds, cooldownSeconds: workout.cooldownSeconds)
        self.totalAll = segs.isEmpty ? 0 : totalWorkout + prerollSeconds
        _engine = State(initialValue: TimerEngine(segments: segs))
    }

    private var done: Bool { engine.phase == .done }
    private var paused: Bool { engine.phase == .paused }
    /// Flood fills the screen with the interval color; ring keeps the app gradient.
    private var flood: Bool { settings.runStyle == .flood && !done }
    private var segmentColor: String { engine.segment?.color ?? Palette.preroll }
    /// Repeated intervals only — the pre-roll, warm up and cool down aren't counted.
    private var intervalCount: Int { segments.filter { $0.intervalIndex >= 0 }.count }

    var body: some View {
        let theme = ThemeColors.for(scheme)
        ZStack {
            if flood { floodBackground } else { AppBackground() }
            VStack(spacing: 0) {
                if !done { header(theme) }
                if done {
                    finishView(theme)
                } else {
                    TimelineView(.animation(minimumInterval: 1.0 / 60, paused: paused)) { _ in
                        if flood { floodRun(theme) } else { ringRun(theme) }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            Cues.shared.initialize()
            Cues.shared.keepAwake(true)
            attachEngineCallbacks()
            engine.start()
            startLive()
        }
        .onDisappear {
            engine.stop()
            Cues.shared.keepAwake(false)
            Cues.shared.release()
            RunLiveActivityController.shared.end()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: engine.remaining) { _, new in
            if !reduceMotion, engine.phase == .running, new > 0, new <= 3 {
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

    // MARK: flood ground

    /// The interval's color as the whole background; cross-fades on segment change.
    private var floodBackground: some View {
        ZStack {
            LinearGradient(
                stops: zip(Palette.floodStops(segmentColor), [0.0, 0.62, 1.0]).map {
                    Gradient.Stop(color: $0, location: $1)
                },
                startPoint: UnitPoint(x: 0.54, y: 0),
                endPoint: UnitPoint(x: 0.46, y: 1))
            .id(segmentColor)
            .transition(.opacity)
        }
        .ignoresSafeArea()
        .animation(.easeOut(duration: 0.3), value: segmentColor)
    }

    // MARK: header

    private func header(_ theme: ThemeColors) -> some View {
        @Bindable var settings = settings
        let fg: Color = flood ? .white : theme.ink
        return HStack {
            Button { showEndConfirm = true } label: {
                Text("End").font(.system(size: 16, weight: .semibold)).foregroundStyle(fg)
                    .padding(.horizontal, 20).frame(height: 40)
                    .floodChrome(flood, radius: 20)
            }
            Spacer()
            Text(workout.name).font(.system(size: 16, weight: .semibold))
                .foregroundStyle(fg.opacity(flood ? 0.9 : 0.6)).lineLimit(1)
            Spacer()
            Button { settings.soundEnabled.toggle() } label: {
                Image(systemName: settings.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(settings.soundEnabled ? fg : fg.opacity(0.5))
                    .frame(width: 40, height: 40)
                    .floodChrome(flood, radius: 20)
            }
        }
        .buttonStyle(.pressableScale)
    }

    // MARK: run — flood

    private func floodRun(_ theme: ThemeColors) -> some View {
        let segment = engine.segment
        let next = segments.indices.contains(engine.index + 1) ? segments[engine.index + 1] : nil
        return VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 0) {
                if let round = roundLine(segment) {
                    Text(round)
                        .font(.system(size: 13, weight: .semibold)).tracking(3)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.bottom, 10)
                }
                Text(TimerEngineMath.formatSeconds(engine.remaining))
                    .font(.system(size: 132, weight: .bold)).tracking(-4).monospacedDigit()
                    .minimumScaleFactor(0.5).lineLimit(1)
                    .foregroundStyle(.white)
                    .scaleEffect(pulse)
                Text(segment?.label ?? "")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.top, 4)
                if let state = stateLabel(segment) {
                    Text(state)
                        .font(.system(size: 13, weight: .bold)).tracking(2)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16).padding(.vertical, 7)
                        .background(Capsule().fill(.white.opacity(0.18)))
                        .padding(.top, 14)
                }
                nextPill(next, fill: .black.opacity(0.24), fg: .white).padding(.top, 26)
            }
            Spacer()
            SegmentBar(segments: segments, index: engine.index,
                       elapsedFraction: 1 - engine.fractionNow(), flood: true)
            HStack {
                Text("\(TimerEngineMath.formatSeconds(engine.totalRemaining)) left")
                Spacer()
                if let round = engine.segment, round.round > 0 {
                    Text("Round \(round.round) of \(round.rounds)")
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.top, 10)
            floodControls().padding(.top, 22)
        }
    }

    private func floodControls() -> some View {
        HStack(spacing: 20) {
            skipButton("backward.end.fill", size: 64, fill: .black.opacity(0.22), fg: .white) {
                engine.skipPrev(); updateLive()
            }
            Button {
                togglePause()
            } label: {
                Image(systemName: paused ? "play.fill" : "pause.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Palette.floodDeep(segmentColor))
                    .offset(x: paused ? 3 : 0)
                    .frame(width: 92, height: 92)
                    .background(Circle().fill(.white))
            }
            skipButton("forward.end.fill", size: 64, fill: .black.opacity(0.22), fg: .white) {
                engine.skipNext(); updateLive()
            }
            .accessibilityIdentifier("skipNext")
        }
        .buttonStyle(.pressableScale)
    }

    // MARK: run — ring

    private func ringRun(_ theme: ThemeColors) -> some View {
        let segment = engine.segment
        let next = segments.indices.contains(engine.index + 1) ? segments[engine.index + 1] : nil
        let color = theme.dark ? Color(hex: segmentColor) : Palette.darkStep(segmentColor)
        return VStack(spacing: 0) {
            Spacer()
            ProgressRing(size: 310, strokeWidth: 16, progress: engine.fractionNow(),
                         color: Color(hex: segmentColor)) {
                VStack(spacing: 2) {
                    Text(roundLine(segment) ?? "")
                        .font(.system(size: 12, weight: .semibold)).tracking(3)
                        .foregroundStyle(theme.inkMuted)
                    Text(TimerEngineMath.formatSeconds(engine.remaining))
                        .font(.system(size: 84, weight: .bold)).monospacedDigit()
                        .minimumScaleFactor(0.5).lineLimit(1)
                        .foregroundStyle(theme.ink)
                        .scaleEffect(pulse)
                    Text(segment?.label ?? "")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(color)
                }
                .padding(.horizontal, 40)
            }
            nextPill(next, fill: theme.cardFill, fg: theme.inkMuted).padding(.top, 28)
            Spacer()
            SegmentBar(segments: segments, index: engine.index,
                       elapsedFraction: 1 - engine.fractionNow(), flood: false, height: 8)
            Text("\(TimerEngineMath.formatSeconds(engine.totalRemaining)) left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(theme.inkMuted)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
            ringControls(theme).padding(.top, 22)
        }
    }

    private func ringControls(_ theme: ThemeColors) -> some View {
        HStack(spacing: 22) {
            skipButton("backward.end.fill", size: 60, fill: nil, fg: theme.ink) {
                engine.skipPrev(); updateLive()
            }
            Button {
                togglePause()
            } label: {
                Image(systemName: paused ? "play.fill" : "pause.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(theme.onAccent)
                    .offset(x: paused ? 3 : 0)
                    .frame(width: 84, height: 84)
                    .background(Circle().fill(theme.accent))
                    .shadow(color: theme.accent.opacity(0.35), radius: 12, y: 6)
            }
            skipButton("forward.end.fill", size: 60, fill: nil, fg: theme.ink) {
                engine.skipNext(); updateLive()
            }
            .accessibilityIdentifier("skipNext")
        }
        .buttonStyle(.pressableScale)
    }

    // MARK: shared run pieces

    /// `ROUND 2 / 8` — hidden for the pre-roll, warm up and cool down (round 0).
    private func roundLine(_ segment: Segment?) -> String? {
        if paused { return "PAUSED" }
        guard let segment, segment.round > 0 else { return nil }
        return "ROUND \(segment.round) / \(segment.rounds)"
    }

    /// WORK / REST chip — only for the two colors that carry a role.
    private func stateLabel(_ segment: Segment?) -> String? {
        switch Palette.role(forColor: segment?.color ?? "") {
        case "Work": return "WORK"
        case "Recovery": return "REST"
        default: return nil
        }
    }

    private func nextPill(_ next: Segment?, fill: Color, fg: Color) -> some View {
        HStack(spacing: 9) {
            if let next {
                Circle().fill(Color(hex: next.color)).frame(width: 9, height: 9)
                Text("Next: \(next.label) · \(TimerEngineMath.formatSeconds(next.seconds))")
                    .font(.system(size: 16, weight: .semibold)).foregroundStyle(fg)
            } else {
                Text("Last interval")
                    .font(.system(size: 16, weight: .semibold)).foregroundStyle(fg)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 11)
        .background(Capsule().fill(fill))
    }

    private func skipButton(_ icon: String, size: CGFloat, fill: Color?, fg: Color,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 20)).foregroundStyle(fg)
                .frame(width: size, height: size)
                .floodChrome(fill != nil, radius: size / 2, fill: fill)
        }
    }

    private func togglePause() {
        if paused {
            engine.resume()
        } else {
            engine.pause()
            pauseCount += 1
        }
        updateLive()
    }

    // MARK: finish

    private func finishView(_ theme: ThemeColors) -> some View {
        let streak = CalendarMath.streakLength(Set(sessions.map { CalendarMath.dayKey($0.completedAt) }))
        let check = theme.dark ? Color(hex: Palette.rest) : Palette.darkStep(Palette.rest)
        return VStack(spacing: 0) {
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(check)
                .frame(width: 84, height: 84)
                .background(Circle().fill(Color(hex: Palette.rest).opacity(0.17)))
                .overlay(Circle().strokeBorder(Color(hex: Palette.rest).opacity(0.55), lineWidth: 1))
                .background(
                    Confetti()
                        .frame(width: 700, height: 700)
                        .allowsHitTesting(false)
                )
            Text(encouragement)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(theme.ink)
                .multilineTextAlignment(.center)
                .padding(.top, 26)
            Text(workout.name)
                .font(.system(size: 16))
                .foregroundStyle(theme.ink.opacity(0.55))
                .padding(.top, 8)
            summaryCard(theme, streak: streak).padding(.top, 26)
            Spacer()
            Button { dismiss() } label: {
                Text("Done").font(.system(size: 17, weight: .bold))
                    .foregroundStyle(theme.onAccent)
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(Capsule().fill(theme.accent))
            }
            .buttonStyle(.pressableScale)
            Button(action: restart) {
                Text("Repeat").font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(theme.ink)
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .glassChrome(radius: 26)
            }
            .buttonStyle(.pressableScale).padding(.top, 10)
        }
    }

    private func summaryCard(_ theme: ThemeColors, streak: Int) -> some View {
        HStack(spacing: 0) {
            summaryStat(theme, value: TimerEngineMath.formatSeconds(totalWorkout), label: "duration")
            Divider().frame(height: 34).opacity(0.4)
            summaryStat(theme, value: "\(intervalCount)/\(intervalCount)", label: "intervals")
            Divider().frame(height: 34).opacity(0.4)
            summaryStat(theme, value: "\(streak)", label: "day streak", arrow: true)
        }
        .padding(.vertical, 18)
        .card()
    }

    private func summaryStat(_ theme: ThemeColors, value: String, label: String, arrow: Bool = false) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text(value).font(.system(size: 20, weight: .bold)).monospacedDigit()
                    .foregroundStyle(theme.ink)
                if arrow {
                    Image(systemName: "arrow.up").font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: Palette.rest))
                }
            }
            Text(label).font(.system(size: 12)).foregroundStyle(theme.inkMuted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Live Activity

    private func liveState(_ index: Int, remaining: Double, running: Bool) -> RunActivityAttributes.ContentState {
        let seg = segments[index]
        let end = Date().addingTimeInterval(remaining)
        let next = segments.indices.contains(index + 1) ? segments[index + 1] : nil
        // Whole-workout remainder at this segment's start, so the card's "left"
        // line stays right without per-second updates.
        let tail = segments[index...].reduce(0) { $0 + $1.seconds }
        return RunActivityAttributes.ContentState(
            label: seg.label, colorHex: seg.color, round: seg.round, rounds: seg.rounds,
            segmentStart: end.addingTimeInterval(-Double(seg.seconds)), segmentEnd: end,
            frozenRemaining: running ? nil : remaining,
            nextLabel: next?.label, nextColorHex: next?.color, nextSeconds: next?.seconds,
            totalRemaining: tail - seg.seconds + Int(remaining.rounded()))
    }

    private func startLive() {
        guard !segments.isEmpty else { return }
        RunLiveActivityController.shared.start(
            workoutName: workout.name,
            state: liveState(0, remaining: Double(segments[0].seconds), running: true))
    }

    /// Reflect the engine's current segment/phase on the Live Activity (pause/resume/skip).
    private func updateLive() {
        guard let seg = engine.segment else { return }
        let remaining = engine.fractionNow() * Double(seg.seconds)
        RunLiveActivityController.shared.update(
            liveState(engine.index, remaining: remaining, running: engine.phase == .running))
    }

    private func attachEngineCallbacks() {
        engine.onSegmentChange = { index, seg in
            if index > 0 { Cues.shared.segmentChange() }
            RunLiveActivityController.shared.update(
                liveState(index, remaining: Double(seg.seconds), running: true))
        }
        engine.onCountdownTick = { _ in Cues.shared.countdown() }
        engine.onFinish = {
            Cues.shared.finishCue()
            RunLiveActivityController.shared.end()
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
        startLive()
    }

    private func recordSession() {
        guard !recorded else { return }
        recorded = true
        context.insert(Session(workoutId: workout.uuid, workoutName: workout.name,
                               totalSeconds: totalWorkout,
                               completedIntervals: intervalCount,
                               totalIntervals: intervalCount,
                               pauseCount: pauseCount))
        try? context.save()
    }
}

private extension View {
    /// Run-screen chrome: a flat translucent fill on the flood ground (glass
    /// disappears against a saturated background), native glass otherwise.
    @ViewBuilder
    func floodChrome(_ flood: Bool, radius: CGFloat, fill: Color? = nil) -> some View {
        if flood {
            background(RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(fill ?? .black.opacity(0.25)))
        } else {
            glassChrome(radius: radius)
        }
    }
}
