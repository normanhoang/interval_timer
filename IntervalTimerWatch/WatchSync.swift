import Foundation
import WatchConnectivity

/// Watch side of sync: receives the workout list from the phone and queues
/// finished runs back to it.
final class WatchSync: NSObject, WCSessionDelegate {
    static let shared = WatchSync()

    private override init() {}

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Instant message when the phone is reachable, queued transfer otherwise
    /// (survives unreachability and app relaunches). The phone dedupes by
    /// session uuid, so a double delivery is harmless.
    func sendSession(_ dto: SessionDTO) {
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        let payload = dto.toDictionary()
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { _ in
                session.transferUserInfo(payload)
            }
        } else {
            session.transferUserInfo(payload)
        }
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        guard activationState == .activated else { return }
        // Catches pushes delivered while the watch app wasn't running.
        apply(session.receivedApplicationContext)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        apply(applicationContext)
    }

    private func apply(_ context: [String: Any]) {
        guard let data = context[SyncKeys.workoutsPayload] as? Data else { return }
        Task { @MainActor in WorkoutStore.shared.replace(with: data) }
    }
}
