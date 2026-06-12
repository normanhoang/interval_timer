import { useColorScheme } from "nativewind";

/**
 * JS-side colors for everything className can't reach (icons, gradients,
 * blur tints, svg strokes). className sites use dark: variants instead.
 */
export interface ThemeColors {
  dark: boolean;
  ink: string;
  inkMuted: string;
  inkFaint: string;
  placeholder: string;
  gradient: readonly [string, string, string];
  glassTint: "light" | "dark";
  glassFill: string;
  glassBorder: string;
  tabChip: string;
  ringTrack: string;
}

const LIGHT: ThemeColors = {
  dark: false,
  ink: "#3B3556",
  inkMuted: "rgba(59,53,86,0.45)",
  inkFaint: "rgba(59,53,86,0.2)",
  placeholder: "rgba(59,53,86,0.3)",
  gradient: ["#FFF1F2", "#EDE9FE", "#E0F2FE"],
  glassTint: "light",
  glassFill: "rgba(255,255,255,0.45)",
  glassBorder: "rgba(255,255,255,0.85)",
  tabChip: "rgba(255,255,255,0.8)",
  ringTrack: "rgba(255,255,255,0.55)",
};

const DARK: ThemeColors = {
  dark: true,
  ink: "#EAE6F7",
  inkMuted: "rgba(234,230,247,0.45)",
  inkFaint: "rgba(234,230,247,0.2)",
  placeholder: "rgba(234,230,247,0.3)",
  gradient: ["#221B36", "#1C2038", "#16222F"],
  glassTint: "dark",
  glassFill: "rgba(255,255,255,0.08)",
  glassBorder: "rgba(255,255,255,0.16)",
  tabChip: "rgba(255,255,255,0.16)",
  ringTrack: "rgba(255,255,255,0.12)",
};

export function useThemeColors(): ThemeColors {
  const { colorScheme } = useColorScheme();
  return colorScheme === "dark" ? DARK : LIGHT;
}
