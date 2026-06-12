import { LinearGradient } from "expo-linear-gradient";
import { StyleSheet } from "react-native";
import { useThemeColors } from "../lib/theme";

/** Pastel wash rendered behind every screen — glass needs colour behind it to refract. */
export function AppBackground() {
  const theme = useThemeColors();
  return (
    <LinearGradient colors={theme.gradient} locations={[0, 0.45, 1]} style={StyleSheet.absoluteFill} />
  );
}
