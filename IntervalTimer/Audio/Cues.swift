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
    #if os(iOS)
    // Looping silent audio kept playing while a run is in the background so iOS
    // doesn't suspend the app — the timer keeps firing and beeps stay on-time.
    private var silence: AVAudioPlayer?
    #endif
    private var interruptionObserver: NSObjectProtocol?
    private var routeChangeObserver: NSObjectProtocol?

    // Main-thread only (written by Settings, read before hopping to `queue`).
    private var soundOn = true
    private var hapticsOn = true
    private var alertId = AlertSounds.defaultId

    /// Watch-only (set from cue relay replies): true while the paired iPhone
    /// reports it's playing audio — the relayed beep covers sound there, so
    /// the local speaker stays quiet. Never gates haptics. Unused on iOS.
    var phoneAudioActive = false

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
        activateSession()
        observeSessionChanges()
        tick = player(named: "tick")
        finish = player(named: "finish")
        for sound in AlertSounds.all {
            alerts[sound.id] = player(named: sound.file)
        }
        #if os(iOS)
        silence = player(named: "silence")
        silence?.numberOfLoops = -1
        #endif
        ready = true
    }

    /// On `queue`. Sets the category fresh each time so it survives whatever reset an
    /// interruption, route change, or (on watchOS) a concurrent HKWorkoutSession causes.
    private func activateSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    /// On `queue`. Re-asserts `.mixWithOthers` after anything external touches the shared
    /// audio session, since nothing else in this app would otherwise notice or recover.
    private func observeSessionChanges() {
        guard interruptionObserver == nil else { return }
        let center = NotificationCenter.default
        interruptionObserver = center.addObserver(
            forName: AVAudioSession.interruptionNotification, object: nil, queue: nil
        ) { [weak self] note in
            guard let typeValue = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: typeValue) == .ended else { return }
            self?.queue.async { self?.activateSession() }
        }
        routeChangeObserver = center.addObserver(
            forName: AVAudioSession.routeChangeNotification, object: nil, queue: nil
        ) { [weak self] _ in
            self?.queue.async { self?.activateSession() }
        }
    }

    func release() {
        queue.async {
            self.tick = nil
            self.finish = nil
            self.alerts.removeAll()
            #if os(iOS)
            self.silence?.stop()
            self.silence = nil
            #endif
            self.ready = false
            if let token = self.interruptionObserver {
                NotificationCenter.default.removeObserver(token)
                self.interruptionObserver = nil
            }
            if let token = self.routeChangeObserver {
                NotificationCenter.default.removeObserver(token)
                self.routeChangeObserver = nil
            }
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    #if os(iOS)
    /// Keep the app alive in the background by looping silent audio, so the run's
    /// timer keeps ticking and beeps fire on time even when minimized/locked.
    func keepAwake(_ on: Bool) {
        queue.async {
            self.load()
            if on { self.silence?.play() } else { self.silence?.stop() }
        }
    }
    #endif

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

    /// Cue relayed from a watch-run workout (sound only — the wrist already
    /// haptic'd). Ignores the local sound toggle: the watch checked its own.
    func playRelayedCue(kind: String, alertId: String?) {
        queue.async {
            self.load()
            switch kind {
            case "countdown": self.replay(self.tick)
            case "finish": self.replay(self.finish)
            case "segment": self.replay(self.alerts[alertId ?? ""] ?? self.alerts[AlertSounds.defaultId])
            default: break
            }
        }
    }

    func countdown() {
        if soundOn && !phoneAudioActive { queue.async { self.replay(self.tick) } }
        if hapticsOn {
            #if os(watchOS)
            WKInterfaceDevice.current().play(.click)
            #else
            lightImpact.impactOccurred()
            #endif
        }
    }

    func segmentChange() {
        if soundOn && !phoneAudioActive {
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
        if soundOn && !phoneAudioActive { queue.async { self.replay(self.finish) } }
        if hapticsOn {
            #if os(watchOS)
            WKInterfaceDevice.current().play(.success)
            #else
            notify.notificationOccurred(.success)
            #endif
        }
    }
}
