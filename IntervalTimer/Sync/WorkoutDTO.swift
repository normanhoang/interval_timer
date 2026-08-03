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

/// Wire format for a finished watch run sent watch → phone. WatchConnectivity
/// only accepts property-list values, so the whole struct travels as one JSON
/// `Data` blob — the same encoding the outbox persists.
struct SessionDTO: Codable {
    var uuid: UUID
    var workoutId: UUID
    var workoutName: String
    var totalSeconds: Int
    var completedAt: Date
    var completedIntervals: Int?
    var totalIntervals: Int?
    var pauseCount: Int?
    var workoutIntervals: [Interval]?
    var workoutRepeats: Int?

    init(uuid: UUID = UUID(), workoutId: UUID, workoutName: String,
         totalSeconds: Int, completedAt: Date = .now,
         completedIntervals: Int? = nil, totalIntervals: Int? = nil, pauseCount: Int? = nil,
         workoutIntervals: [Interval]? = nil, workoutRepeats: Int? = nil) {
        self.uuid = uuid
        self.workoutId = workoutId
        self.workoutName = workoutName
        self.totalSeconds = totalSeconds
        self.completedAt = completedAt
        self.completedIntervals = completedIntervals
        self.totalIntervals = totalIntervals
        self.pauseCount = pauseCount
        self.workoutIntervals = workoutIntervals
        self.workoutRepeats = workoutRepeats
    }

    func toDictionary() -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self) else { return [:] }
        return [SyncKeys.sessionPayload: data]
    }

    init?(userInfo: [String: Any]) {
        if let data = userInfo[SyncKeys.sessionPayload] as? Data,
           let dto = try? JSONDecoder().decode(SessionDTO.self, from: data) {
            self = dto
        } else if let legacy = SessionDTO(legacyUserInfo: userInfo) {
            self = legacy
        } else {
            return nil
        }
    }

    /// Pre-1.8 field-per-key payload. Still readable so a transfer queued by an
    /// older watch build survives the update that changed the wire format.
    private init?(legacyUserInfo userInfo: [String: Any]) {
        guard let uuidString = userInfo[SyncKeys.Legacy.sessionUUID] as? String,
              let uuid = UUID(uuidString: uuidString),
              let workoutIdString = userInfo[SyncKeys.Legacy.sessionWorkoutId] as? String,
              let workoutId = UUID(uuidString: workoutIdString),
              let workoutName = userInfo[SyncKeys.Legacy.sessionWorkoutName] as? String,
              let totalSeconds = userInfo[SyncKeys.Legacy.sessionTotalSeconds] as? Int,
              let completedAt = userInfo[SyncKeys.Legacy.sessionCompletedAt] as? Date
        else { return nil }
        let workoutIntervals = (userInfo[SyncKeys.Legacy.sessionWorkoutIntervals] as? Data)
            .flatMap { try? JSONDecoder().decode([Interval].self, from: $0) }
        self.init(uuid: uuid, workoutId: workoutId, workoutName: workoutName,
                  totalSeconds: totalSeconds, completedAt: completedAt,
                  completedIntervals: userInfo[SyncKeys.Legacy.sessionCompletedIntervals] as? Int,
                  totalIntervals: userInfo[SyncKeys.Legacy.sessionTotalIntervals] as? Int,
                  pauseCount: userInfo[SyncKeys.Legacy.sessionPauseCount] as? Int,
                  workoutIntervals: workoutIntervals,
                  workoutRepeats: userInfo[SyncKeys.Legacy.sessionWorkoutRepeats] as? Int)
    }
}
