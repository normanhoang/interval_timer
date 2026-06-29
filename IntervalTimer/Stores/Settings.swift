import Foundation
import Observation

/// App settings persisted in UserDefaults (mirrors RN lib/SettingsContext.tsx).
/// Pushes flags into Cues whenever they change.
@Observable
final class AppSettings {
    var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Keys.sound); sync() }
    }
    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.haptics); sync() }
    }
    var alertSound: String {
        didSet { defaults.set(alertSound, forKey: Keys.alert); sync() }
    }
    var theme: ThemeSetting {
        didSet { defaults.set(theme.rawValue, forKey: Keys.theme) }
    }

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let sound = "hiit.soundEnabled"
        static let haptics = "hiit.hapticsEnabled"
        static let alert = "hiit.alertSound"
        static let theme = "hiit.theme"
    }

    init() {
        soundEnabled = defaults.object(forKey: Keys.sound) as? Bool ?? true
        hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
        alertSound = defaults.string(forKey: Keys.alert) ?? AlertSounds.defaultId
        theme = ThemeSetting(rawValue: defaults.string(forKey: Keys.theme) ?? "") ?? .system
        sync()
    }

    private func sync() {
        Cues.shared.configure(sound: soundEnabled, haptics: hapticsEnabled, alertSound: alertSound)
    }
}
