import { Ionicons } from "@expo/vector-icons";
import { useMemo, useState } from "react";
import { Alert, Pressable, ScrollView, Text, View } from "react-native";
import ReanimatedSwipeable from "react-native-gesture-handler/ReanimatedSwipeable";
import Animated, { FadeIn, LinearTransition } from "react-native-reanimated";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { MonthCalendar } from "../../components/MonthCalendar";
import { PressableScale } from "../../components/PressableScale";
import { dayKey, streakLength } from "../../lib/calendar";
import { useThemeColors } from "../../lib/theme";
import { formatSeconds } from "../../lib/timer";
import { Session } from "../../lib/types";
import { useWorkouts } from "../../lib/WorkoutsContext";

function dayLabel(iso: string): string {
  const date = new Date(iso);
  const today = new Date();
  const yesterday = new Date(today);
  yesterday.setDate(today.getDate() - 1);
  if (date.toDateString() === today.toDateString()) return "Today";
  if (date.toDateString() === yesterday.toDateString()) return "Yesterday";
  return date.toLocaleDateString(undefined, { weekday: "long", month: "long", day: "numeric" });
}

function groupByDay(sessions: Session[]): { label: string; items: Session[] }[] {
  const sorted = [...sessions].sort((a, b) => b.completedAt.localeCompare(a.completedAt));
  const groups: { label: string; items: Session[] }[] = [];
  for (const session of sorted) {
    const label = dayLabel(session.completedAt);
    const last = groups[groups.length - 1];
    if (last && last.label === label) last.items.push(session);
    else groups.push({ label, items: [session] });
  }
  return groups;
}

function SessionRow({ session, onDelete }: { session: Session; onDelete: () => void }) {
  return (
    <ReanimatedSwipeable
      friction={2}
      rightThreshold={36}
      overshootRight={false}
      renderRightActions={() => (
        <Pressable
          onPress={onDelete}
          className="ml-2 w-[72px] items-center justify-center rounded-2xl bg-rose-400"
        >
          <Ionicons name="trash" size={20} color="white" />
          <Text className="mt-0.5 text-xs font-semibold text-white">Delete</Text>
        </Pressable>
      )}
    >
      <View className="flex-row items-center justify-between rounded-2xl border border-white/60 bg-white/50 px-4 py-3 dark:border-white/10 dark:bg-white/[0.07]">
        <View>
          <Text className="font-semibold text-ink dark:text-ink-dark">{session.workoutName}</Text>
          <Text className="mt-0.5 text-xs text-ink/40 dark:text-ink-dark/40">
            {new Date(session.completedAt).toLocaleTimeString(undefined, {
              hour: "numeric",
              minute: "2-digit",
            })}
          </Text>
        </View>
        <Text className="font-semibold tabular-nums text-ink/60 dark:text-ink-dark/60">
          {formatSeconds(session.totalSeconds)}
        </Text>
      </View>
    </ReanimatedSwipeable>
  );
}

function StatPanel({
  value,
  label,
  icon,
}: {
  value: string;
  label: string;
  icon: keyof typeof Ionicons.glyphMap;
}) {
  const theme = useThemeColors();
  return (
    <View className="flex-1 rounded-3xl border border-white/60 bg-white/50 p-4 dark:border-white/10 dark:bg-white/[0.07]">
      <View className="flex-row items-start justify-between">
        <Text className="text-2xl font-bold text-ink dark:text-ink-dark">{value}</Text>
        <Ionicons name={icon} size={16} color={theme.inkMuted} style={{ marginTop: 4 }} />
      </View>
      <Text className="mt-0.5 text-xs font-medium text-ink/50 dark:text-ink-dark/50">{label}</Text>
    </View>
  );
}

export default function HistoryScreen() {
  const insets = useSafeAreaInsets();
  const theme = useThemeColors();
  const { sessions, clearSessions, clearSessionsForDay, deleteSession, hydrated } = useWorkouts();
  const [selectedDay, setSelectedDay] = useState<string | null>(null);

  const markedDays = useMemo(
    () => new Set(sessions.map((s) => dayKey(s.completedAt))),
    [sessions],
  );

  if (!hydrated) return <View className="flex-1" />;

  const totalSeconds = sessions.reduce((sum, s) => sum + s.totalSeconds, 0);
  const weekAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;
  const thisWeek = sessions.filter((s) => new Date(s.completedAt).getTime() >= weekAgo).length;
  const streak = streakLength(markedDays);

  const visibleSessions = selectedDay
    ? sessions.filter((s) => dayKey(s.completedAt) === selectedDay)
    : sessions;
  const groups = groupByDay(visibleSessions);

  const confirmClear = () => {
    const day = selectedDay ?? dayKey(new Date());
    const dayName = selectedDay
      ? new Date(`${selectedDay}T12:00:00`).toLocaleDateString(undefined, {
          month: "long",
          day: "numeric",
        })
      : "today";
    Alert.alert("Clear history?", "Remove sessions for one day, or everything.", [
      { text: "Cancel", style: "cancel" },
      {
        text: `Clear ${dayName}`,
        onPress: () => {
          clearSessionsForDay(day);
          setSelectedDay(null);
        },
      },
      { text: "Clear all", style: "destructive", onPress: clearSessions },
    ]);
  };

  return (
    <Animated.View entering={FadeIn} className="flex-1" style={{ paddingTop: insets.top + 8 }}>
      <View className="px-6 pb-4">
        <Text className="text-xs font-semibold uppercase tracking-widest text-ink/40 dark:text-ink-dark/40">
          HIIT Timer
        </Text>
        <Text className="text-4xl font-bold text-ink dark:text-ink-dark">History</Text>
      </View>
      <ScrollView contentContainerStyle={{ paddingHorizontal: 24, paddingBottom: 140 }}>
        <View className="gap-3">
          <View className="flex-row gap-3">
            <StatPanel value={String(streak)} label="Day streak" icon="flame-outline" />
            <StatPanel value={String(thisWeek)} label="This week" icon="calendar-outline" />
          </View>
          <View className="flex-row gap-3">
            <StatPanel value={String(sessions.length)} label="Workouts" icon="barbell-outline" />
            <StatPanel value={formatSeconds(totalSeconds)} label="Total time" icon="time-outline" />
          </View>
        </View>

        <View className="mt-4">
          <MonthCalendar
            markedDays={markedDays}
            selectedDay={selectedDay}
            onSelectDay={setSelectedDay}
          />
        </View>

        {selectedDay && (
          <Pressable
            onPress={() => setSelectedDay(null)}
            className="mt-4 flex-row items-center justify-center gap-1.5 self-center rounded-full border border-white/60 bg-white/40 px-4 py-2 dark:border-white/10 dark:bg-white/[0.08]"
          >
            <Text className="text-sm font-semibold text-ink/70 dark:text-ink-dark/70">
              Showing {new Date(`${selectedDay}T12:00:00`).toLocaleDateString(undefined, {
                month: "long",
                day: "numeric",
              })}{" "}
              · Show all
            </Text>
            <Ionicons name="close-circle" size={16} color={theme.inkMuted} />
          </Pressable>
        )}

        {groups.map((group) => (
          <Animated.View key={group.label} layout={LinearTransition} className="mt-6">
            <Text className="mb-2 text-sm font-semibold text-ink/50 dark:text-ink-dark/50">
              {group.label}
            </Text>
            <View className="gap-2">
              {group.items.map((session) => (
                <Animated.View key={session.id} layout={LinearTransition}>
                  <SessionRow session={session} onDelete={() => deleteSession(session.id)} />
                </Animated.View>
              ))}
            </View>
          </Animated.View>
        ))}

        {sessions.length === 0 ? (
          <View className="mt-6 items-center rounded-3xl border border-white/60 bg-white/50 p-8 dark:border-white/10 dark:bg-white/[0.07]">
            <View className="mb-3 h-14 w-14 items-center justify-center rounded-full bg-white/60 dark:bg-white/[0.12]">
              <Ionicons name="calendar-clear-outline" size={24} color={theme.inkMuted} />
            </View>
            <Text className="text-base font-medium text-ink/60 dark:text-ink-dark/60">
              Nothing logged yet
            </Text>
            <Text className="mt-1 text-center text-sm text-ink/40 dark:text-ink-dark/40">
              Finish a workout and it will show up here.
            </Text>
          </View>
        ) : (
          <PressableScale onPress={confirmClear}>
            <Text className="mt-8 text-center text-sm font-semibold text-rose-400">
              Clear history
            </Text>
          </PressableScale>
        )}
      </ScrollView>
    </Animated.View>
  );
}
