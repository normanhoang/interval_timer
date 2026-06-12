import { Ionicons } from "@expo/vector-icons";
import { useState } from "react";
import { Pressable, Text, View } from "react-native";
import { addMonths, dayKey, monthMatrix, monthTitle } from "../lib/calendar";
import { useThemeColors } from "../lib/theme";

const WEEKDAYS = ["S", "M", "T", "W", "T", "F", "S"];

interface Props {
  /** dayKey()s that have at least one session. */
  markedDays: Set<string>;
  selectedDay: string | null;
  onSelectDay: (day: string | null) => void;
}

/** Habit-tracker month grid: dots on workout days, tap a marked day to filter. */
export function MonthCalendar({ markedDays, selectedDay, onSelectDay }: Props) {
  const theme = useThemeColors();
  const today = new Date();
  const todayKey = dayKey(today);
  const [visible, setVisible] = useState({ year: today.getFullYear(), month: today.getMonth() });

  const atCurrentMonth =
    visible.year === today.getFullYear() && visible.month === today.getMonth();
  const weeks = monthMatrix(visible.year, visible.month);

  const page = (delta: number) => setVisible((v) => addMonths(v.year, v.month, delta));

  return (
    <View className="rounded-3xl border border-white/60 bg-white/50 p-4 dark:border-white/10 dark:bg-white/[0.07]">
      <View className="flex-row items-center justify-between">
        <Pressable
          onPress={() => page(-1)}
          hitSlop={8}
          className="h-8 w-8 items-center justify-center rounded-full border border-white/60 bg-white/60 dark:border-white/10 dark:bg-white/[0.12]"
        >
          <Ionicons name="chevron-back" size={15} color={theme.ink} />
        </Pressable>
        <Text className="text-base font-semibold text-ink dark:text-ink-dark">
          {monthTitle(visible.year, visible.month)}
        </Text>
        <Pressable
          onPress={() => page(1)}
          disabled={atCurrentMonth}
          hitSlop={8}
          className={
            atCurrentMonth
              ? "h-8 w-8 items-center justify-center rounded-full bg-white/30 dark:bg-white/[0.04]"
              : "h-8 w-8 items-center justify-center rounded-full border border-white/60 bg-white/60 dark:border-white/10 dark:bg-white/[0.12]"
          }
        >
          <Ionicons
            name="chevron-forward"
            size={15}
            color={atCurrentMonth ? theme.inkFaint : theme.ink}
          />
        </Pressable>
      </View>

      <View className="mt-3 flex-row">
        {WEEKDAYS.map((label, i) => (
          <Text
            key={`${label}-${i}`}
            className="flex-1 text-center text-xs font-semibold text-ink/30 dark:text-ink-dark/30"
          >
            {label}
          </Text>
        ))}
      </View>

      {weeks.map((week, wi) => (
        <View key={wi} className="mt-1.5 flex-row">
          {week.map((date, di) => {
            if (!date) return <View key={di} className="flex-1 py-1" />;
            const key = dayKey(date);
            const marked = markedDays.has(key);
            const selected = selectedDay === key;
            const isToday = key === todayKey;
            const future = date.getTime() > today.getTime() && !isToday;
            return (
              <View key={di} className="flex-1 items-center py-1">
                <Pressable
                  onPress={marked ? () => onSelectDay(selected ? null : key) : undefined}
                  hitSlop={2}
                  className={
                    selected
                      ? "h-9 w-9 items-center justify-center rounded-full border-2 border-primary bg-primary/30"
                      : marked
                        ? "h-9 w-9 items-center justify-center rounded-full bg-primary/25"
                        : isToday
                          ? "h-9 w-9 items-center justify-center rounded-full border border-primary/60"
                          : "h-9 w-9 items-center justify-center rounded-full"
                  }
                >
                  <Text
                    className={
                      marked
                        ? "text-sm font-bold text-ink dark:text-ink-dark"
                        : future
                          ? "text-sm text-ink/25 dark:text-ink-dark/25"
                          : "text-sm font-medium text-ink/60 dark:text-ink-dark/60"
                    }
                  >
                    {date.getDate()}
                  </Text>
                </Pressable>
              </View>
            );
          })}
        </View>
      ))}
    </View>
  );
}
