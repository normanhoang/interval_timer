import Foundation
import HealthKit

/// Keeps the app running (so timer cues fire) while the wrist is down during
/// a run. Session only — no HKWorkoutBuilder is attached, so nothing is
/// saved to Health.
final class WorkoutSessionController: NSObject, HKWorkoutSessionDelegate {
    static let shared = WorkoutSessionController()

    private let store = HKHealthStore()
    private var session: HKWorkoutSession?

    private override init() {}

    func start() {
        // Simulator: no wrist-down suspension to fight, and the Health
        // permission sheet would block automated UI runs.
        #if targetEnvironment(simulator)
        return
        #else
        guard HKHealthStore.isHealthDataAvailable() else { return }
        store.requestAuthorization(toShare: [.workoutType()], read: []) { [weak self] granted, _ in
            guard granted, let self, self.session == nil else { return }
            let config = HKWorkoutConfiguration()
            config.activityType = .highIntensityIntervalTraining
            config.locationType = .indoor
            guard let session = try? HKWorkoutSession(healthStore: self.store, configuration: config) else { return }
            session.delegate = self
            self.session = session
            session.startActivity(with: Date())
        }
        #endif
    }

    func end() {
        session?.end()
        session = nil
    }

    // MARK: HKWorkoutSessionDelegate

    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {}

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {}
}
