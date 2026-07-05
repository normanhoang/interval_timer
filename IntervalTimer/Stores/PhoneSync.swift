import Foundation
import SwiftData
import WatchConnectivity

/// Phone side of watch sync: mirrors the workout list to the watch
/// (latest-wins snapshot) and receives finished watch runs into History.
final class PhoneSync: NSObject, WCSessionDelegate {
    static let shared = PhoneSync()
    private var container: ModelContainer?

    private override init() {}

    func configure(container: ModelContainer) {
        self.container = container
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Push the full workout list. Called after every mutation; cheap enough
    /// that snapshotting everything beats diffing.
    func pushWorkouts() {
        guard let container, WCSession.isSupported(),
              WCSession.default.activationState == .activated else { return }
        Task { @MainActor in
            let descriptor = FetchDescriptor<Workout>(sortBy: [SortDescriptor(\.order)])
            guard let workouts = try? container.mainContext.fetch(descriptor),
                  let data = try? JSONEncoder().encode(workouts.map(WorkoutDTO.init))
            else { return }
            try? WCSession.default.updateApplicationContext([
                SyncKeys.workoutsPayload: data,
                SyncKeys.payloadRevision: Date(),
            ])
        }
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Fresh watch installs get the list as soon as the channel is up.
        if activationState == .activated { pushWorkouts() }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // User switched to another paired watch — reactivate for it.
        session.activate()
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        ingestSession(userInfo)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        ingestSession(message)
    }

    private func ingestSession(_ payload: [String: Any]) {
        guard let dto = SessionDTO(userInfo: payload), let container else { return }
        Task { @MainActor in
            let context = container.mainContext
            let uuid = dto.uuid
            var descriptor = FetchDescriptor<Session>(predicate: #Predicate { $0.uuid == uuid })
            descriptor.fetchLimit = 1
            if let existing = try? context.fetch(descriptor), !existing.isEmpty { return }
            context.insert(Session(uuid: dto.uuid, workoutId: dto.workoutId,
                                   workoutName: dto.workoutName, totalSeconds: dto.totalSeconds,
                                   completedAt: dto.completedAt))
            try? context.save()
        }
    }
}
