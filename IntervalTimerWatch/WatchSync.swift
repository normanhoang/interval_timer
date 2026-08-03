import Foundation
import WatchConnectivity

/// Watch side of sync: receives the workout list from the phone and queues
/// finished runs back to it.
final class WatchSync: NSObject, WCSessionDelegate {
    static let shared = WatchSync()

    private let outbox = SessionOutbox()
    private let deliveryQueue = DispatchQueue(label: "WatchSync.sessionDelivery")
    private var inFlight: Set<UUID> = []

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
        // Persist before returning to the finish screen so app termination or an
        // inactive WCSession cannot lose a completed run.
        outbox.enqueue(dto)
        flushPendingSessions()
    }

    /// Cue relay: the phone replays the beep into whatever it's outputting
    /// (e.g. AirPods playing music the watch can't mix into) and replies with
    /// whether it's playing audio at all — that flag mutes the watch speaker so
    /// exactly one device beeps. Only worth sending live — a late cue is noise,
    /// so no queued fallback; any failure re-enables the local speaker.
    func sendCue(kind: String, alertId: String) {
        let session = WCSession.default
        guard session.activationState == .activated, session.isReachable else {
            DispatchQueue.main.async { Cues.shared.phoneAudioActive = false }
            return
        }
        session.sendMessage([SyncKeys.cueKind: kind, SyncKeys.cueAlert: alertId]) { reply in
            let active = reply[SyncKeys.cuePhoneAudio] as? Bool ?? false
            DispatchQueue.main.async { Cues.shared.phoneAudioActive = active }
        } errorHandler: { _ in
            DispatchQueue.main.async { Cues.shared.phoneAudioActive = false }
        }
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        guard activationState == .activated else { return }
        // Catches pushes delivered while the watch app wasn't running.
        apply(session.receivedApplicationContext)
        flushPendingSessions()
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        apply(applicationContext)
    }

    /// The phone coming back into range is the cheapest chance to hand over a run
    /// that finished while it was away — without it the queue waits for a relaunch.
    func sessionReachabilityDidChange(_ session: WCSession) {
        guard session.isReachable else { return }
        flushPendingSessions()
    }

    /// `transferUserInfo` only reports here. Until it does, the run stays in the
    /// outbox so a termination mid-transfer still leaves it to retry next launch.
    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer,
                 error: Error?) {
        guard let uuid = SessionDTO(userInfo: userInfoTransfer.userInfo)?.uuid else { return }
        deliveryQueue.async { [weak self] in
            guard let self else { return }
            inFlight.remove(uuid)
            if error == nil { outbox.remove(uuid: uuid) }
        }
    }

    private func apply(_ context: [String: Any]) {
        guard let data = context[SyncKeys.workoutsPayload] as? Data else { return }
        Task { @MainActor in WorkoutStore.shared.replace(with: data) }
    }

    private func flushPendingSessions() {
        deliveryQueue.async { [weak self] in
            guard let self else { return }
            let session = WCSession.default
            guard session.activationState == .activated else { return }
            // Transfers queued by an earlier launch are still WatchConnectivity's
            // to deliver — re-sending them would only duplicate the work.
            let queued = Set(session.outstandingUserInfoTransfers
                .compactMap { SessionDTO(userInfo: $0.userInfo)?.uuid })
            for dto in outbox.pending()
            where !inFlight.contains(dto.uuid) && !queued.contains(dto.uuid) {
                inFlight.insert(dto.uuid)
                if session.isReachable {
                    session.sendMessage(dto.toDictionary()) { [weak self] _ in
                        self?.finishDelivery(dto.uuid)
                    } errorHandler: { [weak self] _ in
                        guard let self else { return }
                        deliveryQueue.async { self.queueTransfer(dto, session: session) }
                    }
                } else {
                    queueTransfer(dto, session: session)
                }
            }
        }
    }

    /// Must be called on `deliveryQueue`. The session stays in the outbox and in
    /// `inFlight` until `didFinish` confirms the transfer.
    private func queueTransfer(_ dto: SessionDTO, session: WCSession) {
        dispatchPrecondition(condition: .onQueue(deliveryQueue))
        inFlight.insert(dto.uuid)
        session.transferUserInfo(dto.toDictionary())
    }

    private func finishDelivery(_ uuid: UUID) {
        deliveryQueue.async { [weak self] in
            self?.inFlight.remove(uuid)
            self?.outbox.remove(uuid: uuid)
        }
    }
}
