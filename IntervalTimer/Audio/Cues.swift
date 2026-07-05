import AVFoundation
#if os(watchOS)
import WatchKit
#else
import UIKit
#endif

/// Sound + haptic cues (mirrors RN lib/cues.ts). Plays in silent mode,
/// mixes with other audio. Players are pooled and replayed via seek-to-zero.
final class Cues {
    static let shared = Cues()

    // Audio session + players live on `queue` so activation/loading (tens of
    // ms) never blocks the main thread while the run screen animates in.
    private let queue = DispatchQueue(label: "com.normanhoang.intervaltimer.cues", qos: .userInitiated)
    private var tick: AVAudioPlayer?
    private var finish: AVAudioPlayer?
    private var alerts: [String: AVAudioPlayer] = [:]
    private var ready = false

    // Main-thread only (written by Settings, read before hopping to `queue`).
    private var soundOn = true
    private var hapticsOn = true
    private var alertId = AlertSounds.defaultId

    #if !os(watchOS)
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let notify = UINotificationFeedbackGenerator()
    #endif

    private init() {}

    /// Synced from Settings — cue functions check these flags.
    func configure(sound: Bool, haptics: Bool, alertSound: String) {
        soundOn = sound
        hapticsOn = haptics
        alertId = alertSound
    }

    func initialize() {
        #if !os(watchOS)
        lightImpact.prepare()
        mediumImpact.prepare()
        notify.prepare()
        #endif
        queue.async { self.load() }
    }

    /// On `queue`.
    private func load() {
        guard !ready else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        tick = player(named: "tick")
        finish = player(named: "finish")
        for sound in AlertSounds.all {
            alerts[sound.id] = player(named: sound.file)
        }
        ready = true
    }

    func release() {
        queue.async {
            self.tick = nil
            self.finish = nil
            self.alerts.removeAll()
            self.ready = false
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    /// On `queue`.
    private func player(named name: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return nil }
        let p = try? AVAudioPlayer(contentsOf: url)
        p?.prepareToPlay()
        return p
    }

    /// On `queue`.
    private func replay(_ p: AVAudioPlayer?) {
        guard let p else { return }
        p.currentTime = 0
        p.play()
    }

    /// Settings picker preview — plays regardless of the sound toggle.
    func previewAlert(_ id: String) {
        queue.async {
            self.load()
            self.replay(self.alerts[id])
        }
    }

    func countdown() {
        if soundOn { queue.async { self.replay(self.tick) } }
        if hapticsOn {
            #if os(watchOS)
            WKInterfaceDevice.current().play(.click)
            #else
            lightImpact.impactOccurred()
            #endif
        }
    }

    func segmentChange() {
        if soundOn {
            let id = alertId
            queue.async { self.replay(self.alerts[id] ?? self.alerts[AlertSounds.defaultId]) }
        }
        if hapticsOn {
            #if os(watchOS)
            WKInterfaceDevice.current().play(.notification)
            #else
            mediumImpact.impactOccurred()
            #endif
        }
    }

    func finishCue() {
        if soundOn { queue.async { self.replay(self.finish) } }
        if hapticsOn {
            #if os(watchOS)
            WKInterfaceDevice.current().play(.success)
            #else
            notify.notificationOccurred(.success)
            #endif
        }
    }
}
