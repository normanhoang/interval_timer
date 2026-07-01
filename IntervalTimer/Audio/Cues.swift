import AVFoundation
import UIKit

/// Sound + haptic cues (mirrors RN lib/cues.ts). Plays in silent mode,
/// mixes with other audio. Players are pooled and replayed via seek-to-zero.
final class Cues {
    static let shared = Cues()

    private var tick: AVAudioPlayer?
    private var finish: AVAudioPlayer?
    private var alerts: [String: AVAudioPlayer] = [:]
    private var ready = false

    private var soundOn = true
    private var hapticsOn = true
    private var alertId = AlertSounds.defaultId

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let notify = UINotificationFeedbackGenerator()

    private init() {}

    /// Synced from Settings — cue functions check these flags.
    func configure(sound: Bool, haptics: Bool, alertSound: String) {
        soundOn = sound
        hapticsOn = haptics
        alertId = alertSound
    }

    func initialize() {
        guard !ready else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        tick = player(named: "tick")
        finish = player(named: "finish")
        for sound in AlertSounds.all {
            alerts[sound.id] = player(named: sound.file)
        }
        lightImpact.prepare()
        mediumImpact.prepare()
        notify.prepare()
        ready = true
    }

    func release() {
        tick = nil
        finish = nil
        alerts.removeAll()
        ready = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func player(named name: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return nil }
        let p = try? AVAudioPlayer(contentsOf: url)
        p?.prepareToPlay()
        return p
    }

    private func replay(_ p: AVAudioPlayer?, force: Bool = false) {
        guard let p, soundOn || force else { return }
        p.currentTime = 0
        p.play()
    }

    /// Settings picker preview — plays regardless of the sound toggle.
    func previewAlert(_ id: String) {
        initialize()
        replay(alerts[id], force: true)
    }

    func countdown() {
        replay(tick)
        if hapticsOn { lightImpact.impactOccurred() }
    }

    func segmentChange() {
        replay(alerts[alertId] ?? alerts[AlertSounds.defaultId])
        if hapticsOn { mediumImpact.impactOccurred() }
    }

    func finishCue() {
        replay(finish)
        if hapticsOn { notify.notificationOccurred(.success) }
    }
}
