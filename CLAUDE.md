# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Important

Read the exact versioned docs at https://docs.expo.dev/versions/v54.0.0/ before writing any code. Expo APIs change significantly between SDK versions.

## Commands

```bash
npm start          # Start Expo dev server (shows QR code for Expo Go)
npm run ios        # Start with iOS simulator
npm run android    # Start with Android emulator
npm run web        # Start for browser
```

To verify changes:

```bash
npx tsc --noEmit                          # type-check (strict mode)
npm test                                  # Jest (jest-expo) unit tests for lib/ (run one: npx jest timer)
npx expo export --platform ios --output-dir /tmp/exp   # full bundle compile — catches Metro/Babel/resolution errors tsc can't
```

When adding new Expo/React Native packages, always use `npx expo install <package>` instead of `npm install` — this resolves the SDK 54 compatible version automatically. Some packages (e.g. NativeWind) trip npm's peer-dependency resolver because Expo pins `react`; add `--legacy-peer-deps` when a plain `npm install` fails with an `ERESOLVE` error.

## Stack

- **Expo SDK 54** — targeted at Expo Go 54.x on device
- **React Native 0.81** / **React 19.1**
- **Expo Router 6** — file-based routing via the `app/` directory
- **NativeWind 4** — Tailwind CSS utility classes (`className`) on React Native components, backed by Tailwind v3
- **TypeScript** in strict mode

## What this app is

A **HIIT interval timer**: build workouts as custom sequences of named, timed intervals (each with its own pastel color) repeated for N rounds, run them with a big ring countdown plus sound + haptic cues, and review completed sessions in History (stats + habit-tracker month calendar). Workouts and intervals are drag-reorderable; Settings holds sound/haptics toggles and a System/Light/Dark theme selector. All data is **local-only** (AsyncStorage) — no accounts, no network.

## Architecture

### Routing (`app/`)
The root layout (`app/_layout.tsx`) mounts `SettingsProvider` → `WorkoutsProvider` (inside `GestureHandlerRootView` + `SafeAreaProvider`), imports `global.css`, then renders a `<Stack>` plus a theme-aware `StatusBar`.

- `app/(tabs)/` — bottom tabs: `index.tsx` (**Workouts** — drag-sortable workout cards with per-card play buttons; card body opens the editor; header has Settings gear + New) and `history.tsx` (**History** — stat panels, `MonthCalendar` (tap a marked day to filter the list, "Show all" pill clears), sessions grouped by day with **swipe-to-delete** (`ReanimatedSwipeable` from gesture-handler + `LinearTransition` layout on the containers so rows close up), and a Clear history action offering **clear one day** (the calendar-selected day, else today — `clearSessionsForDay`) or **clear all**).
- `app/workout/[id].tsx` — **modal** editor; `id === "new"` creates. Name, rounds stepper, drag-sortable **single-line** interval rows (☰ handle · color-cycling dot · label input · time pill), swipe-left-to-delete per row (`ReanimatedSwipeable`, same pattern as History), live total footer, Save/Delete. The label `TextInput` uses explicit `style={{ fontSize, height }}` instead of `text-base` — NativeWind's lineHeight inside a `TextInput` shifts text off vertical center on iOS. Tapping a time pill opens `DurationSheet` (bottom-pinned overlay: backdrop + `SlideInDown` panel) containing `DurationWheel` (three `@react-native-picker/picker` hr/min/sec wheels, bundled in Expo Go); wheel changes patch the interval live, and closing clamps a 0s total to 1s.
- `app/settings.tsx` — **modal**: Appearance pills (System/Light/Dark), Sound cues / Haptics switches, and an Alert sound list (tap = select + `previewAlert`), all from `useSettings()`.
- `app/run/[id].tsx` — **fullScreenModal** run screen (`gestureEnabled: false`, `useKeepAwake`). Drives `useIntervalTimer` over the flattened workout (with a 3s "Get ready" pre-roll), shows the `ProgressRing`, round/next-up lines, a total-progress bar, skip/pause controls, and a header mute toggle (writes `soundEnabled` globally). **During workout:** header visible. **On finish:** header hidden (no title/End/mute buttons), shows a random encouraging message from `lib/encouragements.ts` (30-message pool), renders `Confetti` burst from the emoji, and a large prominent "Done" button. Fires the chime + success haptic and appends a `Session` on finish; ending early records nothing.

### Data & timer engine (`lib/`)
- `lib/types.ts` — `Interval`, `Workout`, `Session`.
- `lib/colors.ts` — pastel palette constants (`INTERVAL_COLORS`, `WORK_COLOR`, `REST_COLOR`, `INK`, `PRIMARY`). **Keep in sync with `tailwind.config.js` theme tokens** (tailwind config can't import TS, so hexes are duplicated deliberately).
- `lib/timer.ts` — pure, Jest-tested core: `flattenWorkout(workout, prerollSeconds)` expands repeats into `Segment`s with cumulative `startsAt` offsets; `segmentAt(segments, elapsed)` (an elapsed exactly on a segment edge belongs to the **next** segment); `totalDuration`; `formatSeconds`.
- `lib/useIntervalTimer.ts` — **timestamp-based** engine: elapsed is always recomputed from `Date.now()` minus accumulated pause time (a 100ms `setInterval` only triggers `sync()`), so pauses/JS stalls never drift. Exposes `phase` (`running|paused|done`), whole-second `remaining`, fractional `fraction` (drives the ring), `totalRemaining`, and `pause/resume/skipNext/skipPrev`. Fires `onSegmentChange`, `onCountdownTick` (last 3s of every segment), and `onFinish` exactly once each — callbacks are read through a ref so consumers can pass fresh closures.
- `lib/cues.ts` — `expo-audio` players (`createAudioPlayer`; replay = `seekTo(0)` + `play()`) + `expo-haptics`. `initCues()` sets `playsInSilentMode: true` and is called on run-screen mount; `releaseCues()` on unmount. Module-level sound/haptics/alert-id flags are synced from SettingsContext via `configureCues()`. `cueSegmentChange()` plays the selected alert from a per-id player map built from `lib/alertSounds.ts` (static `require()`s of the five `alert-*.wav`s); `previewAlert(id)` lazily inits and plays even when sound cues are toggled off (explicit user action). The WAVs in `assets/sounds/` are **generated — do not edit**; re-run `node scripts/generate-beeps.mjs` to regenerate (it has plain-tone and bell/harmonic-decay synth helpers). Likewise the app icons in `assets/images/` (icon, android adaptive set, splash, favicon) are **generated** by `node scripts/generate-icon.mjs` (SVG design rasterized via the `sharp` devDependency) — edit the script's SVG, not the PNGs.
- `lib/WorkoutsContext.tsx` — `workouts` CRUD + `reorderWorkouts` + `sessions` (`addSession`/`deleteSession`/`clearSessions`), persisted to AsyncStorage keys `@hiit/workouts` / `@hiit/sessions`, `hydrated` flag, seeds two example workouts on first launch. Consumed via `useWorkouts()`.
- `lib/SettingsContext.tsx` — `{ soundEnabled, hapticsEnabled, alertSound, theme }` persisted to `@hiit/settings`; effects push the theme into nativewind's `colorScheme.set()` and the cue flags into `configureCues()`. Consumed via `useSettings()`.
- `lib/calendar.ts` — pure, Jest-tested: `dayKey` (local `YYYY-MM-DD`), `monthMatrix` (Sunday-first weeks, 0-based month), `addMonths`, `monthTitle`. Used by `components/MonthCalendar.tsx`.
- `lib/encouragements.ts` — export `ENCOURAGEMENTS: string[]` (30 upbeat messages) and `randomEncouragement()` function. Imported by the run screen finish state.

### Styling
NativeWind lets you use `className` on any React Native core component. The Tailwind config scans `app/**` and `components/**`. All Tailwind directives live in `global.css`, which is imported once in `app/_layout.tsx`.

Do not use `StyleSheet.create` for new code — use `className` instead. Conditional classes must use fully-spelled-out class names in ternaries (not string concatenation), so NativeWind's static scanner can detect them.

**Theming (light pastel + dark)**: `components/AppBackground.tsx` is a gradient wash rendered behind every screen (the tabs layout provides it for both tabs — scenes are `transparent`; modal/fullscreen routes each render their own) — rose→lavender→sky in light, plum→indigo→navy in dark. Dark mode is driven by nativewind `colorScheme.set()` from the Settings theme (`app.json` has `userInterfaceStyle: "automatic"` so "System" tracks the device). Two mechanisms, use the right one:
- **className sites** use fully-spelled-out `dark:` variants. Conventions: text `text-ink dark:text-ink-dark` (opacity variants pair up, e.g. `text-ink/50 dark:text-ink-dark/50`); panels `bg-white/50 border-white/60` + `dark:bg-white/[0.07] dark:border-white/10`; pills `bg-white/40` + `dark:bg-white/[0.08]`; stepper buttons `bg-white/60` + `dark:bg-white/[0.12]`.
- **Non-className colors** (Ionicons `color`, gradients, blur tint, svg strokes, placeholderTextColor) come from `useThemeColors()` in `lib/theme.ts` — never hardcode `INK`/rgba inks in components. Accent `primary` (#A78BFA) and the interval pastels (`lib/colors.ts`) are shared by both themes.

### Liquid Glass surfaces — non-obvious rules
`components/Glass.tsx` is the surface primitive for **chrome and controls only** (tab bar pill, header buttons, run-screen controls): on **iOS 26+** it renders the native `GlassView` (`expo-glass-effect`); everywhere else a frosted `BlurView` (`expo-blur`, `tint="light"`) + faint white fill. Both ship in Expo Go on SDK 54.
- **Glass vs. panel split**: static *content* (workout cards, stat panels, editor rows, session rows) must NOT use `Glass` — native glass draws an un-disableable luminous rim. Use a plain `View className="rounded-3xl bg-white/50 border border-white/60 p-4"` panel instead.
- **`Glass` API**: corner radius and borders are **props, not classes** — `<Glass radius={20} bordered className="flex-row px-4">`. `className` carries layout/padding only (a `rounded-*` class rect-clips the native glass rim → jagged edges); `bordered` draws a `StyleSheet.hairlineWidth` overlay.
- **Never put an `opacity-*` utility on a `Glass` element or any ancestor** — native `GlassView` errors on sub-1 opacity. Plain panels are exempt.
- For many small repeated elements (interval pills, stepper buttons) use a cheap translucent `bg-white/40 border border-white/60` instead of a real `Glass`/blur per item, to avoid mounting dozens of blur views.

### Motion primitives (`react-native-reanimated`, Expo Go-safe)
- `components/PressableScale.tsx` — Pressable that springs to 0.97 while held. Scale lives on an inner `Animated.View` (plain `transform` style, not className — `Animated.View` isn't NativeWind-interop'd, same trap as `Glass`). Use for cards/buttons instead of `active:opacity-*`.
- `components/ProgressRing.tsx` — `react-native-svg` ring; `progress` is the **fraction remaining** (1 = full). Animated via `useAnimatedProps` on `strokeDashoffset` with a 140ms linear `withTiming`, so the 100ms timer ticks read as continuous motion.
- **Hydration fade-in**: data screens return a blank `<View className="flex-1" />` while `!hydrated` (from `useWorkouts`), then render their root with reanimated's `entering={FadeIn}` so user data doesn't flash empty before AsyncStorage responds.
- **Swipeable tabs**: `app/(tabs)/_layout.tsx` uses `@react-navigation/material-top-tabs` (via expo-router's `withLayoutContext`) pinned to the bottom (`tabBarPosition="bottom"`), so pages follow the finger (react-native-pager-view, Expo Go-safe). `components/GlassTabBar.tsx` renders the floating glass pill: measure each item's `onLayout`, spring a single absolute chip's `left`/`width`.
- **Drag reordering**: `react-native-sortables` (pure JS over reanimated + gesture-handler, Expo Go-safe; uses the already-installed `expo-haptics` automatically). Pattern: `Sortable.Grid columns={1}` inside a reanimated `Animated.ScrollView`, passing `scrollableRef={useAnimatedRef<Animated.ScrollView>()}` for auto-scroll; `onDragEnd={({ data }) => …}` hands back the reordered array. Rows containing `TextInput`s (editor intervals) must use `customHandle` + `Sortable.Handle` around a ☰ icon so dragging never fights text editing; plain cards (Workouts list) drag by long-press anywhere.
- **Confetti burst** (`components/Confetti.tsx`) — fireworks-style one-shot: 90 small pastel sparks in 3 staggered waves, ease-out radial explosion + quadratic gravity drift + late opacity fade. The component `absoluteFill`s its parent and bursts from the parent's **center** (zero-size origin view), so render it inside the relatively-positioned box that wraps the finish emoji.

### Key config files
- `babel.config.js` — sets `jsxImportSource: "nativewind"`, includes the `nativewind/babel` preset, and lists `react-native-worklets/plugin` **last** (reanimated v4 moved its babel plugin into `react-native-worklets`)
- `metro.config.js` — wraps default Expo config with `withNativeWind`, pointing at `global.css`
- `tailwind.config.js` — includes `nativewind/preset`, sets content paths, and defines the `ink`/`primary`/`pastel-*` color palette
- `nativewind-env.d.ts` / `assets.d.ts` — TypeScript types for `className` and `*.wav` asset imports
- `babel-preset-expo` and `jest-expo` are pinned to the SDK 54 line (`~54.x`) as direct devDependencies — a bare install resolves them to newer SDK majors
