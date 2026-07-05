import Foundation

/// Keys for the WatchConnectivity payloads exchanged between phone and watch.
enum SyncKeys {
    /// JSON-encoded `[WorkoutDTO]` in the application context (phone → watch).
    static let workoutsPayload = "sync.workouts"
    /// Date stamped on each push so identical workout lists still transmit
    /// (applicationContext skips dictionaries equal to the last one sent).
    static let payloadRevision = "sync.revision"

    // Finished-session userInfo transfer (watch → phone). Plist-safe values only.
    static let sessionUUID = "session.uuid"
    static let sessionWorkoutId = "session.workoutId"
    static let sessionWorkoutName = "session.workoutName"
    static let sessionTotalSeconds = "session.totalSeconds"
    static let sessionCompletedAt = "session.completedAt"
}
