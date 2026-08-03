import Foundation

/// Durable queue of sessions in transit. The watch holds finished runs here
/// until WatchConnectivity confirms delivery; the phone holds received runs here
/// until they're in the SwiftData store. Safe to touch from any thread.
struct SessionOutbox {
    static let storageKey = "sync.pendingSessions"

    private let defaults: UserDefaults
    private let key: String
    private let lock = NSLock()

    init(defaults: UserDefaults = .standard, storageKey: String = Self.storageKey) {
        self.defaults = defaults
        self.key = storageKey
    }

    func pending() -> [SessionDTO] {
        lock.lock()
        defer { lock.unlock() }
        return load()
    }

    func enqueue(_ dto: SessionDTO) {
        lock.lock()
        defer { lock.unlock() }

        var sessions = load()
        guard !sessions.contains(where: { $0.uuid == dto.uuid }) else { return }
        sessions.append(dto)
        save(sessions)
    }

    func remove(uuid: UUID) {
        lock.lock()
        defer { lock.unlock() }
        save(load().filter { $0.uuid != uuid })
    }

    private func load() -> [SessionDTO] {
        guard let data = defaults.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([SessionDTO].self, from: data)
        } catch {
            // The next enqueue overwrites the blob, so say so loudly: this is the
            // only trace that queued sessions were dropped.
            AppLog.watchSync.error(
                "Discarding unreadable \(key, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    private func save(_ sessions: [SessionDTO]) {
        if sessions.isEmpty {
            defaults.removeObject(forKey: key)
        } else if let data = try? JSONEncoder().encode(sessions) {
            defaults.set(data, forKey: key)
        }
    }
}
