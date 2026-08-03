import Foundation
import OSLog

/// The app's OSLog categories, in one place so every call site logs under the
/// same subsystem.
enum AppLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "IntervalTimer"

    static let persistence = Logger(subsystem: subsystem, category: "Persistence")
    static let watchSync = Logger(subsystem: subsystem, category: "WatchSync")
}
