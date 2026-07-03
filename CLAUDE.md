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

## Stack

- **SwiftUI** (iOS 17.0 deployment target), **SwiftData** for persistence
- **Swift 5**, Xcode 26
- No third-party packages. Project is generated from `project.yml` via **XcodeGen** — the
  `.xcodeproj` is git-ignored and regenerated, never edited by hand.

## Commands

```bash
xcodegen generate                                                                    # regenerate .xcodeproj from project.yml (run after adding/removing files)
xcodebuild -project IntervalTimer.xcodeproj -scheme IntervalTimer \
  -destination 'platform=iOS Simulator,name=iPhone 17' build                         # build
xcodebuild test -project IntervalTimer.xcodeproj -scheme IntervalTimer \
  -destination 'platform=iOS Simulator,name=iPhone 17'                               # unit tests (pure logic)
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

## Gotchas

- IDE/SourceKit diagnostics show false "Cannot find X in scope" errors across this
  xcodegen project — trust `xcodebuild` output instead.

## Architecture (`IntervalTimer/`)

- `IntervalTimerApp.swift` — `@main`, builds the SwiftData `ModelContainer` (wipes &
  recreates the store if a schema change makes it unloadable — dev convenience), injects
  `AppSettings`, applies `preferredColorScheme`, seeds on first launch.

### Models (`Models/`)
- `Workout.swift` — `@Model Workout` (has `uuid`, `name`, `intervals: [Interval]`,
  `repeats`, `warmupSeconds`/`cooldownSeconds` (once-only segments, 0 = off),
  `createdAt`, `order`) and `@Model Session`. `Interval` is a `Codable` struct
  stored inline on the workout. **Note:** the domain id field is named `uuid`, not `id`,
  to avoid clashing with SwiftData/`Identifiable`. `order` gives the Workouts list a manual
  sort (SwiftData has no inherent order); reordering rewrites it.

### Engine (`Engine/`) — pure, unit-tested
- `Segment.swift` — `TimerEngineMath` namespace:
  `flattenWorkout(intervals:repeats:prerollSeconds:warmupSeconds:cooldownSeconds:)`
  expands rounds (+ optional "Get ready" pre-roll and once-only warm up / cool down —
  all `round: 0`, `intervalIndex: -1`, so the ring hides the round counter for them)
  into `Segment`s with cumulative `startsAt`; `segmentAt(_:elapsed:)` (an elapsed exactly on a segment edge belongs to the
  **next** segment); `totalDuration`; `formatSeconds`.
- `TimerEngine.swift` — `@Observable`, **timestamp-based**: elapsed is always recomputed
  from `Date()` minus accumulated pause time, so pauses/stalls never drift. A 100ms `Timer`
  only triggers `sync()`. Exposes `phase`, whole-second `remaining`, fractional `fraction`
  (drives the ring), `totalRemaining`, `pause/resume/skipNext/skipPrev`, and the
  `onSegmentChange` / `onCountdownTick` (last 3s) / `onFinish` callbacks (each fired as in
  the original RN engine).

### Stores & audio
- `Stores/Settings.swift` — `AppSettings` (`@Observable`) over `UserDefaults`; pushes flags
  into `Cues` on every change. Consumed via `@Environment(AppSettings.self)`.
- `Stores/Seed.swift` — `seedIfNeeded` inserts "Tabata 20/10" and "Classic HIIT 40/20" the
  first time the store is empty.
- `Audio/Cues.swift` — `Cues.shared` singleton: pooled `AVAudioPlayer`s (replay via
  `currentTime = 0`), `AVAudioSession(.playback, .mixWithOthers)`, and
  `UIImpact`/`UINotificationFeedbackGenerator` haptics. `initialize()`/`release()` on
  run-screen appear/disappear. `previewAlert` plays even when sound cues are off.
- `Audio/AlertSounds.swift` — the five selectable alert sounds (filenames in
  `Resources/Sounds/`).

### Util & theme
- `Util/CalendarMath.swift` — pure, unit-tested: `dayKey`, `monthMatrix` (Sunday-first,
  **1-based** month), `addMonths`, `streakLength`, `monthTitle`.
- `Util/Encouragements.swift` — 30 finish messages + `random()`.
- `Theme/Palette.swift` — interval color hexes, `isLight`, and `Color(hex:)`.
- `Theme/Theme.swift` — `ThemeSetting` (System/Light/Dark → `colorScheme`) and
  `ThemeColors` tokens per scheme (`ThemeColors.for(colorScheme)`), accessed in views via
  `@Environment(\.colorScheme)`.

### Components (`Components/`)
- `AppBackground` (gradient wash + `.appBackground()` modifier), `GlassSurface`
  (`.glassChrome()` = native `glassEffect` on iOS 26 / `.ultraThinMaterial` fallback for
  chrome; `.panel()` = translucent fill for static content), `PressableScaleStyle`
  (`.buttonStyle(.pressableScale)`), `ProgressRing` (trimmed circle, `progress` = fraction
  remaining), `IntervalMixBar` (proportional color bar), `MonthCalendar`, `DurationWheel`
  (3 wheel pickers), `Confetti` (`TimelineView`/`Canvas` particle burst), `FlexWrap`
  (wrapping `Layout` for chips) + `EditorTarget`.

### Screens (`Screens/`)
- `RootTabView` — `TabView`: Workouts + History.
- `WorkoutsScreen` — header (Settings gear, New), reorderable `List` of workout cards (play
  button → `RunScreen` fullScreenCover; card tap → editor sheet; `EditButton` toggles
  drag-reorder).
- `WorkoutEditorScreen` — sheet; name, rounds stepper (1–99), independent warm-up /
  cool-down toggle rows (fixed label+color, duration wheel, 60s default on enable),
  interval `List` (`.onMove` reorder + `.swipeActions` delete), per-row color/duration
  sheets (`.presentationDetents`; closing a 0s duration clamps to 1s), total footer,
  save/delete.
- `RunScreen` — fullScreenCover, keep-awake (`isIdleTimerDisabled`), 3s pre-roll, ring +
  round/next-up + total-progress bar + controls + header mute. On finish: confetti +
  random encouragement + Done + "Repeat workout" (rebuilds the engine and re-runs from
  the pre-roll; each completion inserts its own `Session`). Ending early records nothing.
- `HistoryScreen` — stat panels (streak / this-week / total workouts / total time),
  `MonthCalendar` (tap a marked day to filter, "Show all" clears), sessions grouped
  Today/Yesterday/weekday with swipe-to-delete, Clear history (clear day or all).
- `SettingsScreen` — sheet: appearance pills, Sound/Haptics toggles, alert-sound list
  (tap = select + preview).

### Resources
- `Resources/Sounds/` — five `alert-*.wav` + `tick.wav` + `finish.wav` (bundled, loaded by
  filename). `Resources/Assets.xcassets` — single-size `AppIcon` + `AccentColor` (#A78BFA).

## Tests (`IntervalTimerTests/`)
`TimerTests` and `CalendarTests` cover the pure engine/calendar math (ported from the
original Jest suite). Run them after touching anything in `Engine/` or `Util/`.
