import Foundation
import HealthKit

/// Keeps the app running (so timer cues fire) while the wrist is down during
/// a run. Session only — no HKWorkoutBuilder is attached, so nothing is
/// saved to Health.
final class WorkoutSessionController: NSObject, HKWorkoutSessionDelegate {
    static let shared = WorkoutSessionController()

    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    /// False once `end()` has run, so an authorization sheet answered after the
    /// run is over doesn't start a session behind the user's back.
    private var startWanted = false

    private override init() {}

    func start() {
        // Simulator: no wrist-down suspension to fight, and the Health
        // permission sheet would block automated UI runs.
        #if targetEnvironment(simulator)
        return
        #else
        guard HKHealthStore.isHealthDataAvailable() else { return }
        startWanted = true
        store.requestAuthorization(toShare: [.workoutType()], read: []) { [weak self] granted, _ in
            DispatchQueue.main.async {
                guard let self, self.startWanted else { return }
                guard granted, self.session == nil else { return }
                let config = HKWorkoutConfiguration()
                config.activityType = .highIntensityIntervalTraining
                config.locationType = .indoor
                guard let session = try? HKWorkoutSession(
                    healthStore: self.store, configuration: config) else { return }
                session.delegate = self
                self.session = session
                session.startActivity(with: Date())
            }
        }
        #endif
    }

    func end() {
        startWanted = false
        session?.end()
        session = nil
    }

    // MARK: HKWorkoutSessionDelegate

    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        guard toState == .ended else { return }
        DispatchQueue.main.async { [weak self] in
            if self?.session === workoutSession { self?.session = nil }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            if self?.session === workoutSession { self?.session = nil }
        }
    }
}
