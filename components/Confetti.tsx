import { useEffect, useMemo } from "react";
import { StyleSheet, View } from "react-native";
import Animated, {
  Easing,
  useAnimatedStyle,
  useSharedValue,
  withDelay,
  withTiming,
} from "react-native-reanimated";

const COLORS = ["#FBCFE8", "#FED7AA", "#BBF7D0", "#BAE6FD", "#DDD6FE", "#FEF3C7", "#A78BFA"];

interface Spark {
  id: number;
  angle: number;
  distance: number;
  size: number;
  color: string;
  delay: number;
  duration: number;
  gravity: number;
}

function SparkView({ spark }: { spark: Spark }) {
  const t = useSharedValue(0);

  useEffect(() => {
    t.value = withDelay(
      spark.delay,
      withTiming(1, { duration: spark.duration, easing: Easing.out(Easing.cubic) }),
    );
  }, [spark, t]);

  const animatedStyle = useAnimatedStyle(() => ({
    // invisible until its wave starts, then fades out over the last 35%
    opacity: t.value === 0 ? 0 : t.value < 0.65 ? 1 : (1 - t.value) / 0.35,
    transform: [
      { translateX: Math.cos(spark.angle) * spark.distance * t.value },
      { translateY: Math.sin(spark.angle) * spark.distance * t.value + spark.gravity * t.value * t.value },
      { scale: 1 - 0.5 * t.value },
    ],
  }));

  return (
    <Animated.View
      style={[
        {
          position: "absolute",
          left: -spark.size / 2,
          top: -spark.size / 2,
          width: spark.size,
          height: spark.size,
          borderRadius: spark.size / 2,
          backgroundColor: spark.color,
        },
        animatedStyle,
      ]}
    />
  );
}

/**
 * Fireworks-style one-shot burst from the center of the parent.
 * Render inside a relatively-positioned container; plays on mount.
 */
export function Confetti() {
  const sparks = useMemo<Spark[]>(() => {
    const result: Spark[] = [];
    const count = 90;
    for (let i = 0; i < count; i++) {
      const wave = i % 3;
      result.push({
        id: i,
        angle: Math.random() * Math.PI * 2,
        distance: 90 + Math.random() * 130,
        size: 4 + Math.random() * 4,
        color: COLORS[Math.floor(Math.random() * COLORS.length)],
        delay: wave * 180 + Math.random() * 80,
        duration: 900 + Math.random() * 600,
        gravity: 30 + Math.random() * 50,
      });
    }
    return result;
  }, []);

  return (
    <View
      pointerEvents="none"
      style={[StyleSheet.absoluteFill, { alignItems: "center", justifyContent: "center" }]}
    >
      <View style={{ width: 0, height: 0 }}>
        {sparks.map((spark) => (
          <SparkView key={spark.id} spark={spark} />
        ))}
      </View>
    </View>
  );
}
