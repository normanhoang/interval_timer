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
    }

    var workoutName: String
}
