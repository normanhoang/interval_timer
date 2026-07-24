import ActivityKit
import Foundation

/// Live Activity payload for a running workout — the lock-screen / Dynamic Island
/// card. `ContentState` is swapped at each interval boundary; the countdown itself
/// ticks on the OS side from `segmentStart…segmentEnd` (no per-second app updates).
struct RunActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var label: String
        var colorHex: String
        /// 1-based round; 0 hides the round line (pre-roll / warm up / cool down).
        var round: Int
        var rounds: Int
        var segmentStart: Date
        var segmentEnd: Date
        /// While paused: seconds frozen on the clock. nil while running (uses the range).
        var frozenRemaining: Double?
        /// Next-up line; nil on the last segment.
        var nextLabel: String?
        var nextColorHex: String?
        var nextSeconds: Int?
        /// Seconds left in the whole workout at `segmentStart`.
        var totalRemaining: Int?

        init(
            label: String,
            colorHex: String,
            round: Int,
            rounds: Int,
            segmentStart: Date,
            segmentEnd: Date,
            frozenRemaining: Double? = nil,
            nextLabel: String? = nil,
            nextColorHex: String? = nil,
            nextSeconds: Int? = nil,
            totalRemaining: Int? = nil
        ) {
            self.label = label
            self.colorHex = colorHex
            self.round = round
            self.rounds = rounds
            self.segmentStart = segmentStart
            self.segmentEnd = segmentEnd
            self.frozenRemaining = frozenRemaining
            self.nextLabel = nextLabel
            self.nextColorHex = nextColorHex
            self.nextSeconds = nextSeconds
            self.totalRemaining = totalRemaining
        }
    }

    var workoutName: String
}
