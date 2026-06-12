import { Ionicons } from "@expo/vector-icons";
import { MaterialTopTabBarProps } from "@react-navigation/material-top-tabs";
import { useEffect, useState } from "react";
import { Pressable, Text, View } from "react-native";
import Animated, { useAnimatedStyle, useSharedValue, withSpring } from "react-native-reanimated";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useThemeColors } from "../lib/theme";
import { Glass } from "./Glass";

const SPRING = { damping: 24, stiffness: 280 };

const ICONS: Record<string, keyof typeof Ionicons.glyphMap> = {
  index: "barbell",
  history: "time",
};

/** Floating glass pill with a sliding chip that springs to the active tab. */
export function GlassTabBar({ state, descriptors, navigation }: MaterialTopTabBarProps) {
  const insets = useSafeAreaInsets();
  const theme = useThemeColors();
  const [layouts, setLayouts] = useState<Record<number, { x: number; width: number }>>({});
  const chipLeft = useSharedValue(0);
  const chipWidth = useSharedValue(0);

  useEffect(() => {
    const layout = layouts[state.index];
    if (!layout) return;
    if (chipWidth.value === 0) {
      chipLeft.value = layout.x;
      chipWidth.value = layout.width;
    } else {
      chipLeft.value = withSpring(layout.x, SPRING);
      chipWidth.value = withSpring(layout.width, SPRING);
    }
  }, [state.index, layouts, chipLeft, chipWidth]);

  const chipStyle = useAnimatedStyle(() => ({
    left: chipLeft.value,
    width: chipWidth.value,
  }));

  return (
    <View
      pointerEvents="box-none"
      style={{
        position: "absolute",
        left: 0,
        right: 0,
        bottom: insets.bottom + 12,
        alignItems: "center",
      }}
    >
      <Glass radius={28} bordered className="flex-row p-1.5">
        <Animated.View
          style={[
            chipStyle,
            {
              position: "absolute",
              top: 6,
              bottom: 6,
              borderRadius: 22,
              backgroundColor: theme.tabChip,
            },
          ]}
        />
        {state.routes.map((route, i) => {
          const { options } = descriptors[route.key];
          const label = options.title ?? route.name;
          const active = state.index === i;
          return (
            <Pressable
              key={route.key}
              onLayout={(e) => {
                const { x, width } = e.nativeEvent.layout;
                setLayouts((prev) => ({ ...prev, [i]: { x, width } }));
              }}
              onPress={() => {
                const event = navigation.emit({
                  type: "tabPress",
                  target: route.key,
                  canPreventDefault: true,
                });
                if (!active && !event.defaultPrevented) {
                  navigation.navigate(route.name);
                }
              }}
              className="flex-row items-center gap-1.5 rounded-full px-5 py-2.5"
            >
              <Ionicons
                name={ICONS[route.name] ?? "ellipse"}
                size={16}
                color={active ? theme.ink : theme.inkMuted}
              />
              <Text
                className={
                  active
                    ? "text-sm font-semibold text-ink dark:text-ink-dark"
                    : "text-sm font-medium text-ink/50 dark:text-ink-dark/50"
                }
              >
                {label}
              </Text>
            </Pressable>
          );
        })}
      </Glass>
    </View>
  );
}
