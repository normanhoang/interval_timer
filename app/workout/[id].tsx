import { Ionicons } from "@expo/vector-icons";
import { useLocalSearchParams, useRouter } from "expo-router";
import { useCallback, useState } from "react";
import {
  Alert,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  Text,
  TextInput,
  View,
} from "react-native";
import ReanimatedSwipeable from "react-native-gesture-handler/ReanimatedSwipeable";
import Animated, { useAnimatedRef } from "react-native-reanimated";
import Sortable, { SortableGridRenderItem } from "react-native-sortables";
import { AppBackground } from "../../components/AppBackground";
import { DurationSheet } from "../../components/DurationSheet";
import { DurationWheel } from "../../components/DurationWheel";
import { Glass } from "../../components/Glass";
import { PressableScale } from "../../components/PressableScale";
import { nextIntervalColor, REST_COLOR, WORK_COLOR } from "../../lib/colors";
import { useThemeColors } from "../../lib/theme";
import { formatSeconds, totalDuration } from "../../lib/timer";
import { Interval } from "../../lib/types";
import { uid, useWorkouts } from "../../lib/WorkoutsContext";

function defaultIntervals(): Interval[] {
  return [
    { id: uid(), label: "Work", seconds: 30, color: WORK_COLOR },
    { id: uid(), label: "Rest", seconds: 15, color: REST_COLOR },
  ];
}

export default function WorkoutEditorScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const theme = useThemeColors();
  const { getWorkout, addWorkout, updateWorkout, deleteWorkout } = useWorkouts();
  const scrollRef = useAnimatedRef<Animated.ScrollView>();

  const isNew = id === "new";
  const existing = isNew ? undefined : getWorkout(id);

  const [name, setName] = useState(existing?.name ?? "");
  const [repeats, setRepeats] = useState(existing?.repeats ?? 4);
  const [intervals, setIntervals] = useState<Interval[]>(
    existing ? existing.intervals.map((i) => ({ ...i })) : defaultIntervals(),
  );
  const [editingId, setEditingId] = useState<string | null>(null);

  const patchInterval = useCallback((intervalId: string, patch: Partial<Interval>) => {
    setIntervals((prev) => prev.map((i) => (i.id === intervalId ? { ...i, ...patch } : i)));
  }, []);

  const removeInterval = useCallback((intervalId: string) => {
    setIntervals((prev) => prev.filter((i) => i.id !== intervalId));
  }, []);

  const addInterval = () => {
    const work = intervals.length % 2 === 0;
    setIntervals((prev) => [
      ...prev,
      {
        id: uid(),
        label: work ? "Work" : "Rest",
        seconds: work ? 30 : 15,
        color: work ? WORK_COLOR : REST_COLOR,
      },
    ]);
  };

  const save = () => {
    if (intervals.length === 0) {
      Alert.alert("No intervals", "Add at least one interval before saving.");
      return;
    }
    const payload = {
      name: name.trim() || "Workout",
      intervals,
      repeats,
    };
    if (existing) updateWorkout(existing.id, payload);
    else addWorkout(payload);
    router.back();
  };

  const confirmDelete = () => {
    if (!existing) return;
    Alert.alert("Delete workout?", `“${existing.name}” will be removed.`, [
      { text: "Cancel", style: "cancel" },
      {
        text: "Delete",
        style: "destructive",
        onPress: () => {
          deleteWorkout(existing.id);
          router.back();
        },
      },
    ]);
  };

  const renderInterval = useCallback<SortableGridRenderItem<Interval>>(
    ({ item: interval }) => (
      <ReanimatedSwipeable
        friction={2}
        rightThreshold={36}
        overshootRight={false}
        renderRightActions={() => (
          <Pressable
            onPress={() => removeInterval(interval.id)}
            className="ml-2 w-16 items-center justify-center rounded-3xl bg-rose-400"
          >
            <Ionicons name="trash" size={18} color="white" />
          </Pressable>
        )}
      >
        <View className="min-h-[54px] flex-row items-center gap-2.5 rounded-3xl border border-white/60 bg-white/50 px-3 py-2 dark:border-white/10 dark:bg-white/[0.07]">
          <Sortable.Handle>
            <View className="h-8 w-8 items-center justify-center">
              <Ionicons name="reorder-three" size={22} color={theme.inkMuted} />
            </View>
          </Sortable.Handle>
          <Pressable
            onPress={() => patchInterval(interval.id, { color: nextIntervalColor(interval.color) })}
            hitSlop={6}
          >
            <View
              className="h-7 w-7 rounded-full border-2 border-white/80 dark:border-white/30"
              style={{ backgroundColor: interval.color }}
            />
          </Pressable>
          <TextInput
            value={interval.label}
            onChangeText={(label) => patchInterval(interval.id, { label })}
            placeholder="Label"
            placeholderTextColor={theme.placeholder}
            className="flex-1 p-0 font-semibold text-ink dark:text-ink-dark"
            style={{ fontSize: 16, height: 40, textAlignVertical: "center" }}
          />
          <Pressable
            onPress={() => setEditingId(interval.id)}
            hitSlop={4}
            className="rounded-full border border-white/60 bg-white/60 px-3 py-1.5 dark:border-white/10 dark:bg-white/[0.12]"
          >
            <Text className="text-sm font-semibold tabular-nums text-ink dark:text-ink-dark">
              {formatSeconds(interval.seconds)}
            </Text>
          </Pressable>
        </View>
      </ReanimatedSwipeable>
    ),
    [patchInterval, removeInterval, theme],
  );

  const editingInterval = intervals.find((i) => i.id === editingId);

  const closeDurationSheet = () => {
    if (editingInterval && editingInterval.seconds === 0) {
      patchInterval(editingInterval.id, { seconds: 1 });
    }
    setEditingId(null);
  };

  const total = totalDuration({ intervals, repeats });

  return (
    <View className="flex-1">
      <AppBackground />
      <KeyboardAvoidingView
        className="flex-1"
        behavior={Platform.OS === "ios" ? "padding" : undefined}
      >
        <View className="flex-row items-center justify-between px-5 pb-2 pt-5">
          <PressableScale onPress={() => router.back()} hitSlop={8}>
            <Glass radius={20} bordered className="h-10 w-10 items-center justify-center">
              <Ionicons name="close" size={20} color={theme.ink} />
            </Glass>
          </PressableScale>
          <Text className="text-lg font-bold text-ink dark:text-ink-dark">
            {isNew ? "New Workout" : "Edit Workout"}
          </Text>
          <PressableScale onPress={save} hitSlop={8}>
            <Glass radius={20} bordered className="px-4 py-2">
              <Text className="font-semibold text-ink dark:text-ink-dark">Save</Text>
            </Glass>
          </PressableScale>
        </View>

        <Animated.ScrollView
          ref={scrollRef}
          contentContainerStyle={{ paddingHorizontal: 20, paddingBottom: 48 }}
          keyboardShouldPersistTaps="handled"
        >
          <View className="gap-3">
            <View className="rounded-3xl border border-white/60 bg-white/50 p-4 dark:border-white/10 dark:bg-white/[0.07]">
              <Text className="mb-1.5 text-xs font-semibold uppercase tracking-widest text-ink/40 dark:text-ink-dark/40">
                Name
              </Text>
              <TextInput
                value={name}
                onChangeText={setName}
                placeholder="e.g. Morning HIIT"
                placeholderTextColor={theme.placeholder}
                className="text-lg font-semibold text-ink dark:text-ink-dark"
              />
            </View>

            <View className="flex-row items-center justify-between rounded-3xl border border-white/60 bg-white/50 p-4 dark:border-white/10 dark:bg-white/[0.07]">
              <View>
                <Text className="text-xs font-semibold uppercase tracking-widest text-ink/40 dark:text-ink-dark/40">
                  Rounds
                </Text>
                <Text className="mt-0.5 text-sm text-ink/50 dark:text-ink-dark/50">
                  Repeat the sequence
                </Text>
              </View>
              <View className="flex-row items-center gap-3">
                <Pressable
                  onPress={() => setRepeats((r) => Math.max(1, r - 1))}
                  hitSlop={6}
                  className="h-9 w-9 items-center justify-center rounded-full border border-white/60 bg-white/60 dark:border-white/10 dark:bg-white/[0.12]"
                >
                  <Text className="text-base font-semibold text-ink dark:text-ink-dark">−</Text>
                </Pressable>
                <Text className="w-8 text-center text-lg font-bold tabular-nums text-ink dark:text-ink-dark">
                  {repeats}
                </Text>
                <Pressable
                  onPress={() => setRepeats((r) => Math.min(99, r + 1))}
                  hitSlop={6}
                  className="h-9 w-9 items-center justify-center rounded-full border border-white/60 bg-white/60 dark:border-white/10 dark:bg-white/[0.12]"
                >
                  <Text className="text-base font-semibold text-ink dark:text-ink-dark">+</Text>
                </Pressable>
              </View>
            </View>

            <Text className="mt-2 px-1 text-xs font-semibold uppercase tracking-widest text-ink/40 dark:text-ink-dark/40">
              Intervals — drag ☰ to reorder
            </Text>

            <Sortable.Grid
              columns={1}
              data={intervals}
              keyExtractor={(interval) => interval.id}
              renderItem={renderInterval}
              rowGap={12}
              customHandle
              onDragEnd={({ data }) => setIntervals(data)}
              scrollableRef={scrollRef}
            />

            <PressableScale onPress={addInterval}>
              <View className="items-center rounded-3xl border-2 border-dashed border-ink/15 py-3.5 dark:border-ink-dark/15">
                <Text className="font-semibold text-ink/50 dark:text-ink-dark/50">
                  + Add interval
                </Text>
              </View>
            </PressableScale>

            <Text className="mt-1 text-center text-sm font-medium text-ink/50 dark:text-ink-dark/50">
              Total: {formatSeconds(total)} · {repeats} {repeats === 1 ? "round" : "rounds"}
            </Text>

            {existing && (
              <PressableScale onPress={confirmDelete}>
                <Text className="mt-4 text-center text-sm font-semibold text-rose-400">
                  Delete workout
                </Text>
              </PressableScale>
            )}
          </View>
        </Animated.ScrollView>
      </KeyboardAvoidingView>

      {editingInterval && (
        <DurationSheet title={editingInterval.label || "Duration"} onClose={closeDurationSheet}>
          <DurationWheel
            seconds={editingInterval.seconds}
            onChange={(seconds) => patchInterval(editingInterval.id, { seconds })}
          />
        </DurationSheet>
      )}
    </View>
  );
}
