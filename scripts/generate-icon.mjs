// Generates all app icon assets into assets/images/ from one SVG design:
// the app's pastel gradient, a segmented interval ring in the six interval
// colors, a frosted glass disc, and the violet play button.
// Run: node scripts/generate-icon.mjs   (requires devDependency `sharp`)
import path from "node:path";
import { fileURLToPath } from "node:url";
import sharp from "sharp";

const SIZE = 1024;
const C = SIZE / 2;

// Keep in sync with lib/colors.ts / tailwind.config.js.
// Exception: the app's pale green (#EAFFD0) vanishes against the frosted
// white disc at icon sizes, so the icon uses a deeper green stand-in.
const GRADIENT = ["#FFF1F2", "#EDE9FE", "#E0F2FE"];
const INTERVAL_COLORS = ["#F38181", "#FCE38A", "#B5E48C", "#95E1D3", "#A8D8EA", "#C9B6E4"];
const PRIMARY = "#A78BFA";

function polar(cx, cy, r, deg) {
  const rad = ((deg - 90) * Math.PI) / 180;
  return [cx + r * Math.cos(rad), cy + r * Math.sin(rad)];
}

function arcPath(cx, cy, r, startDeg, endDeg) {
  const [x0, y0] = polar(cx, cy, r, startDeg);
  const [x1, y1] = polar(cx, cy, r, endDeg);
  const largeArc = endDeg - startDeg > 180 ? 1 : 0;
  return `M ${x0.toFixed(2)} ${y0.toFixed(2)} A ${r} ${r} 0 ${largeArc} 1 ${x1.toFixed(2)} ${y1.toFixed(2)}`;
}

/** Segmented interval ring + play triangle, centered at (512,512). */
function artwork({ mono = false } = {}) {
  const ringR = 305;
  const ringW = 108;
  const segments = INTERVAL_COLORS.length;
  const gapDeg = 22;
  const segDeg = 360 / segments - gapDeg;

  let arcs = "";
  for (let i = 0; i < segments; i++) {
    const start = i * (segDeg + gapDeg);
    const color = mono ? "#FFFFFF" : INTERVAL_COLORS[i];
    arcs += `<path d="${arcPath(C, C, ringR, start, start + segDeg)}" stroke="${color}" stroke-width="${ringW}" stroke-linecap="round" fill="none"/>`;
  }

  // play triangle, optically centered (nudged right); the thick round-join
  // stroke is what rounds the corners — fatter stroke = softer triangle
  const playColor = mono ? "#FFFFFF" : PRIMARY;
  const tri = `M ${C - 50} ${C - 76} L ${C + 88} ${C} L ${C - 50} ${C + 76} Z`;
  const play = `<path d="${tri}" fill="${playColor}" stroke="${playColor}" stroke-width="92" stroke-linejoin="round" stroke-linecap="round"/>`;

  return arcs + play;
}

const frostedDisc = `
  <circle cx="${C}" cy="${C}" r="416" fill="#FFFFFF" fill-opacity="0.5"/>`;

const gradientDefs = `
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="${GRADIENT[0]}"/>
      <stop offset="0.5" stop-color="${GRADIENT[1]}"/>
      <stop offset="1" stop-color="${GRADIENT[2]}"/>
    </linearGradient>
  </defs>`;

function svg(body) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${SIZE}" height="${SIZE}" viewBox="0 0 ${SIZE} ${SIZE}">${body}</svg>`;
}

const fullIcon = svg(`${gradientDefs}
  <rect width="${SIZE}" height="${SIZE}" fill="url(#bg)"/>
  ${frostedDisc}
  ${artwork()}`);

const background = svg(`${gradientDefs}
  <rect width="${SIZE}" height="${SIZE}" fill="url(#bg)"/>`);

// Android adaptive foreground: art scaled into the centre safe zone (~66%)
const adaptiveScale = 0.58;
const foreground = svg(`
  <g transform="translate(${C} ${C}) scale(${adaptiveScale}) translate(${-C} ${-C})">
    ${frostedDisc}
    ${artwork()}
  </g>`);

const monochrome = svg(`
  <g transform="translate(${C} ${C}) scale(${adaptiveScale}) translate(${-C} ${-C})">
    ${artwork({ mono: true })}
  </g>`);

// Splash: ring + play on transparent (splash bg colour comes from app.json)
const splash = svg(`${frostedDisc}${artwork()}`);

const outDir = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "assets", "images");

const jobs = [
  ["icon.png", fullIcon, 1024],
  ["android-icon-background.png", background, 1024],
  ["android-icon-foreground.png", foreground, 1024],
  ["android-icon-monochrome.png", monochrome, 1024],
  ["splash-icon.png", splash, 512],
  ["favicon.png", fullIcon, 64],
];

for (const [name, source, size] of jobs) {
  // density 2x supersamples the SVG rasterization, then Lanczos downsampling
  // smooths every edge — without this, curves alias visibly at small sizes
  await sharp(Buffer.from(source), { density: 144 })
    .resize(size, size)
    .png()
    .toFile(path.join(outDir, name));
  console.log(`wrote assets/images/${name} (${size}px)`);
}
