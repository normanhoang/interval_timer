// Generates the cue sounds (16-bit mono PCM WAVs) into assets/sounds/.
// Run once: node scripts/generate-beeps.mjs
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const SAMPLE_RATE = 44100;

function tone(freq, durationMs, volume = 0.4, fadeMs = 12) {
  const n = Math.round((durationMs / 1000) * SAMPLE_RATE);
  const fade = Math.round((fadeMs / 1000) * SAMPLE_RATE);
  const samples = new Float32Array(n);
  for (let i = 0; i < n; i++) {
    let v = Math.sin(2 * Math.PI * freq * (i / SAMPLE_RATE)) * volume;
    if (i < fade) v *= i / fade;
    if (i > n - fade) v *= (n - i) / fade;
    samples[i] = v;
  }
  return samples;
}

// Bell-like strike: fundamental + decaying harmonics under an exponential envelope.
function bellTone(freq, durationMs, volume = 0.4, harmonics = [1, 0.5, 0.25], decay = 5) {
  const n = Math.round((durationMs / 1000) * SAMPLE_RATE);
  const attack = Math.round(0.004 * SAMPLE_RATE);
  const samples = new Float32Array(n);
  for (let i = 0; i < n; i++) {
    const t = i / SAMPLE_RATE;
    let v = 0;
    harmonics.forEach((amp, h) => {
      v += amp * Math.sin(2 * Math.PI * freq * (h + 1) * t);
    });
    v *= volume * Math.exp(-decay * t);
    if (i < attack) v *= i / attack;
    samples[i] = v;
  }
  return samples;
}

function silence(ms) {
  return new Float32Array(Math.round((ms / 1000) * SAMPLE_RATE));
}

function concat(...parts) {
  const out = new Float32Array(parts.reduce((s, p) => s + p.length, 0));
  let offset = 0;
  for (const p of parts) {
    out.set(p, offset);
    offset += p.length;
  }
  return out;
}

function toWav(samples) {
  const buf = Buffer.alloc(44 + samples.length * 2);
  buf.write("RIFF", 0);
  buf.writeUInt32LE(36 + samples.length * 2, 4);
  buf.write("WAVE", 8);
  buf.write("fmt ", 12);
  buf.writeUInt32LE(16, 16); // fmt chunk size
  buf.writeUInt16LE(1, 20); // PCM
  buf.writeUInt16LE(1, 22); // mono
  buf.writeUInt32LE(SAMPLE_RATE, 24);
  buf.writeUInt32LE(SAMPLE_RATE * 2, 28); // byte rate
  buf.writeUInt16LE(2, 32); // block align
  buf.writeUInt16LE(16, 34); // bits per sample
  buf.write("data", 36);
  buf.writeUInt32LE(samples.length * 2, 40);
  for (let i = 0; i < samples.length; i++) {
    const v = Math.max(-32768, Math.min(32767, Math.round(samples[i] * 32767)));
    buf.writeInt16LE(v, 44 + i * 2);
  }
  return buf;
}

const outDir = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "assets", "sounds");
fs.mkdirSync(outDir, { recursive: true });

const files = {
  // 3-2-1 countdown tick
  "tick.wav": tone(880, 110),
  // finish: ascending C6-E6-G6 chime
  "finish.wav": concat(tone(1047, 150), silence(30), tone(1319, 150), silence(30), tone(1568, 340)),
  // selectable interval-change alerts
  "alert-beep.wav": concat(tone(1175, 130), silence(40), tone(1568, 180)),
  "alert-chime.wav": concat(tone(1047, 120), silence(20), tone(1319, 120), silence(20), tone(1568, 200)),
  "alert-bell.wav": bellTone(1175, 700, 0.45, [1, 0.6, 0.35, 0.15], 4.5),
  "alert-ding.wav": bellTone(1568, 600, 0.45, [1, 0.3], 3.5),
  "alert-pulse.wav": concat(tone(880, 90, 0.45), silence(70), tone(880, 90, 0.45)),
};

for (const [name, samples] of Object.entries(files)) {
  fs.writeFileSync(path.join(outDir, name), toWav(samples));
  console.log(`wrote assets/sounds/${name}`);
}
