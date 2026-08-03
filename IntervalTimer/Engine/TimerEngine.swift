import Foundation
import Observation

enum TimerPhase: Equatable { case running, paused, done }

/// Timestamp-based interval engine (port of RN lib/useIntervalTimer.ts).
/// Elapsed is always recomputed from a monotonic clock minus accumulated pause
/// time, so pauses and stalls never accumulate drift. A 100ms timer only
/// triggers sync().
@Observable
final class TimerEngine {
    private(set) var phase: TimerPhase = .running
    private(set) var index = 0
    /// Whole seconds left in the current segment.
    private(set) var remaining = 0
    /// Fraction (0–1) of the current segment remaining — drives the ring.
    private(set) var fraction: Double = 1
    private(set) var totalRemaining: Double = 0

    var segment: Segment? { segments.indices.contains(index) ? segments[index] : nil }

    /// Callbacks (set by the view). Fired at most as RN does.
    var onSegmentChange: ((Int, Segment) -> Void)?
    var onCountdownTick: ((Int) -> Void)?
    var onFinish: (() -> Void)?

    private let segments: [Segment]
    private let total: Int
    private let now: () -> TimeInterval

    private var startedAt: TimeInterval
    private var pausedAccum: TimeInterval = 0
    private var pausedAt: TimeInterval?
    private var lastIndex = 0
    private var lastWhole = 0
    private var finished = false
    private var ticker: Timer?

    /// Monotonic *and* sleep-inclusive: CLOCK_MONOTONIC_RAW keeps counting while
    /// the device is asleep (unlike `systemUptime`/CLOCK_UPTIME_RAW, which would
    /// stall a locked run) and is immune to wall-clock adjustments (unlike `Date`).
    /// Matches the wall-clock dates the Live Activity's countdown is built from.
    static func continuousTime() -> TimeInterval {
        Double(clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)) / 1_000_000_000
    }

    init(segments: [Segment], now: @escaping () -> TimeInterval = TimerEngine.continuousTime) {
        self.segments = segments
        self.total = TimerEngineMath.totalOfSegments(segments)
        self.now = now
        self.startedAt = now()
        self.remaining = segments.first?.seconds ?? 0
        self.lastWhole = segments.first?.seconds ?? 0
        self.totalRemaining = Double(total)
    }

    func start() {
        startedAt = now()
        pausedAccum = 0
        pausedAt = nil
        startTicker()
    }

    func stop() {
        ticker?.invalidate()
        ticker = nil
    }

    private func startTicker() {
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.sync()
        }
        ticker?.tolerance = 0.02
    }

    private func elapsedNow() -> Double {
        let current = now()
        let pausedSeconds = pausedAccum + (pausedAt.map { current - $0 } ?? 0)
        return current - startedAt - pausedSeconds
    }

    /// Driven by the 100ms ticker; internal (not private) so tests can step the
    /// injected clock and advance the engine deterministically.
    func sync() {
        let elapsed = elapsedNow()
        let pos = TimerEngineMath.segmentAt(segments, elapsed: elapsed)
        if pos.done {
            index = pos.index
            remaining = 0
            fraction = 0
            totalRemaining = 0
            phase = .done
            stop()
            if !finished {
                finished = true
                onFinish?()
            }
            return
        }
        let seg = segments[pos.index]
        let whole = Int(pos.remaining.rounded(.up))
        if pos.index != lastIndex {
            lastIndex = pos.index
            lastWhole = whole
            onSegmentChange?(pos.index, seg)
        } else if whole != lastWhole {
            lastWhole = whole
            if whole >= 1 && whole <= 3 { onCountdownTick?(whole) }
        }
        // @Observable fires on every set regardless of equality — skip no-op writes.
        if index != pos.index { index = pos.index }
        if remaining != whole { remaining = whole }
        fraction = pos.remaining / Double(seg.seconds)
        totalRemaining = max(0, Double(total) - elapsed)
    }

    /// Frame-rate read for the ring: current segment fraction computed straight
    /// from the timestamp math, independent of the 100ms ticker. Pure read — no
    /// state writes, so it's safe to call from a TimelineView every frame.
    func fractionNow() -> Double {
        guard phase == .running else { return fraction }
        let pos = TimerEngineMath.segmentAt(segments, elapsed: elapsedNow())
        if pos.done { return 0 }
        return pos.remaining / Double(segments[pos.index].seconds)
    }

    private func setElapsed(_ seconds: Double) {
        let current = now()
        let pausedSeconds = pausedAccum + (pausedAt.map { current - $0 } ?? 0)
        startedAt = current - pausedSeconds - seconds
        sync()
    }

    func pause() {
        guard phase == .running else { return }
        pausedAt = now()
        phase = .paused
        // Elapsed is timestamp based, so the ticker can stop while paused
        // (nothing changes) and restart on resume with zero drift.
        stop()
    }

    func resume() {
        guard phase == .paused else { return }
        if let pausedAt {
            pausedAccum += now() - pausedAt
            self.pausedAt = nil
        }
        phase = .running
        startTicker()
        sync()
    }

    func skipNext() {
        guard !finished else { return }
        let nextIndex = lastIndex + 1
        if segments.indices.contains(nextIndex) {
            setElapsed(Double(segments[nextIndex].startsAt))
        } else {
            setElapsed(Double(total))
        }
    }

    func skipPrev() {
        guard !finished, segments.indices.contains(lastIndex) else { return }
        let current = segments[lastIndex]
        let intoCurrent = elapsedNow() - Double(current.startsAt)
        if intoCurrent > 1.5 || lastIndex == 0 {
            setElapsed(Double(current.startsAt))
        } else {
            setElapsed(Double(segments[lastIndex - 1].startsAt))
        }
    }
}
