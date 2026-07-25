import Foundation

/// Wire format for a workout mirrored phone → watch. `Interval` is already
/// Codable and shared, so it rides along as-is.
struct WorkoutDTO: Codable, Identifiable, Hashable {
    var uuid: UUID
    var name: String
    var intervals: [Interval]
    var repeats: Int
    var warmupSeconds: Int
    var cooldownSeconds: Int
    var warmupColor: String
    var cooldownColor: String
    var order: Int

    var id: UUID { uuid }

    init(_ workout: Workout) {
        uuid = workout.uuid
        name = workout.name
        intervals = workout.intervals
        repeats = workout.repeats
        warmupSeconds = workout.warmupSeconds
        cooldownSeconds = workout.cooldownSeconds
        warmupColor = workout.warmupColor
        cooldownColor = workout.cooldownColor
        order = workout.order
    }
}

/// Wire format for a finished watch run sent watch → phone via
/// `transferUserInfo`, which only accepts property-list values.
struct SessionDTO {
    var uuid: UUID
    var workoutId: UUID
    var workoutName: String
    var totalSeconds: Int
    var completedAt: Date
    var completedIntervals: Int?
    var totalIntervals: Int?
    var pauseCount: Int?

    init(uuid: UUID = UUID(), workoutId: UUID, workoutName: String,
         totalSeconds: Int, completedAt: Date = .now,
         completedIntervals: Int? = nil, totalIntervals: Int? = nil, pauseCount: Int? = nil) {
        self.uuid = uuid
        self.workoutId = workoutId
        self.workoutName = workoutName
        self.totalSeconds = totalSeconds
        self.completedAt = completedAt
        self.completedIntervals = completedIntervals
        self.totalIntervals = totalIntervals
        self.pauseCount = pauseCount
    }

    func toDictionary() -> [String: Any] {
        [
            SyncKeys.sessionUUID: uuid.uuidString,
            SyncKeys.sessionWorkoutId: workoutId.uuidString,
            SyncKeys.sessionWorkoutName: workoutName,
            SyncKeys.sessionTotalSeconds: totalSeconds,
            SyncKeys.sessionCompletedAt: completedAt,
            SyncKeys.sessionCompletedIntervals: completedIntervals as Any,
            SyncKeys.sessionTotalIntervals: totalIntervals as Any,
            SyncKeys.sessionPauseCount: pauseCount as Any,
        ].compactMapValues { $0 is NSNull ? nil : $0 }
    }

    init?(userInfo: [String: Any]) {
        guard let uuidString = userInfo[SyncKeys.sessionUUID] as? String,
              let uuid = UUID(uuidString: uuidString),
              let workoutIdString = userInfo[SyncKeys.sessionWorkoutId] as? String,
              let workoutId = UUID(uuidString: workoutIdString),
              let workoutName = userInfo[SyncKeys.sessionWorkoutName] as? String,
              let totalSeconds = userInfo[SyncKeys.sessionTotalSeconds] as? Int,
              let completedAt = userInfo[SyncKeys.sessionCompletedAt] as? Date
        else { return nil }
        self.init(uuid: uuid, workoutId: workoutId, workoutName: workoutName,
                  totalSeconds: totalSeconds, completedAt: completedAt,
                  completedIntervals: userInfo[SyncKeys.sessionCompletedIntervals] as? Int,
                  totalIntervals: userInfo[SyncKeys.sessionTotalIntervals] as? Int,
                  pauseCount: userInfo[SyncKeys.sessionPauseCount] as? Int)
    }
}
