import Foundation

/// One concrete stretch of the timeline (repeats expanded, pre-roll prepended).
struct Segment: Equatable {
    var label: String
    var seconds: Int
    var color: String
    /// 1-based round number; 0 for the pre-roll.
    var round: Int
    var rounds: Int
    /// Index into the workout's interval list; -1 for the pre-roll.
    var intervalIndex: Int
    /// Cumulative seconds from timer start.
    var startsAt: Int
}

struct SegmentPosition {
    var index: Int
    /// Seconds left in the current segment (fractional).
    var remaining: Double
    var done: Bool
}

enum TimerEngineMath {
    /// Expand a workout's intervals over its rounds, optionally prepending a
    /// "Get ready" pre-roll. Warm up / cool down (0 = none) run once — before
    /// round 1 and after the last round. Intervals with seconds <= 0 are skipped.
    static func flattenWorkout(
        intervals: [Interval],
        repeats: Int,
        prerollSeconds: Int = 0,
        warmupSeconds: Int = 0,
        cooldownSeconds: Int = 0,
        warmupColor: String = Palette.warmup,
        cooldownColor: String = Palette.cooldown
    ) -> [Segment] {
        var segments: [Segment] = []
        var t = 0
        func appendOnce(_ label: String, _ seconds: Int, _ color: String) {
            segments.append(Segment(
                label: label,
                seconds: seconds,
                color: color,
                round: 0,
                rounds: repeats,
                intervalIndex: -1,
                startsAt: t
            ))
            t += seconds
        }
        if prerollSeconds > 0 { appendOnce("Get ready", prerollSeconds, Palette.preroll) }
        if warmupSeconds > 0 { appendOnce("Warm up", warmupSeconds, warmupColor) }
        guard repeats >= 1 else { return segments }
        for round in 1...repeats {
            for (intervalIndex, interval) in intervals.enumerated() {
                if interval.seconds <= 0 { continue }
                segments.append(Segment(
                    label: interval.label,
                    seconds: interval.seconds,
                    color: interval.color,
                    round: round,
                    rounds: repeats,
                    intervalIndex: intervalIndex,
                    startsAt: t
                ))
                t += interval.seconds
            }
        }
        if cooldownSeconds > 0 { appendOnce("Cool down", cooldownSeconds, cooldownColor) }
        return segments
    }

    static func totalDuration(
        intervals: [Interval],
        repeats: Int,
        warmupSeconds: Int = 0,
        cooldownSeconds: Int = 0
    ) -> Int {
        repeats * intervals.reduce(0) { $0 + max(0, $1.seconds) }
            + max(0, warmupSeconds) + max(0, cooldownSeconds)
    }

    static func totalOfSegments(_ segments: [Segment]) -> Int {
        guard let last = segments.last else { return 0 }
        return last.startsAt + last.seconds
    }

    /// Elapsed exactly on a segment edge belongs to the next segment.
    static func segmentAt(_ segments: [Segment], elapsed: Double) -> SegmentPosition {
        let total = Double(totalOfSegments(segments))
        if segments.isEmpty || elapsed >= total {
            return SegmentPosition(index: max(0, segments.count - 1), remaining: 0, done: true)
        }
        var index = 0
        for i in 0..<segments.count {
            if elapsed >= Double(segments[i].startsAt) { index = i } else { break }
        }
        let segment = segments[index]
        let remaining = Double(segment.startsAt + segment.seconds) - elapsed
        return SegmentPosition(index: index, remaining: remaining, done: false)
    }

    /// "m:ss" or "h:mm:ss".
    static func formatSeconds(_ total: Double) -> String {
        let t = max(0, Int(total.rounded()))
        let h = t / 3600
        let m = (t % 3600) / 60
        let s = t % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }

    static func formatSeconds(_ total: Int) -> String {
        formatSeconds(Double(total))
    }
}
