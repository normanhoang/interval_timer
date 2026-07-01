import SwiftUI
import SwiftData

@main
struct IntervalTimerApp: App {
    @State private var settings = AppSettings()

    let container: ModelContainer = {
        let schema = Schema([Workout.self, Session.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Incompatible store (e.g. a schema change during development) — wipe and retry.
            if let url = config.url as URL? {
                try? FileManager.default.removeItem(at: url)
                try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("store-shm"))
                try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("store-wal"))
            }
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(settings)
                .preferredColorScheme(settings.theme.colorScheme)
                .task { seedIfNeeded(container.mainContext) }
        }
        .modelContainer(container)
    }
}
