import { Ionicons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import { useCallback } from "react";
import { Text, View } from "react-native";
import Animated, { FadeIn, useAnimatedRef } from "react-native-reanimated";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import Sortable, { SortableGridRenderItem } from "react-native-sortables";
import { Glass } from "../../components/Glass";
import { PressableScale } from "../../components/PressableScale";
import { PRIMARY } from "../../lib/colors";
import { useThemeColors } from "../../lib/theme";
import { formatSeconds, totalDuration } from "../../lib/timer";
import { Workout } from "../../lib/types";
import { useWorkouts } from "../../lib/WorkoutsContext";

function WorkoutCard({ workout }: { workout: Workout }) {
  const router = useRouter();
  return (
    <PressableScale onPress={() => router.push(`/workout/${workout.id}`)}>
      <View className="rounded-3xl border border-white/60 bg-white/50 p-4 dark:border-white/10 dark:bg-white/[0.07]">
        <View className="flex-row items-center justify-between">
          <View className="flex-1 pr-3">
            <Text className="text-lg font-semibold text-ink dark:text-ink-dark">
              {workout.name}
            </Text>
            <Text className="mt-0.5 text-sm text-ink/50 dark:text-ink-dark/50">
              {formatSeconds(totalDuration(workout))} · {workout.repeats}{" "}
              {workout.repeats === 1 ? "round" : "rounds"}
            </Text>
          </View>
          <PressableScale onPress={() => router.push(`/run/${workout.id}`)} hitSlop={6}>
            <View
              className="h-14 w-14 items-center justify-center rounded-full"
              style={{ backgroundColor: PRIMARY }}
            >
              <Ionicons name="play" size={22} color="white" style={{ marginLeft: 2 }} />
            </View>
          </PressableScale>
        </View>
        <View className="mt-3 flex-row flex-wrap gap-1.5">
          {workout.intervals.map((interval) => (
            <View
              key={interval.id}
              className="flex-row items-center gap-1.5 rounded-full border border-white/60 bg-white/40 px-2.5 py-1 dark:border-white/10 dark:bg-white/[0.08]"
            >
              <View
                className="h-2.5 w-2.5 rounded-full"
                style={{ backgroundColor: interval.color }}
              />
              <Text className="text-xs font-medium text-ink/70 dark:text-ink-dark/70">
                {interval.label} {formatSeconds(interval.seconds)}
              </Text>
            </View>
          ))}
        </View>
      </View>
    </PressableScale>
  );
}

export default function WorkoutsScreen() {
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const theme = useThemeColors();
  const { workouts, hydrated, reorderWorkouts } = useWorkouts();
  const scrollRef = useAnimatedRef<Animated.ScrollView>();

  const renderItem = useCallback<SortableGridRenderItem<Workout>>(
    ({ item }) => <WorkoutCard workout={item} />,
    [],
  );

  if (!hydrated) return <View className="flex-1" />;

  return (
    <Animated.View entering={FadeIn} className="flex-1" style={{ paddingTop: insets.top + 8 }}>
      <View className="flex-row items-end justify-between px-6 pb-4">
        <View>
          <Text className="text-xs font-semibold uppercase tracking-widest text-ink/40 dark:text-ink-dark/40">
            HIIT Timer
          </Text>
          <Text className="text-4xl font-bold text-ink dark:text-ink-dark">Workouts</Text>
        </View>
        <View className="flex-row items-center gap-2">
          <PressableScale onPress={() => router.push("/settings")} hitSlop={6}>
            <Glass radius={22} bordered className="h-11 w-11 items-center justify-center">
              <Ionicons name="settings-outline" size={19} color={theme.ink} />
            </Glass>
          </PressableScale>
          <PressableScale onPress={() => router.push("/workout/new")}>
            <Glass radius={22} bordered className="flex-row items-center gap-1 px-4 py-2.5">
              <Ionicons name="add" size={18} color={theme.ink} />
              <Text className="font-semibold text-ink dark:text-ink-dark">New</Text>
            </Glass>
          </PressableScale>
        </View>
      </View>
      <Animated.ScrollView
        ref={scrollRef}
        contentContainerStyle={{ paddingHorizontal: 24, paddingBottom: 140 }}
      >
        <Sortable.Grid
          columns={1}
          data={workouts}
          keyExtractor={(workout) => workout.id}
          renderItem={renderItem}
          rowGap={12}
          onDragEnd={({ data }) => reorderWorkouts(data)}
          scrollableRef={scrollRef}
        />
        {workouts.length === 0 && (
          <View className="items-center rounded-3xl border border-white/60 bg-white/50 p-8 dark:border-white/10 dark:bg-white/[0.07]">
            <Text className="text-base font-medium text-ink/60 dark:text-ink-dark/60">
              No workouts yet
            </Text>
            <Text className="mt-1 text-center text-sm text-ink/40 dark:text-ink-dark/40">
              Tap “New” to build your first interval workout.
            </Text>
          </View>
        )}
      </Animated.ScrollView>
    </Animated.View>
  );
}
