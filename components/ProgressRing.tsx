import { ReactNode, useEffect } from "react";
import { StyleSheet, View } from "react-native";
import Animated, {
  Easing,
  useAnimatedProps,
  useSharedValue,
  withTiming,
} from "react-native-reanimated";
import Svg, { Circle } from "react-native-svg";
import { useThemeColors } from "../lib/theme";

const AnimatedCircle = Animated.createAnimatedComponent(Circle);

interface Props {
  size: number;
  strokeWidth?: number;
  /** Fraction remaining, 0–1: 1 draws the full ring, 0 empties it. */
  progress: number;
  color: string;
  trackColor?: string;
  children?: ReactNode;
}

export function ProgressRing({ size, strokeWidth = 14, progress, color, trackColor, children }: Props) {
  const theme = useThemeColors();
  const track = trackColor ?? theme.ringTrack;
  const r = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * r;
  const p = useSharedValue(progress);

  useEffect(() => {
    p.value = withTiming(progress, { duration: 140, easing: Easing.linear });
  }, [p, progress]);

  const animatedProps = useAnimatedProps(() => ({
    strokeDashoffset: circumference * (1 - p.value),
  }));

  return (
    <View style={{ width: size, height: size }}>
      <Svg width={size} height={size}>
        <Circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          stroke={track}
          strokeWidth={strokeWidth}
          fill="none"
        />
        <AnimatedCircle
          cx={size / 2}
          cy={size / 2}
          r={r}
          stroke={color}
          strokeWidth={strokeWidth}
          strokeLinecap="round"
          fill="none"
          strokeDasharray={`${circumference} ${circumference}`}
          animatedProps={animatedProps}
          transform={`rotate(-90 ${size / 2} ${size / 2})`}
        />
      </Svg>
      <View style={StyleSheet.absoluteFill} className="items-center justify-center">
        {children}
      </View>
    </View>
  );
}
