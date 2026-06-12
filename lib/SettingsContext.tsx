import AsyncStorage from "@react-native-async-storage/async-storage";
import { colorScheme } from "nativewind";
import {
  ReactNode,
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import { DEFAULT_ALERT_ID } from "./alertSounds";
import { configureCues } from "./cues";

const SETTINGS_KEY = "@hiit/settings";

export type ThemeSetting = "system" | "light" | "dark";

interface Settings {
  soundEnabled: boolean;
  hapticsEnabled: boolean;
  alertSound: string;
  theme: ThemeSetting;
}

const DEFAULTS: Settings = {
  soundEnabled: true,
  hapticsEnabled: true,
  alertSound: DEFAULT_ALERT_ID,
  theme: "system",
};

interface SettingsValue extends Settings {
  hydrated: boolean;
  setSoundEnabled: (enabled: boolean) => void;
  setHapticsEnabled: (enabled: boolean) => void;
  setAlertSound: (id: string) => void;
  setTheme: (theme: ThemeSetting) => void;
}

const SettingsContext = createContext<SettingsValue | null>(null);

export function SettingsProvider({ children }: { children: ReactNode }) {
  const [hydrated, setHydrated] = useState(false);
  const [settings, setSettings] = useState<Settings>(DEFAULTS);

  useEffect(() => {
    (async () => {
      try {
        const raw = await AsyncStorage.getItem(SETTINGS_KEY);
        if (raw != null) setSettings({ ...DEFAULTS, ...JSON.parse(raw) });
      } catch {
      } finally {
        setHydrated(true);
      }
    })();
  }, []);

  const hydratedRef = useRef(false);
  hydratedRef.current = hydrated;

  const patch = useCallback((partial: Partial<Settings>) => {
    setSettings((prev) => {
      const next = { ...prev, ...partial };
      if (hydratedRef.current) {
        AsyncStorage.setItem(SETTINGS_KEY, JSON.stringify(next)).catch(() => {});
      }
      return next;
    });
  }, []);

  useEffect(() => {
    colorScheme.set(settings.theme);
  }, [settings.theme]);

  useEffect(() => {
    configureCues({
      sound: settings.soundEnabled,
      haptics: settings.hapticsEnabled,
      alertSound: settings.alertSound,
    });
  }, [settings.soundEnabled, settings.hapticsEnabled, settings.alertSound]);

  const value = useMemo<SettingsValue>(
    () => ({
      ...settings,
      hydrated,
      setSoundEnabled: (soundEnabled) => patch({ soundEnabled }),
      setHapticsEnabled: (hapticsEnabled) => patch({ hapticsEnabled }),
      setAlertSound: (alertSound) => patch({ alertSound }),
      setTheme: (theme) => patch({ theme }),
    }),
    [settings, hydrated, patch],
  );

  return <SettingsContext.Provider value={value}>{children}</SettingsContext.Provider>;
}

export function useSettings(): SettingsValue {
  const value = useContext(SettingsContext);
  if (!value) throw new Error("useSettings must be used inside SettingsProvider");
  return value;
}
