import Foundation

struct AlertSound: Identifiable {
    let id: String
    let label: String
    /// Bundled resource filename (without extension); all are .wav.
    let file: String
}

enum AlertSounds {
    static let all: [AlertSound] = [
        AlertSound(id: "beep", label: "Beep", file: "alert-beep"),
        AlertSound(id: "chime", label: "Chime", file: "alert-chime"),
        AlertSound(id: "bell", label: "Bell", file: "alert-bell"),
        AlertSound(id: "ding", label: "Ding", file: "alert-ding"),
        AlertSound(id: "pulse", label: "Pulse", file: "alert-pulse"),
    ]

    static let defaultId = "beep"

    static func file(for id: String) -> String {
        all.first { $0.id == id }?.file ?? "alert-beep"
    }
}
