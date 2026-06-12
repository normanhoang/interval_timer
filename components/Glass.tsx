import { BlurView } from "expo-blur";
import { GlassView, isLiquidGlassAvailable } from "expo-glass-effect";
import { ReactNode } from "react";
import { Platform, StyleProp, StyleSheet, View, ViewStyle } from "react-native";
import { useThemeColors } from "../lib/theme";

const nativeGlass = Platform.OS === "ios" && isLiquidGlassAvailable();

interface Props {
  /** Corner radius — must be a prop, not a rounded-* class (the native glass layer shapes itself with it). */
  radius?: number;
  /** Draw a hairline border overlay (1px utility borders on the clipping view alias badly). */
  bordered?: boolean;
  borderColor?: string;
  /** Layout/padding only — never opacity-* or rounded-*. */
  className?: string;
  style?: StyleProp<ViewStyle>;
  children?: ReactNode;
}

export function Glass({ radius = 20, bordered = false, borderColor, className, style, children }: Props) {
  const theme = useThemeColors();
  const border = bordered ? (
    <View
      pointerEvents="none"
      style={[
        StyleSheet.absoluteFill,
        {
          borderRadius: radius,
          borderWidth: StyleSheet.hairlineWidth,
          borderColor: borderColor ?? theme.glassBorder,
        },
      ]}
    />
  ) : null;

  if (nativeGlass) {
    return (
      <GlassView style={[{ borderRadius: radius }, style]}>
        <View className={className}>{children}</View>
        {border}
      </GlassView>
    );
  }

  return (
    <View style={[{ borderRadius: radius, overflow: "hidden" }, style]}>
      <BlurView intensity={36} tint={theme.glassTint} style={StyleSheet.absoluteFill} />
      <View
        pointerEvents="none"
        style={[StyleSheet.absoluteFill, { backgroundColor: theme.glassFill }]}
      />
      <View className={className}>{children}</View>
      {border}
    </View>
  );
}
