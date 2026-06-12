import {
  MaterialTopTabNavigationEventMap,
  MaterialTopTabNavigationOptions,
  createMaterialTopTabNavigator,
} from "@react-navigation/material-top-tabs";
import { ParamListBase, TabNavigationState } from "@react-navigation/native";
import { withLayoutContext } from "expo-router";
import { View } from "react-native";
import { AppBackground } from "../../components/AppBackground";
import { GlassTabBar } from "../../components/GlassTabBar";

const { Navigator } = createMaterialTopTabNavigator();

const MaterialTopTabs = withLayoutContext<
  MaterialTopTabNavigationOptions,
  typeof Navigator,
  TabNavigationState<ParamListBase>,
  MaterialTopTabNavigationEventMap
>(Navigator);

export default function TabsLayout() {
  return (
    <View className="flex-1">
      <AppBackground />
      <MaterialTopTabs
        tabBarPosition="bottom"
        style={{ backgroundColor: "transparent" }}
        screenOptions={{
          sceneStyle: { backgroundColor: "transparent" },
          swipeEnabled: true,
        }}
        tabBar={(props) => <GlassTabBar {...props} />}
      >
        <MaterialTopTabs.Screen name="index" options={{ title: "Workouts" }} />
        <MaterialTopTabs.Screen name="history" options={{ title: "History" }} />
      </MaterialTopTabs>
    </View>
  );
}
