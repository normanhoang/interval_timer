# Graph Report - .  (2026-07-04)

## Corpus Check
- 50 files · ~202,428 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 399 nodes · 806 edges · 21 communities (18 shown, 3 thin omitted)
- Extraction: 93% EXTRACTED · 7% INFERRED · 0% AMBIGUOUS · INFERRED: 59 edges (avg confidence: 0.84)
- Token cost: 135,682 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_History Screen & Sessions|History Screen & Sessions]]
- [[_COMMUNITY_Month Calendar & Calendar Math|Month Calendar & Calendar Math]]
- [[_COMMUNITY_Segment Math & Workout Flattening|Segment Math & Workout Flattening]]
- [[_COMMUNITY_Settings & Alert Sounds|Settings & Alert Sounds]]
- [[_COMMUNITY_Background & Input Components|Background & Input Components]]
- [[_COMMUNITY_Progress Ring & Confetti|Progress Ring & Confetti]]
- [[_COMMUNITY_Workout Data Models|Workout Data Models]]
- [[_COMMUNITY_Timer Phases & App Settings|Timer Phases & App Settings]]
- [[_COMMUNITY_Audio Cues Engine|Audio Cues Engine]]
- [[_COMMUNITY_Timer Engine Core|Timer Engine Core]]
- [[_COMMUNITY_Glass Surface Styling|Glass Surface Styling]]
- [[_COMMUNITY_Palette & App Icon Identity|Palette & App Icon Identity]]
- [[_COMMUNITY_History Screenshot UI|History Screenshot UI]]
- [[_COMMUNITY_Workouts Screenshot & Seeding|Workouts Screenshot & Seeding]]
- [[_COMMUNITY_App Store & Privacy Docs|App Store & Privacy Docs]]
- [[_COMMUNITY_FlexWrap Layout|FlexWrap Layout]]
- [[_COMMUNITY_Engine Design Rationale|Engine Design Rationale]]
- [[_COMMUNITY_XcodeGen Project Config|XcodeGen Project Config]]
- [[_COMMUNITY_Silent-Mode Audio FAQ|Silent-Mode Audio FAQ]]
- [[_COMMUNITY_Seed Workouts Note|Seed Workouts Note]]
- [[_COMMUNITY_Whats New 1.2|Whats New 1.2]]

## God Nodes (most connected - your core abstractions)
1. `ThemeColors` - 43 edges
2. `WorkoutEditorScreen` - 28 edges
3. `TimerEngine` - 23 edges
4. `Interval` - 23 edges
5. `HistoryScreen` - 21 edges
6. `RunScreen` - 21 edges
7. `Color` - 19 edges
8. `SwiftUI` - 18 edges
9. `Segment` - 17 edges
10. `TimerTests` - 17 edges

## Surprising Connections (you probably didn't know these)
- `Session Row: 'Tabata 20/10', 3:21PM, duration 4:00` --shares_data_with--> `Session`  [INFERRED]
  docs/screenshots/6.5in-history.png → IntervalTimer/Models/Workout.swift
- `Habit Tracker Month Calendar (July 2026, Sunday-first, chevron month nav, selected day 2 highlighted in purple)` --implements--> `MonthCalendar`  [INFERRED]
  docs/screenshots/6.5in-history.png → IntervalTimer/Components/MonthCalendar.swift
- `History Screen App Store Screenshot (6.5in)` --implements--> `HistoryScreen`  [INFERRED]
  docs/screenshots/6.5in-history.png → IntervalTimer/Screens/HistoryScreen.swift
- `App Store Screenshot: Workouts Screen (6.5in)` --references--> `WorkoutsScreen`  [INFERRED]
  docs/screenshots/6.5in-workouts.png → IntervalTimer/Screens/WorkoutsScreen.swift
- `Interval Bars Motif` --semantically_similar_to--> `IntervalMixBar`  [INFERRED] [semantically similar]
  IntervalTimer/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png → IntervalTimer/Components/IntervalMixBar.swift

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Local-Only / No-Network Privacy Posture** — claude_swiftdata_local_persistence, docs_privacy_local_only_storage, docs_app_store_connect_info_data_not_collected [INFERRED 0.85]
- **Release Versioning Flow (project.yml -> listing doc)** — claude_release_process, project_base_settings, docs_app_store_connect_info_listing [EXTRACTED 1.00]
- **App Store Submission Surface (listing, policy, support pages)** — docs_app_store_connect_info_listing, docs_privacy_privacy_policy, docs_support_support_page, docs_app_store_connect_info_github_pages_setup [EXTRACTED 1.00]
- **App Icon Visual Identity: colored interval pills on dark gradient** — intervaltimer_resources_assets_xcassets_appicon_appiconset_icon_1024_appicon, intervaltimer_resources_assets_xcassets_appicon_appiconset_icon_1024_intervalbarsmotif, intervaltimer_resources_assets_xcassets_appicon_appiconset_icon_1024_darkgradientbackground, intervaltimer_resources_assets_xcassets_appicon_appiconset_icon_1024_colorcodedintervals [EXTRACTED 1.00]
- **History habit-tracking flow: completed Session records feed the stat panels, month calendar day marks, and the grouped session list on one screen** — docs_screenshots_6_5in_history_stats_grid, docs_screenshots_6_5in_history_month_calendar_ui, docs_screenshots_6_5in_history_session_list, intervaltimer_models_workout_session [INFERRED 0.85]
- **Workout card composition pattern: name + duration/rounds meta, tappable play affordance, proportional color mix bar, and per-interval chips together summarize a workout at a glance** — docs_screenshots_6_5in_workouts_workout_card, docs_screenshots_6_5in_workouts_play_button, docs_screenshots_6_5in_workouts_interval_mix_bar, docs_screenshots_6_5in_workouts_interval_chips [EXTRACTED 1.00]

## Communities (21 total, 3 thin omitted)

### Community 0 - "History Screen & Sessions"
Cohesion: 0.07
Nodes (24): EditMode, IndexSet, HistoryScreen, Date, DateFormatter, Int, Set, String (+16 more)

### Community 1 - "Month Calendar & Calendar Math"
Cohesion: 0.09
Nodes (18): MonthCalendar, Binding, Bool, Date, Int, Set, String, Void (+10 more)

### Community 2 - "Segment Math & Workout Flattening"
Cohesion: 0.11
Nodes (9): IntervalTimer, SegmentPosition, Bool, Double, Int, TimerEngineMath, Int, TimerTests (+1 more)

### Community 3 - "Settings & Alert Sounds"
Cohesion: 0.08
Nodes (21): App, CaseIterable, AlertSound, AlertSounds, String, IntervalTimerApp, SettingsScreen, Binding (+13 more)

### Community 4 - "Background & Input Components"
Cohesion: 0.10
Nodes (16): Configuration, AppBackground, View, DurationWheel, Binding, Int, String, ButtonStyle (+8 more)

### Community 5 - "Progress Ring & Confetti"
Cohesion: 0.13
Nodes (18): Equatable, Confetti, Spark, Double, Int, ProgressRing, CGFloat, Content (+10 more)

### Community 6 - "Workout Data Models"
Cohesion: 0.16
Nodes (17): Codable, Hashable, Identifiable, EditorTarget, edit, new, String, Interval (+9 more)

### Community 7 - "Timer Phases & App Settings"
Cohesion: 0.10
Nodes (16): CGColor, CoreGraphics, Foundation, ImageIO, TimerPhase, done, paused, running (+8 more)

### Community 8 - "Audio Cues Engine"
Cohesion: 0.17
Nodes (6): AVAudioPlayer, AVFoundation, Cues, Bool, String, UIKit

### Community 9 - "Timer Engine Core"
Cohesion: 0.23
Nodes (7): Date, Double, Int, Void, TimerEngine, TimeInterval, Timer

### Community 10 - "Glass Surface Styling"
Cohesion: 0.23
Nodes (9): ColorScheme, GlassChrome, Panel, Bool, CGFloat, Content, View, View (+1 more)

### Community 11 - "Palette & App Icon Identity"
Cohesion: 0.17
Nodes (10): IntervalMixBar, CGFloat, App Icon (1024px), Color-Coded Interval Durations, Dark Navy-Purple Gradient Background, Interval Bars Motif, Palette, Bool (+2 more)

### Community 12 - "History Screenshot UI"
Cohesion: 0.16
Nodes (14): Screen Header ('INTERVAL PULSE TIMER' eyebrow + large 'History' title), Clear History Button (destructive red text action), Day Streak Stat Panel (flame icon, value 1), Design Pattern: Translucent Rounded Glass Cards on Pastel Gradient Wash, History Screen App Store Screenshot (6.5in), Habit Tracker Month Calendar (July 2026, Sunday-first, chevron month nav, selected day 2 highlighted in purple), Sessions List Grouped by Day ('Today' header with session card), Session Row: 'Tabata 20/10', 3:21PM, duration 4:00 (+6 more)

### Community 13 - "Workouts Screenshot & Seeding"
Cohesion: 0.21
Nodes (12): Classic HIIT 40/20 workout entry (6:00 total, 6 rounds, Work 0:40 / Rest 0:20), Soft pastel gradient wash background (pink top to blue bottom, light theme), Header: 'INTERVAL PULSE TIMER' eyebrow, large 'Workouts' title, Settings gear, '+ New' pill button, Interval Chips (pill chips with color dot + name + duration, e.g. 'Work 0:20', 'Rest 0:10'), Interval Mix Bar (horizontal bar split proportionally by interval color/duration: red work vs teal rest), Green circular Play button (per-card, launches Run screen), App Store Screenshot: Workouts Screen (6.5in), Floating pill Tab Bar (Workouts bolt icon selected in purple accent, History calendar icon) (+4 more)

### Community 14 - "App Store & Privacy Docs"
Cohesion: 0.20
Nodes (12): HIIT Interval Timer App (Interval Pulse Timer), Release Version-Bump Process, SwiftData Local-Only Persistence, Workout order Field for Manual Sort, Workout Domain ID Named uuid, App Privacy: Data Not Collected, GitHub Pages Hosting Setup for Policy/Support URLs, App Store Connect Listing — Interval Pulse Timer (+4 more)

### Community 15 - "FlexWrap Layout"
Cohesion: 0.31
Nodes (7): CGRect, CGSize, FlexWrap, CGFloat, Layout, ProposedViewSize, Subviews

### Community 16 - "Engine Design Rationale"
Cohesion: 0.33
Nodes (6): flattenWorkout Segment Expansion (TimerEngineMath), RunScreen Keep-Awake & Finish Flow, TimerEngine Timestamp-Based Design, Warm-up / Cool-down Once-Only Segments, What's New 1.1 — Warm-up/Cool-down & Repeat Workout, FAQ: Screen Stays Awake During Workout (isIdleTimerDisabled)

### Community 17 - "XcodeGen Project Config"
Cohesion: 0.67
Nodes (3): XcodeGen Project Generation, IntervalTimer App Target, IntervalTimerTests Unit-Test Target

## Knowledge Gaps
- **36 isolated node(s):** `AVFoundation`, `UIKit`, `new`, `edit`, `running` (+31 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `RunScreen` connect `Progress Ring & Confetti` to `History Screen & Sessions`, `Segment Math & Workout Flattening`, `Background & Input Components`, `Workout Data Models`, `Timer Phases & App Settings`, `Audio Cues Engine`, `Timer Engine Core`?**
  _High betweenness centrality (0.119) - this node is a cross-community bridge._
- **Why does `ThemeColors` connect `History Screen & Sessions` to `Month Calendar & Calendar Math`, `Settings & Alert Sounds`, `Progress Ring & Confetti`, `Timer Engine Core`, `Glass Surface Styling`?**
  _High betweenness centrality (0.103) - this node is a cross-community bridge._
- **Why does `SwiftUI` connect `Background & Input Components` to `History Screen & Sessions`, `Month Calendar & Calendar Math`, `Settings & Alert Sounds`, `Progress Ring & Confetti`, `Workout Data Models`, `Glass Surface Styling`, `Palette & App Icon Identity`?**
  _High betweenness centrality (0.098) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `Interval` (e.g. with `seedIfNeeded()` and `.testSkipsZeroSecondIntervals()`) actually correct?**
  _`Interval` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `AVFoundation`, `UIKit`, `new` to the rest of the system?**
  _41 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `History Screen & Sessions` be split into smaller, more focused modules?**
  _Cohesion score 0.07490079365079365 - nodes in this community are weakly interconnected._
- **Should `Month Calendar & Calendar Math` be split into smaller, more focused modules?**
  _Cohesion score 0.08710801393728224 - nodes in this community are weakly interconnected._