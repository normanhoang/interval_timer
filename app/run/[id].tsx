import { Ionicons } from "@expo/vector-icons";
import { useKeepAwake } from "expo-keep-awake";
import { useLocalSearchParams, useRouter } from "expo-router";
import { useEffect, useMemo, useRef } from "react";
import { Alert, Text, useWindowDimensions, View } from "react-native";
import Animated, { FadeIn } from "react-native-reanimated";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { AppBackground } from "../../components/AppBackground";
import { Confetti } from "../../components/Confetti";
import { Glass } from "../../components/Glass";
import { PressableScale } from "../../components/PressableScale";
import { ProgressRing } from "../../components/ProgressRing";
import { randomEncouragement } from "../../lib/encouragements";
import { PRIMARY } from "../../lib/colors";
import { cueCountdown, cueFinish, cueSegmentChange, initCues, releaseCues } from "../../lib/cues";
import { useSettings } from "../../lib/SettingsContext";
import { useThemeColors } from "../../lib/theme";
import { flattenWorkout, formatSeconds, totalDuration } from "../../lib/timer";
import { useIntervalTimer } from "../../lib/useIntervalTimer";
import { useWorkouts } from "../../lib/WorkoutsContext";

const PREROLL_SECONDS = 3;

export default function RunScreen() {
  useKeepAwake();
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const theme = useThemeColors();
  const { width } = useWindowDimensions();
  const { getWorkout, addSession } = useWorkouts();
  const { soundEnabled, setSoundEnabled } = useSettings();

  const workout = getWorkout(id);
  const segments = useMemo(
    () => (workout ? flattenWorkout(workout, PREROLL_SECONDS) : []),
    [workout],
  );

  const timer = useIntervalTimer(segments, {
    onSegmentChange: (index) => {
      if (index > 0) cueSegmentChange();
    },
    onCountdownTick: () => cueCountdown(),
    onFinish: () => cueFinish(),
  });

  useEffect(() => {
    initCues();
    return () => releaseCues();
  }, []);

  const recordedRef = useRef(false);
  useEffect(() => {
    if (timer.phase === "done" && !recordedRef.current && workout) {
      recordedRef.current = true;
      addSession({
        workoutId: workout.id,
        workoutName: workout.name,
        totalSeconds: totalDuration(workout),
      });
    }
  }, [timer.phase, workout, addSession]);

  if (!workout) {
    return (
      <View className="flex-1">
        <AppBackground />
      </View>
    );
  }

  const segment = timer.segment;
  const next = segments[timer.index + 1];
  const done = timer.phase === "done";
  const paused = timer.phase === "paused";
  const ringSize = Math.min(width - 72, 340);
  const totalAll = segments.length ? totalDuration(workout) + PREROLL_SECONDS : 0;
  const elapsedFraction = totalAll > 0 ? 1 - timer.totalRemaining / totalAll : 1;
  const encouragement = useMemo(() => randomEncouragement(), [done]);

  const end = () => {
    if (done) {
      router.back();
      return;
    }
    Alert.alert("End workout?", "Progress won't be saved to history.", [
      { text: "Keep going", style: "cancel" },
      { text: "End", style: "destructive", onPress: () => router.back() },
    ]);
  };

  return (
    <View className="flex-1">
      <AppBackground />
      <View
        className="flex-1 px-6"
        style={{ paddingTop: insets.top + 12, paddingBottom: insets.bottom + 16 }}
      >
        {!done && (
          <View className="flex-row items-center justify-between">
            <PressableScale onPress={end} hitSlop={8}>
              <Glass radius={20} bordered className="px-4 py-2">
                <Text className="font-semibold text-ink dark:text-ink-dark">End</Text>
              </Glass>
            </PressableScale>
            <Text
              className="text-base font-semibold text-ink/60 dark:text-ink-dark/60"
              numberOfLines={1}
            >
              {workout.name}
            </Text>
            <PressableScale onPress={() => setSoundEnabled(!soundEnabled)} hitSlop={8}>
              <Glass radius={20} bordered className="h-10 w-10 items-center justify-center">
                <Ionicons
                  name={soundEnabled ? "volume-high" : "volume-mute"}
                  size={18}
                  color={soundEnabled ? theme.ink : theme.inkMuted}
                />
              </Glass>
            </PressableScale>
          </View>
        )}

        {done ? (
          <Animated.View entering={FadeIn} className="flex-1 items-center justify-center">
            <View className="relative h-24 w-24 items-center justify-center">
              <Text className="text-6xl">🎉</Text>
              <Confetti />
            </View>
            <Text className="mt-6 text-3xl font-bold text-ink dark:text-ink-dark">
              {encouragement}
            </Text>
            <Text className="mt-3 text-base text-ink/50 dark:text-ink-dark/50">
              {workout.name} · {formatSeconds(totalDuration(workout))}
            </Text>
            <PressableScale onPress={() => router.back()} className="mt-12">
              <Glass radius={32} bordered className="px-12 py-5">
                <Text className="text-2xl font-bold text-ink dark:text-ink-dark">Done</Text>
              </Glass>
            </PressableScale>
          </Animated.View>
        ) : (
          <>
            <View className="flex-1 items-center justify-center">
              <ProgressRing
                size={ringSize}
                strokeWidth={16}
                progress={timer.fraction}
                color={segment?.color ?? "#DDD6FE"}
              >
                <Text className="text-xs font-semibold uppercase tracking-widest text-ink/40 dark:text-ink-dark/40">
                  {paused
                    ? "Paused"
                    : segment && segment.round > 0
                      ? `Round ${segment.round}/${segment.rounds}`
                      : ""}
                </Text>
                <Text className="text-7xl font-bold tabular-nums text-ink dark:text-ink-dark">
                  {formatSeconds(timer.remaining)}
                </Text>
                <Text className="text-lg font-semibold text-ink/60 dark:text-ink-dark/60">
                  {segment?.label ?? ""}
                </Text>
              </ProgressRing>
              <Text className="mt-6 text-base font-medium text-ink/50 dark:text-ink-dark/50">
                {next ? `Next: ${next.label} · ${formatSeconds(next.seconds)}` : "Last interval"}
              </Text>
            </View>

            <View className="mb-6 gap-1.5">
              <View className="h-2 overflow-hidden rounded-full bg-white/50 dark:bg-white/[0.12]">
                <View
                  className="h-full rounded-full"
                  style={{
                    width: `${Math.min(100, Math.max(0, elapsedFraction * 100))}%`,
                    backgroundColor: PRIMARY,
                  }}
                />
              </View>
              <Text className="text-center text-xs font-medium text-ink/40 dark:text-ink-dark/40">
                {formatSeconds(timer.totalRemaining)} left
              </Text>
            </View>

            <View className="flex-row items-center justify-center gap-5">
              <PressableScale onPress={timer.skipPrev} hitSlop={8}>
                <Glass radius={26} bordered className="h-[52px] w-[52px] items-center justify-center">
                  <Ionicons name="play-skip-back" size={20} color={theme.ink} />
                </Glass>
              </PressableScale>
              <PressableScale onPress={paused ? timer.resume : timer.pause} hitSlop={8}>
                <Glass radius={40} bordered className="h-20 w-20 items-center justify-center">
                  <Ionicons
                    name={paused ? "play" : "pause"}
                    size={32}
                    color={theme.ink}
                    style={paused ? { marginLeft: 3 } : undefined}
                  />
                </Glass>
              </PressableScale>
              <PressableScale onPress={timer.skipNext} hitSlop={8}>
                <Glass radius={26} bordered className="h-[52px] w-[52px] items-center justify-center">
                  <Ionicons name="play-skip-forward" size={20} color={theme.ink} />
                </Glass>
              </PressableScale>
            </View>
          </>
        )}
      </View>
    </View>
  );
}
