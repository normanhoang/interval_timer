import Foundation
import Observation

/// Watch-local cache of the workouts mirrored from the phone. Persisted as
/// JSON so the list is available offline immediately at launch.
@Observable
final class WorkoutStore {
    static let shared = WorkoutStore()

    private(set) var workouts: [WorkoutDTO] = []

    private static var cacheURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("workouts.json")
    }

    private init() {
        if let data = try? Data(contentsOf: Self.cacheURL),
           let dtos = try? JSONDecoder().decode([WorkoutDTO].self, from: data) {
            workouts = dtos.sorted { $0.order < $1.order }
        }
    }

    @MainActor
    func replace(with data: Data) {
        guard let dtos = try? JSONDecoder().decode([WorkoutDTO].self, from: data) else { return }
        workouts = dtos.sorted { $0.order < $1.order }
        try? data.write(to: Self.cacheURL)
    }
}
