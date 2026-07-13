import ActivityKit
import Foundation

/// Manages the run's Live Activity lifecycle. The engine's segment-change callback
/// drives `update`; the OS renders the ticking countdown between updates.
final class RunLiveActivityController {
    static let shared = RunLiveActivityController()
    private init() {}

    private var activity: Activity<RunActivityAttributes>?

    func start(workoutName: String, state: RunActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        endAll()
        activity = try? Activity.request(
            attributes: RunActivityAttributes(workoutName: workoutName),
            content: .init(state: state, staleDate: nil))
    }

    func update(_ state: RunActivityAttributes.ContentState) {
        guard let activity else { return }
        Task { await activity.update(.init(state: state, staleDate: nil)) }
    }

    func end() {
        guard let activity else { return }
        self.activity = nil
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }

    /// Clear our handle plus any activity left over from a previous run/process.
    private func endAll() {
        activity = nil
        for a in Activity<RunActivityAttributes>.activities {
            Task { await a.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
