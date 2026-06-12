import { AudioPlayer, createAudioPlayer, setAudioModeAsync } from "expo-audio";
import * as Haptics from "expo-haptics";
import finishSrc from "../assets/sounds/finish.wav";
import tickSrc from "../assets/sounds/tick.wav";
import { ALERT_SOUNDS, DEFAULT_ALERT_ID } from "./alertSounds";

let players: { tick: AudioPlayer; finish: AudioPlayer; alerts: Record<string, AudioPlayer> } | null =
  null;

let soundOn = true;
let hapticsOn = true;
let alertId = DEFAULT_ALERT_ID;

/** Synced from SettingsContext — cue functions check these flags. */
export function configureCues(options: { sound: boolean; haptics: boolean; alertSound: string }) {
  soundOn = options.sound;
  hapticsOn = options.haptics;
  alertId = options.alertSound;
}

export async function initCues() {
  if (players) return;
  try {
    await setAudioModeAsync({ playsInSilentMode: true });
  } catch {
    // web / unsupported — visual timer still works
  }
  const alerts: Record<string, AudioPlayer> = {};
  for (const sound of ALERT_SOUNDS) {
    alerts[sound.id] = createAudioPlayer(sound.src);
  }
  players = {
    tick: createAudioPlayer(tickSrc),
    finish: createAudioPlayer(finishSrc),
    alerts,
  };
}

export function releaseCues() {
  if (!players) return;
  for (const player of [players.tick, players.finish, ...Object.values(players.alerts)]) {
    try {
      player.release();
    } catch {}
  }
  players = null;
}

function replay(player?: AudioPlayer, force = false) {
  if (!player || (!soundOn && !force)) return;
  try {
    player.seekTo(0);
    player.play();
  } catch {}
}

function haptic(fire: () => Promise<void>) {
  if (!hapticsOn) return;
  fire().catch(() => {});
}

/** Settings picker preview — plays regardless of the sound toggle (explicit user action). */
export async function previewAlert(id: string) {
  await initCues();
  replay(players?.alerts[id], true);
}

export function cueCountdown() {
  replay(players?.tick);
  haptic(() => Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light));
}

export function cueSegmentChange() {
  replay(players?.alerts[alertId] ?? players?.alerts[DEFAULT_ALERT_ID]);
  haptic(() => Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium));
}

export function cueFinish() {
  replay(players?.finish);
  haptic(() => Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success));
}
