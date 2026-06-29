import Foundation
import Observation

enum TimerPhase { case running, paused, done }

/// Timestamp-based interval engine (port of RN lib/useIntervalTimer.ts).
/// Elapsed is always recomputed from wall-clock minus accumulated pause time,
/// so pauses and stalls never accumulate drift. A 100ms timer only triggers sync().
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

    private var startedAt = Date()
    private var pausedAccum: TimeInterval = 0
    private var pausedAt: Date?
    private var lastIndex = 0
    private var lastWhole = 0
    private var finished = false
    private var ticker: Timer?

    init(segments: [Segment]) {
        self.segments = segments
        self.total = TimerEngineMath.totalOfSegments(segments)
        self.remaining = segments.first?.seconds ?? 0
        self.lastWhole = segments.first?.seconds ?? 0
        self.totalRemaining = Double(total)
    }

    func start() {
        startedAt = Date()
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
    }

    private func elapsedNow() -> Double {
        let pausedMs = pausedAccum + (pausedAt.map { Date().timeIntervalSince($0) } ?? 0)
        return Date().timeIntervalSince(startedAt) - pausedMs
    }

    private func sync() {
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
        index = pos.index
        remaining = whole
        fraction = pos.remaining / Double(seg.seconds)
        totalRemaining = max(0, Double(total) - elapsed)
    }

    private func setElapsed(_ seconds: Double) {
        let pausedMs = pausedAccum + (pausedAt.map { Date().timeIntervalSince($0) } ?? 0)
        startedAt = Date().addingTimeInterval(-pausedMs - seconds)
        sync()
    }

    func pause() {
        guard phase == .running else { return }
        pausedAt = Date()
        phase = .paused
    }

    func resume() {
        guard phase == .paused else { return }
        if let pausedAt {
            pausedAccum += Date().timeIntervalSince(pausedAt)
            self.pausedAt = nil
        }
        phase = .running
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
