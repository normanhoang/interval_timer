// Selectable interval-change alert sounds. Static require()s so Metro bundles them.
export interface AlertSound {
  id: string;
  label: string;
  src: number;
}

export const ALERT_SOUNDS: AlertSound[] = [
  { id: "beep", label: "Beep", src: require("../assets/sounds/alert-beep.wav") },
  { id: "chime", label: "Chime", src: require("../assets/sounds/alert-chime.wav") },
  { id: "bell", label: "Bell", src: require("../assets/sounds/alert-bell.wav") },
  { id: "ding", label: "Ding", src: require("../assets/sounds/alert-ding.wav") },
  { id: "pulse", label: "Pulse", src: require("../assets/sounds/alert-pulse.wav") },
];

export const DEFAULT_ALERT_ID = "beep";
