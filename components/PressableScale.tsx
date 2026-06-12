import { ReactNode } from "react";
import { Pressable, PressableProps, StyleProp, ViewStyle } from "react-native";
import Animated, { useAnimatedStyle, useSharedValue, withSpring } from "react-native-reanimated";

const SPRING = { damping: 22, stiffness: 320 };

interface Props extends Omit<PressableProps, "style" | "children"> {
  /** Applied to the inner Animated.View (plain style — Animated.View isn't NativeWind-interop'd). */
  style?: StyleProp<ViewStyle>;
  children?: ReactNode;
}

/** Pressable that springs to 0.97 while held — the Apple "squish". */
export function PressableScale({ children, style, onPressIn, onPressOut, ...rest }: Props) {
  const scale = useSharedValue(1);
  const animatedStyle = useAnimatedStyle(() => ({ transform: [{ scale: scale.value }] }));

  return (
    <Pressable
      {...rest}
      onPressIn={(e) => {
        scale.value = withSpring(0.97, SPRING);
        onPressIn?.(e);
      }}
      onPressOut={(e) => {
        scale.value = withSpring(1, SPRING);
        onPressOut?.(e);
      }}
    >
      <Animated.View style={[animatedStyle, style]}>{children}</Animated.View>
    </Pressable>
  );
}
