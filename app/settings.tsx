import { Ionicons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import { Pressable, ScrollView, Switch, Text, View } from "react-native";
import { AppBackground } from "../components/AppBackground";
import { Glass } from "../components/Glass";
import { PressableScale } from "../components/PressableScale";
import { ALERT_SOUNDS } from "../lib/alertSounds";
import { PRIMARY } from "../lib/colors";
import { previewAlert } from "../lib/cues";
import { ThemeSetting, useSettings } from "../lib/SettingsContext";
import { useThemeColors } from "../lib/theme";

const THEME_OPTIONS: { value: ThemeSetting; label: string }[] = [
  { value: "system", label: "System" },
  { value: "light", label: "Light" },
  { value: "dark", label: "Dark" },
];

function ToggleRow({
  title,
  subtitle,
  value,
  onValueChange,
}: {
  title: string;
  subtitle: string;
  value: boolean;
  onValueChange: (value: boolean) => void;
}) {
  return (
    <View className="flex-row items-center justify-between rounded-3xl border border-white/60 bg-white/50 p-4 dark:border-white/10 dark:bg-white/[0.07]">
      <View className="flex-1 pr-3">
        <Text className="text-base font-semibold text-ink dark:text-ink-dark">{title}</Text>
        <Text className="mt-0.5 text-sm text-ink/50 dark:text-ink-dark/50">{subtitle}</Text>
      </View>
      <Switch
        value={value}
        onValueChange={onValueChange}
        trackColor={{ true: PRIMARY }}
        thumbColor="#ffffff"
      />
    </View>
  );
}

export default function SettingsScreen() {
  const router = useRouter();
  const theme = useThemeColors();
  const {
    soundEnabled,
    hapticsEnabled,
    alertSound,
    theme: themeSetting,
    setSoundEnabled,
    setHapticsEnabled,
    setAlertSound,
    setTheme,
  } = useSettings();

  const pickAlert = (id: string) => {
    setAlertSound(id);
    previewAlert(id);
  };

  return (
    <View className="flex-1">
      <AppBackground />
      <View className="flex-row items-center justify-between px-5 pb-2 pt-5">
        <PressableScale onPress={() => router.back()} hitSlop={8}>
          <Glass radius={20} bordered className="h-10 w-10 items-center justify-center">
            <Ionicons name="close" size={20} color={theme.ink} />
          </Glass>
        </PressableScale>
        <Text className="text-lg font-bold text-ink dark:text-ink-dark">Settings</Text>
        <View className="w-10" />
      </View>

      <ScrollView contentContainerStyle={{ paddingHorizontal: 20, paddingTop: 12, paddingBottom: 40, gap: 12 }}>
        <View className="rounded-3xl border border-white/60 bg-white/50 p-4 dark:border-white/10 dark:bg-white/[0.07]">
          <Text className="mb-3 text-xs font-semibold uppercase tracking-widest text-ink/40 dark:text-ink-dark/40">
            Appearance
          </Text>
          <View className="flex-row gap-2">
            {THEME_OPTIONS.map((option) => {
              const active = themeSetting === option.value;
              return (
                <Pressable
                  key={option.value}
                  onPress={() => setTheme(option.value)}
                  className={
                    active
                      ? "flex-1 items-center rounded-full border border-white/70 bg-white/80 py-2.5 dark:border-white/20 dark:bg-white/[0.16]"
                      : "flex-1 items-center rounded-full border border-white/50 bg-white/30 py-2.5 dark:border-white/10 dark:bg-white/[0.04]"
                  }
                >
                  <Text
                    className={
                      active
                        ? "text-sm font-semibold text-ink dark:text-ink-dark"
                        : "text-sm font-medium text-ink/50 dark:text-ink-dark/50"
                    }
                  >
                    {option.label}
                  </Text>
                </Pressable>
              );
            })}
          </View>
        </View>

        <ToggleRow
          title="Sound cues"
          subtitle="Countdown beeps and interval chimes"
          value={soundEnabled}
          onValueChange={setSoundEnabled}
        />
        <ToggleRow
          title="Haptics"
          subtitle="Vibration taps on interval changes"
          value={hapticsEnabled}
          onValueChange={setHapticsEnabled}
        />
        <View className="rounded-3xl border border-white/60 bg-white/50 p-4 dark:border-white/10 dark:bg-white/[0.07]">
          <Text className="mb-1 text-xs font-semibold uppercase tracking-widest text-ink/40 dark:text-ink-dark/40">
            Alert sound
          </Text>
          <Text className="mb-2 text-sm text-ink/50 dark:text-ink-dark/50">
            Played on every interval change — tap to preview
          </Text>
          {ALERT_SOUNDS.map((sound, i) => {
            const active = alertSound === sound.id;
            return (
              <Pressable
                key={sound.id}
                onPress={() => pickAlert(sound.id)}
                className={
                  i === 0
                    ? "flex-row items-center justify-between py-2.5"
                    : "flex-row items-center justify-between border-t border-ink/5 py-2.5 dark:border-ink-dark/10"
                }
              >
                <Text
                  className={
                    active
                      ? "text-base font-semibold text-ink dark:text-ink-dark"
                      : "text-base font-medium text-ink/60 dark:text-ink-dark/60"
                  }
                >
                  {sound.label}
                </Text>
                {active && <Ionicons name="checkmark-circle" size={20} color={PRIMARY} />}
              </Pressable>
            );
          })}
        </View>
      </ScrollView>
    </View>
  );
}
