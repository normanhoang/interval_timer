// Pastel palette — keep in sync with tailwind.config.js theme tokens.
export const INTERVAL_COLORS = [
  "#FBCFE8", // pink
  "#FED7AA", // peach
  "#BBF7D0", // mint
  "#BAE6FD", // sky
  "#DDD6FE", // lavender
  "#FEF3C7", // butter
] as const;

export const WORK_COLOR = "#FED7AA";
export const REST_COLOR = "#BAE6FD";
export const PREROLL_COLOR = "#DDD6FE";
export const INK = "#3B3556";
export const PRIMARY = "#A78BFA";

export function nextIntervalColor(current: string): string {
  const i = INTERVAL_COLORS.indexOf(current as (typeof INTERVAL_COLORS)[number]);
  return INTERVAL_COLORS[(i + 1) % INTERVAL_COLORS.length];
}
