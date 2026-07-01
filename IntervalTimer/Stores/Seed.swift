import Foundation
import SwiftData

/// Inserts two example workouts the first time the app launches with an empty store.
@MainActor
func seedIfNeeded(_ context: ModelContext) {
    let existing = (try? context.fetch(FetchDescriptor<Workout>())) ?? []
    guard existing.isEmpty else { return }

    let now = Date.now
    let tabata = Workout(
        name: "Tabata 20/10",
        intervals: [
            Interval(label: "Work", seconds: 20, color: Palette.work),
            Interval(label: "Rest", seconds: 10, color: Palette.rest),
        ],
        repeats: 8,
        createdAt: now,
        order: 0
    )
    let classic = Workout(
        name: "Classic HIIT 40/20",
        intervals: [
            Interval(label: "Work", seconds: 40, color: Palette.work),
            Interval(label: "Rest", seconds: 20, color: Palette.rest),
        ],
        repeats: 6,
        createdAt: now,
        order: 1
    )
    context.insert(tabata)
    context.insert(classic)
    try? context.save()
}
