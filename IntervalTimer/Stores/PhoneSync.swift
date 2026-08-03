import AVFoundation
import Foundation
import SwiftData
import WatchConnectivity

/// Phone side of watch sync: mirrors the workout list to the watch
/// (latest-wins snapshot) and receives finished watch runs into History.
final class PhoneSync: NSObject, WCSessionDelegate {
    static let shared = PhoneSync()
    private var container: ModelContainer?
    /// Watch runs are held here until they're safely in the store, so a delivery
    /// that arrives before the container exists (or that fails to insert) isn't lost.
    private let inbox = SessionOutbox(storageKey: "sync.pendingIncomingSessions")

    private override init() {}

    func configure(container: ModelContainer) {
        self.container = container
        flushInbox()
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

    /// Cues arrive on this variant (the watch wants to know whether the phone is
    /// playing audio, to decide whether its own speaker should stay quiet). Only
    /// worth beeping here when the phone owns an audio stream the watch can't reach.
    /// Use `secondaryAudioShouldBeSilencedHint` rather than `isOtherAudioPlaying`:
    /// the latter also reports inaudible/mixable background sessions (and is a
    /// false positive with Accessibility → Sound Recognition), which would wrongly
    /// mute the watch and leave only delayed phone beeps.
    func session(_ session: WCSession, didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        if let kind = message[SyncKeys.cueKind] as? String {
            let phoneAudio = AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint
            if phoneAudio, kind != "status" {
                Cues.shared.playRelayedCue(kind: kind, alertId: message[SyncKeys.cueAlert] as? String)
            }
            replyHandler([SyncKeys.cuePhoneAudio: phoneAudio])
            return
        }
        ingestSession(message)
        replyHandler([:])
    }

    private func ingestSession(_ payload: [String: Any]) {
        guard let dto = SessionDTO(userInfo: payload) else { return }
        inbox.enqueue(dto)
        flushInbox()
    }

    private func flushInbox() {
        guard let container else { return }
        Task { @MainActor in
            let context = container.mainContext
            // Read inside the task: an overlapping flush may already have drained
            // entries that were pending when this one was scheduled.
            for dto in inbox.pending() {
                let uuid = dto.uuid
                var descriptor = FetchDescriptor<Session>(predicate: #Predicate { $0.uuid == uuid })
                descriptor.fetchLimit = 1
                do {
                    if try !context.fetch(descriptor).isEmpty {
                        inbox.remove(uuid: uuid)
                        continue
                    }
                    context.insert(Session(uuid: uuid, workoutId: dto.workoutId,
                                           workoutName: dto.workoutName, totalSeconds: dto.totalSeconds,
                                           completedAt: dto.completedAt,
                                           completedIntervals: dto.completedIntervals,
                                           totalIntervals: dto.totalIntervals,
                                           pauseCount: dto.pauseCount,
                                           workoutIntervals: dto.workoutIntervals,
                                           workoutRepeats: dto.workoutRepeats))
                    try context.save()
                    inbox.remove(uuid: uuid)
                } catch {
                    context.rollback()
                    AppLog.watchSync.error(
                        "Failed to ingest watch session: \(error.localizedDescription, privacy: .public)")
                    // The store is unhappy right now (disk full, locked); the rest
                    // of the queue would fail the same way. Keep them for next time.
                    break
                }
            }
        }
    }
}
