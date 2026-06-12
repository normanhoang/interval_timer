import "../global.css";

import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { SettingsProvider } from "../lib/SettingsContext";
import { useThemeColors } from "../lib/theme";
import { WorkoutsProvider } from "../lib/WorkoutsContext";

function ThemedStatusBar() {
  const theme = useThemeColors();
  return <StatusBar style={theme.dark ? "light" : "dark"} />;
}

export default function RootLayout() {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaProvider>
        <SettingsProvider>
          <WorkoutsProvider>
            <ThemedStatusBar />
            <Stack screenOptions={{ headerShown: false }}>
              <Stack.Screen name="(tabs)" />
              <Stack.Screen name="workout/[id]" options={{ presentation: "modal" }} />
              <Stack.Screen name="settings" options={{ presentation: "modal" }} />
              <Stack.Screen
                name="run/[id]"
                options={{ presentation: "fullScreenModal", gestureEnabled: false }}
              />
            </Stack>
          </WorkoutsProvider>
        </SettingsProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
