import SwiftUI

@main
struct IntervalTimerWatchApp: App {
    // Watch-local settings (mute/haptics are per-device by design).
    @State private var settings = AppSettings()

    init() {
        WatchSync.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WorkoutsListView()
            }
            .environment(settings)
        }
    }
}
