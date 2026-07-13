import Foundation

/// Keys for the WatchConnectivity payloads exchanged between phone and watch.
enum SyncKeys {
    /// JSON-encoded `[WorkoutDTO]` in the application context (phone → watch).
    static let workoutsPayload = "sync.workouts"
    /// Date stamped on each push so identical workout lists still transmit
    /// (applicationContext skips dictionaries equal to the last one sent).
    static let payloadRevision = "sync.revision"

    // Live cue relay (watch → phone, sendMessage only). The watch can't mix its
    // beeps into audio the phone owns (e.g. music streaming to AirPods), so the
    // phone replays each cue locally where it mixes with that stream.
    static let cueKind = "cue.kind"
    static let cueAlert = "cue.alert"
    /// Bool in the cue reply: whether the phone is currently playing other
    /// audio (watch silences its own speaker while true).
    static let cuePhoneAudio = "cue.phoneAudio"

    // Finished-session userInfo transfer (watch → phone). Plist-safe values only.
    static let sessionUUID = "session.uuid"
    static let sessionWorkoutId = "session.workoutId"
    static let sessionWorkoutName = "session.workoutName"
    static let sessionTotalSeconds = "session.totalSeconds"
    static let sessionCompletedAt = "session.completedAt"
}
