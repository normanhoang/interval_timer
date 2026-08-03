# Review Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Correct the confirmed persistence, history, timer, Watch lifecycle/transfer, DTO, and support-document findings with regression coverage.

**Architecture:** Keep the existing app structure. Add only two focused seams: optional session workout snapshots at the model/wire boundary, and a durable Watch outbox at the connectivity boundary. Make time injectable inside the existing timer and handle persistence errors at their existing UI action sites.

**Tech Stack:** Swift 5, SwiftUI, SwiftData, XCTest, HealthKit, WatchConnectivity, XcodeGen; iOS 17.0 and watchOS 10.0.

## Global Constraints

- Preserve existing user data; never delete a SwiftData store during startup recovery.
- Preserve current screens and navigation.
- Keep new session fields optional for lightweight migration of existing stores.
- Add no third-party dependencies.
- Do not commit unless the user explicitly requests a commit.

---

### Task 1: Pure regression seams

**Files:**
- Modify: `IntervalTimer/Util/CalendarMath.swift`
- Modify: `IntervalTimer/Sync/WorkoutDTO.swift`
- Modify: `IntervalTimer/Sync/SyncKeys.swift`
- Modify: `IntervalTimer/Engine/TimerEngine.swift`
- Modify: `IntervalTimerTests/CalendarTests.swift`
- Modify: `IntervalTimerTests/TimerTests.swift`
- Create: `IntervalTimerTests/SyncTests.swift`

**Interfaces:**
- Produces: `CalendarMath.countInCurrentWeek(_:now:calendar:) -> Int`
- Produces: `TimerEngine.init(segments:now:)` with a monotonic default closure
- Produces: plist-safe `SessionDTO.toDictionary()` and Codable DTO snapshots

- [ ] Add a calendar test with Sunday, Saturday, and prior-week dates; run it and confirm the missing helper fails compilation.
- [ ] Implement `countInCurrentWeek` using the calendar's `.weekOfYear` interval; rerun the test and confirm it passes.
- [ ] Add DTO tests that validate a nil-optionals payload with `PropertyListSerialization` and round-trip snapshot data; run and confirm the current dictionary fails validation or lacks the new API.
- [ ] Build the dictionary incrementally with unwrapped optionals and encode snapshot intervals as `Data`; rerun the DTO tests.
- [ ] Add deterministic timer tests that advance an injected uptime value through start, pause, resume, skip, and finish; run and confirm the current initializer/API is missing.
- [ ] Replace wall-clock `Date` state in `TimerEngine` with injected monotonic seconds and make `sync()` testable at module scope; rerun timer tests and the complete unit suite.

### Task 2: Persistence safety and historical snapshots

**Files:**
- Modify: `IntervalTimer/IntervalTimerApp.swift`
- Modify: `IntervalTimer/Models/Workout.swift`
- Modify: `IntervalTimer/Screens/RunScreen.swift`
- Modify: `IntervalTimer/Screens/HistoryScreen.swift`
- Modify: `IntervalTimer/Screens/SessionDetailScreen.swift`
- Modify: `IntervalTimer/Screens/WorkoutEditorScreen.swift`
- Modify: `IntervalTimer/Screens/WorkoutsScreen.swift`
- Modify: `IntervalTimer/Stores/Seed.swift`
- Modify: `IntervalTimer/Stores/PhoneSync.swift`
- Create: `IntervalTimerTests/PersistenceTests.swift`

**Interfaces:**
- Produces: optional `Session.workoutIntervals` and `Session.workoutRepeats`
- Produces: startup state that either exposes a persistent container or a blocking error
- Consumes: `CalendarMath.countInCurrentWeek` and DTO snapshot fields from Task 1

- [ ] Add an in-memory SwiftData test that saves and reloads a session snapshot; run and confirm the model initializer lacks snapshot fields.
- [ ] Add optional snapshot properties and initializer arguments to `Session`; populate them in phone runs and Watch ingestion; rerun the persistence test.
- [ ] Render snapshot data in History/detail views, fall back to an explicitly current workout for legacy sessions, and use calendar-week counting.
- [ ] Replace startup deletion with a single persistent attempt plus an in-memory rendering fallback and blocking error screen.
- [ ] Replace mutation-site `try? context.save()` calls with `do`/`catch`; roll back, surface actionable UI errors, and gate dismissal/Watch pushes on success.
- [ ] Make seeding and phone ingestion log and roll back save failures; run all unit tests and an iOS/watch build.

### Task 3: Watch authorization and durable delivery

**Files:**
- Modify: `IntervalTimerWatch/WorkoutSessionController.swift`
- Modify: `IntervalTimerWatch/WatchSync.swift`
- Modify: `IntervalTimerWatch/Views/WatchRunView.swift`
- Modify: `IntervalTimerTests/SyncTests.swift`

**Interfaces:**
- Produces: authorization request-token cancellation in `WorkoutSessionController`
- Produces: a Codable `SessionOutbox` that queues before sending and flushes after activation
- Consumes: plist-safe `SessionDTO` from Task 1

- [ ] Add outbox tests proving enqueue survives reconstruction, removal is UUID-specific, and malformed stored data recovers as an empty queue; run and confirm `SessionOutbox` is missing.
- [ ] Implement the minimal `UserDefaults`-backed outbox and rerun its tests.
- [ ] Queue `SessionDTO` before transport, flush on activation, acknowledge live messages, and fall back to `transferUserInfo`; keep phone UUID deduplication.
- [ ] Add a request token to HealthKit authorization, invalidate it in `end()`, and clear matching sessions on delegate failure or terminal state.
- [ ] Build the Watch target and run the complete unit suite.

### Task 4: Documentation and UI verification

**Files:**
- Modify: `docs/support.html`
- Temporarily create and remove: `IntervalTimerUITests/SmokeTests.swift`
- Temporarily modify and restore: `project.yml`

**Interfaces:**
- Consumes: the finished application behavior from Tasks 1–3

- [ ] Correct silent-mode and workout-deletion support copy.
- [ ] Run the complete unit-test suite and require zero failures.
- [ ] Add the temporary XCUITest target and regenerate the project.
- [ ] Start the UI smoke test in a background `xcodebuild` session, then review the source diff while it runs.
- [ ] Confirm UI-test completion, remove the temporary target/source, regenerate the project, and verify the final project builds.
- [ ] Run static analysis, inspect the final diff/status, and report exact test counts and any remaining limitations.
