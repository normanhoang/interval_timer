import { View } from "react-native";
import { Interval } from "../lib/types";

interface Props {
  intervals: Interval[];
  height?: number;
}

/**
 * Proportional stacked color bar — one rounded sliver per interval, width
 * proportional to its seconds. A workout's visual fingerprint at a glance.
 */
export function IntervalMixBar({ intervals, height = 6 }: Props) {
  const visible = intervals.filter((interval) => interval.seconds > 0);
  if (visible.length === 0) return null;
  return (
    <View className="flex-row" style={{ height, gap: 3 }}>
      {visible.map((interval) => (
        <View
          key={interval.id}
          style={{
            flex: interval.seconds,
            backgroundColor: interval.color,
            borderRadius: height / 2,
          }}
        />
      ))}
    </View>
  );
}
