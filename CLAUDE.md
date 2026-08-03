# CLAUDE.md

Guidance for Claude Code (claude.ai/code) working in this repository.

## What this app is

A **HIIT interval timer** for iOS: build workouts as custom sequences of named, timed
intervals (each with its own color) repeated for N rounds, run them with a big ring
countdown plus sound + haptic cues, and review completed sessions in History (stats + habit
tracker month calendar). Workouts and intervals are drag-reorderable; Settings holds
sound/haptics toggles and a System/Light/Dark theme selector. All data is **local-only**
(SwiftData) — no accounts, no network.

This is a native rewrite of a former Expo/React Native app; behavior is preserved
screen-for-screen.

An **Apple Watch companion** (`IntervalTimerWatch/`) lists phone-created workouts and runs
them with full controls; workouts mirror phone→watch and finished watch runs land in the
phone's History via WatchConnectivity (still no network — device-to-device only). The watch
is always dark (watchOS has no light mode); no editing on watch.

A phone run shows a **Live Activity** (Lock Screen + Dynamic Island: current interval,
round, countdown) via the `IntervalTimerWidgets` extension, and keeps cue timing alive in
the background by looping silent audio (see Live Activity section).

## Stack

- **SwiftUI** (iOS 17.0 / watchOS 10.0 deployment targets), **SwiftData** for persistence
  (phone only — the watch caches Codable DTOs as JSON)
- **Swift 5**, Xcode 26
- No third-party packages. Project is generated from `project.yml` via **XcodeGen** — the
  `.xcodeproj` is git-ignored and regenerated, never edited by hand.
- Three targets: `IntervalTimer` (iOS), `IntervalTimerWatch` (watchOS companion, embedded
  via target dependency), and `IntervalTimerWidgets` (WidgetKit app extension for the run
  Live Activity, embedded appex). The watch target compiles a subset of the phone's
  sources directly (Models, Engine, Theme, Cues, Settings, Encouragements, Sync, Sounds)
  — listed file-by-file in `project.yml`; the widgets target compiles
  `RunActivityAttributes.swift` + `Theme/Palette.swift` from the phone sources.

## Commands

```bash
xcodegen generate                                                                    # regenerate .xcodeproj from project.yml (run after adding/removing files)
xcodebuild -project IntervalTimer.xcodeproj -scheme IntervalTimer \
  -destination 'platform=iOS Simulator,name=iPhone 17' build                         # build
xcodebuild test -project IntervalTimer.xcodeproj -scheme IntervalTimer \
  -destination 'platform=iOS Simulator,name=iPhone 17'                               # unit tests (pure logic)
xcodebuild -project IntervalTimer.xcodeproj -scheme IntervalTimerWatch \
  -destination 'generic/platform=watchOS Simulator' build                            # watch app build
```

Run on simulator:

```bash
APP=$(xcodebuild ... -showBuildSettings | grep -m1 BUILT_PRODUCTS_DIR | sed 's/.*= //')/IntervalTimer.app
xcrun simctl install booted "$APP" && xcrun simctl launch booted com.normanhoang.intervaltimer
xcrun simctl io booted screenshot shot.png
```

**Important:** after adding, removing, or renaming source files you must re-run
`xcodegen generate` before building, or the new files won't be in the project.

Device & release:

```bash
xcrun devicectl list devices                                                         # paired iPhones
xcodebuild -project IntervalTimer.xcodeproj -scheme IntervalTimer \
  -destination 'platform=iOS,id=<UDID>' -allowProvisioningUpdates build              # build for phone
xcrun devicectl device install app --device <UDID> <BUILT_PRODUCTS_DIR>/IntervalTimer.app
xcodebuild -project IntervalTimer.xcodeproj -scheme IntervalTimer -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/IntervalTimer.xcarchive \
  -allowProvisioningUpdates archive                                                  # Release archive
xcodebuild -exportArchive -archivePath build/IntervalTimer.xcarchive \
  -exportPath build/export -exportOptionsPlist build/exportOptions.plist             # IPA
```

Releasing: bump `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` in `project.yml` (then
`xcodegen generate`), and update the version table + "What's New" in
`docs/app-store-connect-info.md`.

## Simulators & UI verification

- The long-booted "iPhone 17" simulator is **shared with other automation** (other
  projects' UI tests launch their apps over yours mid-run). Boot a dedicated device
  (e.g. iPhone 17 Pro) for anything interactive, and shut it down after.
- "AppStore-6.5" sim (iPhone 11 Pro Max) exists for App Store screenshots (1242×2688,
  portrait) → saved in `docs/screenshots/`.
- Clicking the Simulator window with cliclick/AppleScript is unreliable. To drive the UI,
  add a **temporary XCUITest target** (`bundle.ui-testing` in `project.yml` + `xcodegen`),
  run it with `-only-testing:`, capture `xcrun simctl io <UDID> screenshot` from the shell
  while the test dwells, then delete the target and regenerate.
- XCUITest + SwiftUI quirks: buttons often report `isHittable == false` — tap
  `element.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5))` instead; a `Toggle`
  shows up as duplicate nested switch elements (pick one per row by frame position).
- Watch sims: a paired pair exists ("Watch S11 42mm (claude)" ↔ iPhone 17 Pro). If the
  watchOS platform is missing, `xcodebuild -downloadPlatform watchOS` first; create + pair
  via `xcrun simctl create` / `xcrun simctl pair`. The temporary-XCUITest pattern above
  works on watch sims too (same coordinate-tap quirk).

## Gotchas

- IDE/SourceKit diagnostics show false "Cannot find X in scope" errors across this
  xcodegen project — trust `xcodebuild` output instead.
- **`transferUserInfo` never delivers between paired simulators** (sender's `didFinish`
  even reports success). That's why `WatchSync.sendSession` uses `sendMessage` when
  reachable with `transferUserInfo` as fallback; the phone dedupes by session uuid. Test
  session sync on sims via the reachable path; queued delivery only on real devices.
- Installing the dev-signed watch app from the iPhone Watch app fails with "could not be
  installed at this time" unless (a) the **watch's UDID is in the provisioning profile**
  (check `security cms -D -i embedded.mobileprovision` → `ProvisionedDevices`; Xcode GUI
  registers watches, CLI builds don't) and (b) **Developer Mode is on** on the watch. The
  watch only becomes visible to `devicectl`/CLI after Xcode's Devices window has made first
  contact with it via the USB-connected phone.
- Watch sim clocks can be days off from the host — don't trust `completedAt` timestamps
  from sim-run sessions when eyeballing the History store.

## Architecture (`IntervalTimer/`)

- `IntervalTimerApp.swift` — `@main` + `PersistenceBootstrap`, which opens the SwiftData
  store and, when that fails, falls back to an in-memory container and shows
  `StoreRecoveryView` in place of the app (with an opt-in destructive "Reset local data"
  that deletes the store and reopens it — never automatic). Injects `AppSettings`, applies
  `preferredColorScheme`, seeds on first launch.

### Models (`Models/`)
- `Workout.swift` — `@Model Workout` (has `uuid`, `name`, `intervals: [Interval]`,
  `repeats`, `warmupSeconds`/`cooldownSeconds` (once-only segments, 0 = off) with
  `warmupColor`/`cooldownColor`, `createdAt`, `order`) and `@Model Session`. `Interval` is a `Codable` struct
  stored inline on the workout. **Note:** the domain id field is named `uuid`, not `id`,
  to avoid clashing with SwiftData/`Identifiable`. `order` gives the Workouts list a manual
  sort (SwiftData has no inherent order); reordering rewrites it.

### Engine (`Engine/`) — pure, unit-tested
- `Segment.swift` — `TimerEngineMath` namespace:
  `flattenWorkout(intervals:repeats:prerollSeconds:warmupSeconds:cooldownSeconds:warmupColor:cooldownColor:)`
  expands rounds (+ optional "Get ready" pre-roll and once-only warm up / cool down —
  all `round: 0`, `intervalIndex: -1`, so the ring hides the round counter for them)
  into `Segment`s with cumulative `startsAt`; `segmentAt(_:elapsed:)` (an elapsed exactly on a segment edge belongs to the
  **next** segment); `totalDuration`; `formatSeconds`.
- `TimerEngine.swift` — `@Observable`, **timestamp-based**: elapsed is always recomputed
  from a monotonic clock (`CLOCK_MONOTONIC_RAW`, which keeps counting while the device
  sleeps — `systemUptime` does not) minus accumulated pause time, so pauses/stalls never
  drift and wall-clock changes can't jump the run. The clock is injectable for tests
  (`init(segments:now:)`). A 100ms `Timer`
  only triggers `sync()`. Exposes `phase`, whole-second `remaining`, fractional `fraction`
  (drives the ring), `totalRemaining`, `pause/resume/skipNext/skipPrev`, and the
  `onSegmentChange` / `onCountdownTick` (last 3s) / `onFinish` callbacks (each fired as in
  the original RN engine).

### Stores & audio
- `Stores/Settings.swift` — `AppSettings` (`@Observable`) over `UserDefaults`; pushes flags
  into `Cues` on every change. Consumed via `@Environment(AppSettings.self)`. Shared with
  the watch (each device keeps its own defaults — watch mute is watch-local).
- `Stores/Seed.swift` — `seedIfNeeded` inserts "Tabata 20/10" and "Classic HIIT 40/20" the
  first time the store is empty.
- `Stores/PhoneSync.swift` — iOS half of watch sync (`WCSessionDelegate` singleton, holds
  the `ModelContainer`). `pushWorkouts()` snapshots the full workout list as JSON
  `[WorkoutDTO]` into `updateApplicationContext` (latest-wins); called from app launch,
  editor save/delete, and list reorder — **call it after any new workout mutation**.
  Receives finished watch sessions (message or userInfo), dedupes by uuid, inserts
  `Session`. Also answers live cue-relay messages from a watch run: replies with
  `secondaryAudioShouldBeSilencedHint` (not `isOtherAudioPlaying`, which false-positives
  on inaudible/mixable background sessions) and, when the phone *is* playing audio (e.g.
  music to AirPods), replays the beep locally via `Cues.playRelayedCue` so it mixes into
  that stream.
- `Audio/Cues.swift` — `Cues.shared` singleton: pooled `AVAudioPlayer`s (replay via
  `currentTime = 0`), `AVAudioSession(.playback, .mixWithOthers)`, and
  `UIImpact`/`UINotificationFeedbackGenerator` haptics. `initialize()`/`release()` on
  run-screen appear/disappear. `previewAlert` plays even when sound cues are off.
  Re-activates the audio session (re-asserting `.mixWithOthers`) after interruptions and
  route changes — nothing else recovers it. Platform-split with `#if os(watchOS)`: watch
  haptics via `WKInterfaceDevice.play` (click / notification / success); the AVFoundation
  half is shared. Cue-relay hooks: `playRelayedCue` (phone side, plays a watch-run beep
  ignoring the local sound toggle) and `phoneAudioActive` (watch side — while true the
  watch speaker stays quiet because the phone is beeping; never gates haptics).
  iOS-only `keepAwake(_:)` loops `silence.wav` while a run is active so iOS doesn't
  suspend the app in the background — the engine keeps ticking and beeps stay on-time
  when minimized/locked.
- `Audio/AlertSounds.swift` — the five selectable alert sounds (filenames in
  `Resources/Sounds/`).

### Sync (`Sync/`) — compiled into both targets
- `WorkoutDTO.swift` — Codable wire formats: `WorkoutDTO` (mirrors `Workout`, phone→watch)
  and `SessionDTO` (finished watch run, watch→phone). Both travel as a single JSON `Data`
  blob (plist-safe) under one key, so no field-by-field mapping.
- `SessionOutbox.swift` — thread-safe durable queue of `SessionDTO`s in UserDefaults. The
  watch holds a finished run until WatchConnectivity confirms delivery
  (`didFinish` for `transferUserInfo`, the reply for `sendMessage`); the phone holds a
  received run under its own key until it's committed to the store.
- `SyncKeys.swift` — payload key constants: applicationContext (includes a `Date`
  revision because identical dictionaries aren't re-sent), `session.payload`, and
  the live cue relay (`cue.kind`/`cue.alert` watch→phone, `cue.phoneAudio` in the reply).

### Live Activity (`LiveActivity/` + `IntervalTimerWidgets/`)
- `LiveActivity/RunActivityAttributes.swift` — `ActivityAttributes` payload (compiled into
  both the app and the widgets extension). `ContentState` carries label/color/round plus
  `segmentStart…segmentEnd` dates — the OS renders the ticking countdown from the date
  range, so no per-second updates; `frozenRemaining` non-nil while paused.
- `LiveActivity/RunLiveActivityController.swift` — singleton lifecycle wrapper
  (`start`/`update`/`end`); `start` first ends any activity left over from a previous
  run/process. `RunScreen` starts it on appear, updates on segment change and
  pause/resume/skip, ends on disappear. Requires `NSSupportsLiveActivities` in the app's
  `Info.plist`.
- `IntervalTimerWidgets/` — the extension target: `IntervalTimerWidgetsBundle.swift`
  (`@main`) + `RunLiveActivity.swift` (lock-screen card and Dynamic Island
  expanded/compact/minimal presentations).

### Util & theme
- `Util/CalendarMath.swift` — pure, unit-tested: `dayKey`, `monthMatrix` (Sunday-first,
  **1-based** month), `addMonths`, `streakLength`, `bestStreak`, `weekDays`, `monthTitle`.
- `Util/Encouragements.swift` — 30 finish messages + `random()`.
- `Theme/Palette.swift` — interval color hexes, `isLight`, `Color(hex:)`, the run
  screen's flood gradients (`floodStops`/`floodDeep`, hand-tuned for work/rest and
  derived in HSB for the rest), `darkStep` (interval color as text on light) and
  `role(forColor:)` (the editor's "Work"/"Recovery" sub-line — the exercise name itself
  is `Interval.label`).
- `Theme/Theme.swift` — `ThemeSetting` (System/Light/Dark → `colorScheme`) and
  `ThemeColors` tokens per scheme (`ThemeColors.for(colorScheme)`), accessed in views via
  `@Environment(\.colorScheme)`: ink/card/accent/destructive/streak values for the
  dark-first 1.7 design.

### Components (`Components/`)
- `AppBackground` (gradient wash + `.appBackground()` modifier), `GlassSurface`
  (`.glassChrome()` = native `glassEffect` on iOS 26 / `.ultraThinMaterial` fallback for
  chrome; `.card()` = the redesign's card fill/border/shadow; `.panel()` = older
  translucent fill), `PressableScaleStyle` (`.buttonStyle(.pressableScale)`),
  `ProgressRing` (trimmed circle, `progress` = fraction remaining), `IntervalMixBar`
  (proportional color bar), `SegmentBar` (one sliver per flattened run segment),
  `WeekStrip` (History's week row + Month expander), `MonthCalendar`, `DurationWheel`
  (3 wheel pickers), `Confetti` (`TimelineView`/`Canvas` particle burst), `EditorTarget`.

### Screens (`Screens/`)
- `RootTabView` — `TabView`: Workouts + History.
- `WorkoutsScreen` — header (Settings gear, accent New pill), reorderable `List` of
  workout cards (play button → `RunScreen` fullScreenCover; card tap → editor sheet;
  long-press drag reorders; `⋯` menu = Duplicate / Edit / Delete).
- `WorkoutEditorScreen` — sheet; name, rounds stepper (1–99), independent warm-up /
  cool-down toggle rows (duration wheel, 60s default on enable, tappable color swatch →
  picker sheet), interval `List` (`.onMove` reorder + `.swipeActions` delete), per-row color/duration
  sheets (`.presentationDetents`; closing a 0s duration clamps to 1s), total footer,
  save/delete.
- `RunScreen` — fullScreenCover, keep-awake (`isIdleTimerDisabled` + `Cues.keepAwake`
  background audio), Live Activity start/update/end (see Live Activity section), 3s
  pre-roll. Two styles picked by `AppSettings.runStyle`: **Flood** (default — the interval
  color fills the screen as a cross-fading gradient, white chrome) and **Ring** (app
  gradient + `ProgressRing`). Both show round / exercise name / next-up / `SegmentBar` /
  controls / header mute. On finish: confetti + encouragement + summary card (duration,
  intervals, day streak) + Done + Repeat. Each completion inserts a `Session` carrying
  interval counts and pause count; ending early still records nothing.
- `HistoryScreen` — streak hero (current + `CalendarMath.bestStreak`), three stat tiles
  (durations as "24 min", never "24:00"), `WeekStrip` with a Month expander that swaps in
  the existing `MonthCalendar` (any day tappable — selection filters the list), session
  list shows one day at a time and defaults to today (reset every time the tab appears),
  rows show a color spine + completion detail and push `SessionDetailScreen`;
  swipe-to-delete, Clear history (clear day or all).
- `SettingsScreen` — sheet: appearance pills, Sound/Haptics toggles, Run screen picker
  (Flood / Ring), alert-sound list (tap = select + preview).
- `SessionDetailScreen` — pushed from a History row: duration, intervals, pauses and the
  workout's interval mix (looked up by `workoutId`; degrades if it was deleted).

### Resources
- `Resources/Sounds/` — five `alert-*.wav` + `tick.wav` + `finish.wav` + `silence.wav`
  (the keep-awake loop; bundled, loaded by
  filename; also bundled into the watch app). `Resources/Assets.xcassets` — single-size
  `AppIcon` + `AccentColor` (#A78BFA).

## Watch app (`IntervalTimerWatch/`)

- `IntervalTimerWatchApp.swift` — `@main`; watch-local `AppSettings`; activates `WatchSync`;
  `NavigationStack` root.
- `WatchSync.swift` — watch half of sync: applies `receivedApplicationContext` on
  activation (catches pushes made while the app was closed) + live context updates into
  `WorkoutStore`; `sendSession` = `sendMessage` when reachable, else/on-error
  `transferUserInfo` (see Gotchas); `sendCue` relays each run beep to the phone
  (`sendMessage` only — a late cue is noise, so no queued fallback) and sets
  `Cues.phoneAudioActive` from the reply so exactly one device beeps.
- `WorkoutStore.swift` — `@Observable` singleton; `[WorkoutDTO]` sorted by `order`,
  persisted as JSON in Application Support so the list works offline at launch.
- `WorkoutSessionController.swift` — `HKWorkoutSession` (`.highIntensityIntervalTraining`)
  purely as wrist-down keep-alive during a run; **no builder attached, nothing written to
  Health**; no-op on simulator (auth sheet blocks automation). Needs the HealthKit
  entitlement + `WKBackgroundModes: workout-processing` (in `project.yml` / `Info.plist`).
- `Views/WorkoutsListView.swift` — workout rows (name, duration, interval color dots);
  empty state points to the iPhone.
- `Views/WatchRunView.swift` — condensed `RunScreen` mirror on a single combined page,
  always flood (the watch has no run-style setting): interval-color gradient face, top
  control row (End w/ confirm, mute, pause), countdown at 30fps, round, next-up,
  `LinearProgressBar`, total remaining, skip± row. Same engine/cues wiring, plus each cue is
  relayed to the phone via `WatchSync.sendCue` (see Sync). Finish view (encouragement /
  Done / Repeat). Recording sends a `SessionDTO` instead of touching SwiftData. Back-swipe
  is disabled mid-run — End is the only exit.
- `Views/LinearProgressBar.swift` — horizontal watch-only replacement for the phone's
  circular `ProgressRing` (frees vertical space for the combined run page).

## Tests (`IntervalTimerTests/`)
`TimerTests`, `CalendarTests` and `PaletteTests` cover the pure engine/calendar/color math
(the first two ported from the
original Jest suite). Run them after touching anything in `Engine/` or `Util/`.
`ProgressRingTests` renders the ring via `ImageRenderer` and pixel-checks that depletion
starts at top center (guards the round-cap overhang regression).
