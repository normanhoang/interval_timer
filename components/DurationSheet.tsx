import { Pressable, Text, View } from "react-native";
import Animated, { FadeIn, FadeOut, SlideInDown, SlideOutDown } from "react-native-reanimated";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { PressableScale } from "./PressableScale";

interface Props {
  title: string;
  /** Done/backdrop dismiss — parent clamps a 0s total before closing. */
  onClose: () => void;
  children: React.ReactNode;
}

/** Bottom-pinned sheet for the duration wheels, with a dimmed dismissable backdrop. */
export function DurationSheet({ title, onClose, children }: Props) {
  const insets = useSafeAreaInsets();

  return (
    <View className="absolute inset-0">
      <Animated.View entering={FadeIn} exiting={FadeOut} className="absolute inset-0">
        <Pressable onPress={onClose} className="flex-1 bg-black/25" />
      </Animated.View>
      <Animated.View
        entering={SlideInDown}
        exiting={SlideOutDown}
        className="absolute inset-x-0 bottom-0"
      >
        <View
          className="rounded-t-[28px] border-t border-white/60 bg-[#F6F1FA] px-5 pt-4 dark:border-white/10 dark:bg-[#221F38]"
          style={{ paddingBottom: insets.bottom + 12 }}
        >
          <View className="flex-row items-center justify-between">
            <Text className="text-base font-semibold text-ink/60 dark:text-ink-dark/60">
              {title}
            </Text>
            <PressableScale onPress={onClose} hitSlop={8}>
              <View className="rounded-full border border-white/60 bg-white/70 px-5 py-2 dark:border-white/10 dark:bg-white/[0.14]">
                <Text className="font-semibold text-ink dark:text-ink-dark">Done</Text>
              </View>
            </PressableScale>
          </View>
          {children}
        </View>
      </Animated.View>
    </View>
  );
}
