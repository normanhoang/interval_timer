import Foundation
import SwiftData

/// One named, timed, colored interval. Stored inline on a Workout (Codable).
struct Interval: Codable, Identifiable, Hashable {
    var id: UUID
    var label: String
    var seconds: Int
    /// Pastel hex from Palette.intervalColors.
    var color: String

    init(id: UUID = UUID(), label: String, seconds: Int, color: String) {
        self.id = id
        self.label = label
        self.seconds = seconds
        self.color = color
    }
}

@Model
final class Workout {
    @Attribute(.unique) var uuid: UUID
    var name: String
    var intervals: [Interval]
    /// How many times the interval sequence repeats (rounds).
    var repeats: Int
    /// Once-only warm up / cool down seconds; 0 = disabled.
    var warmupSeconds: Int = 0
    var cooldownSeconds: Int = 0
    var warmupColor: String = Palette.warmup
    var cooldownColor: String = Palette.cooldown
    var createdAt: Date
    /// Manual sort position for the Workouts list (SwiftData has no inherent order).
    var order: Int

    init(
        uuid: UUID = UUID(),
        name: String,
        intervals: [Interval],
        repeats: Int,
        warmupSeconds: Int = 0,
        cooldownSeconds: Int = 0,
        warmupColor: String = Palette.warmup,
        cooldownColor: String = Palette.cooldown,
        createdAt: Date = .now,
        order: Int = 0
    ) {
        self.uuid = uuid
        self.name = name
        self.intervals = intervals
        self.repeats = repeats
        self.warmupSeconds = warmupSeconds
        self.cooldownSeconds = cooldownSeconds
        self.warmupColor = warmupColor
        self.cooldownColor = cooldownColor
        self.createdAt = createdAt
        self.order = order
    }
}

@Model
final class Session {
    @Attribute(.unique) var uuid: UUID
    var workoutId: UUID
    var workoutName: String
    var totalSeconds: Int
    var completedAt: Date

    init(
        uuid: UUID = UUID(),
        workoutId: UUID,
        workoutName: String,
        totalSeconds: Int,
        completedAt: Date = .now
    ) {
        self.uuid = uuid
        self.workoutId = workoutId
        self.workoutName = workoutName
        self.totalSeconds = totalSeconds
        self.completedAt = completedAt
    }
}
