import SwiftUI
import SwiftData

/// Opening the on-disk store, with an in-memory stand-in when that fails so the
/// app can present a recovery screen instead of crashing on launch.
struct PersistenceBootstrap {
    let container: ModelContainer
    /// True when `container` is the in-memory stand-in — nothing written to it lasts.
    let failed: Bool

    private static let schema = Schema([Workout.self, Session.self])

    private static func configuration(storeURL: URL?) -> ModelConfiguration {
        if let storeURL {
            ModelConfiguration(schema: schema, url: storeURL)
        } else {
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }
    }

    /// `storeURL` is for tests; the app uses SwiftData's default location.
    static func load(storeURL: URL? = nil) -> PersistenceBootstrap {
        let config = configuration(storeURL: storeURL)
        do {
            return PersistenceBootstrap(
                container: try ModelContainer(for: schema, configurations: [config]),
                failed: false)
        } catch {
            AppLog.persistence.error(
                "Couldn't open the store: \(error.localizedDescription, privacy: .public)")
            return PersistenceBootstrap(container: inMemory(), failed: true)
        }
    }

    /// Destructive: deletes the store and reopens it empty. Only reachable from
    /// the recovery screen, where the alternative is reinstalling the app.
    static func reset(storeURL: URL? = nil) -> PersistenceBootstrap {
        let url = configuration(storeURL: storeURL).url
        for suffix in ["store", "store-shm", "store-wal"] {
            try? FileManager.default.removeItem(
                at: url.deletingPathExtension().appendingPathExtension(suffix))
        }
        return load(storeURL: storeURL)
    }

    private static func inMemory() -> ModelContainer {
        do {
            return try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        } catch {
            fatalError("Failed to create fallback ModelContainer: \(error)")
        }
    }
}

@main
struct IntervalTimerApp: App {
    @State private var settings = AppSettings()
    @State private var bootstrap: PersistenceBootstrap

    init() {
        let bootstrap = PersistenceBootstrap.load()
        _bootstrap = State(initialValue: bootstrap)
        if !bootstrap.failed { Self.startSync(bootstrap.container) }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if bootstrap.failed {
                    StoreRecoveryView(reset: resetStore)
                } else {
                    RootTabView()
                        .task {
                            seedIfNeeded(bootstrap.container.mainContext)
                            PhoneSync.shared.pushWorkouts()
                        }
                }
            }
            .environment(settings)
            .preferredColorScheme(settings.theme.colorScheme)
        }
        .modelContainer(bootstrap.container)
    }

    private static func startSync(_ container: ModelContainer) {
        PhoneSync.shared.configure(container: container)
        PhoneSync.shared.activate()
    }

    private func resetStore() {
        let recovered = PersistenceBootstrap.reset()
        if !recovered.failed { Self.startSync(recovered.container) }
        bootstrap = recovered
    }
}

/// Shown in place of the app when the store can't be opened — the only in-app
/// way out of a store that won't load short of deleting the app.
private struct StoreRecoveryView: View {
    let reset: () -> Void
    @State private var showResetConfirm = false

    var body: some View {
        VStack(spacing: 20) {
            ContentUnavailableView(
                "Workouts unavailable",
                systemImage: "externaldrive.badge.exclamationmark",
                description: Text(
                    "Interval Timer couldn’t open its local data. Your data was left untouched — quit and reopen the app to try again."))
            Button("Reset local data", role: .destructive) { showResetConfirm = true }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .confirmationDialog("Reset local data?", isPresented: $showResetConfirm,
                            titleVisibility: .visible) {
            Button("Delete workouts and history", role: .destructive) { reset() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Every workout and session on this iPhone is deleted. This can't be undone.")
        }
    }
}
