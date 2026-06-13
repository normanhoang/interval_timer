// Soft interval palette — keep in sync with tailwind.config.js theme tokens
// and scripts/generate-icon.mjs.
export const INTERVAL_COLORS = [
  "#F38181", // coral
  "#FCE38A", // yellow
  "#EAFFD0", // pale green
  "#95E1D3", // aqua
  "#A8D8EA", // sky
  "#C9B6E4", // lavender
] as const;

export const WORK_COLOR = "#F38181";
export const REST_COLOR = "#95E1D3";
export const PREROLL_COLOR = "#FCE38A";
export const INK = "#3B3556";
export const PRIMARY = "#A78BFA";

/** Retired palette hexes → closest current hue, for migrating persisted workouts. */
export const LEGACY_COLOR_MAP: Record<string, string> = {
  // original pastels
  "#FBCFE8": "#F38181", // pink → coral
  "#FED7AA": "#FCE38A", // peach → yellow
  "#FEF3C7": "#FCE38A", // butter → yellow
  "#BBF7D0": "#EAFFD0", // mint → pale green
  "#BAE6FD": "#A8D8EA", // sky → sky
  "#DDD6FE": "#C9B6E4", // lavender → lavender
  // bold interlude palette
  "#FF0055": "#F38181", // raspberry → coral
  "#FF7A00": "#F38181", // orange → coral
  "#FFD500": "#FCE38A", // yellow → yellow
  "#00C57E": "#95E1D3", // green → aqua
  "#0058E1": "#A8D8EA", // cobalt → sky
  "#7C3AED": "#C9B6E4", // violet → lavender
};

/** Perceived-luminance check for picking a readable foreground on a swatch. */
export function isLightColor(hex: string): boolean {
  const n = parseInt(hex.slice(1), 16);
  const r = (n >> 16) & 255;
  const g = (n >> 8) & 255;
  const b = n & 255;
  return 0.299 * r + 0.587 * g + 0.114 * b > 150;
}
