# Review Fixes Design

## Goal

Fix every confirmed review finding without changing the app's visible workflow or replacing its existing SwiftUI, SwiftData, HealthKit, and WatchConnectivity architecture.

## Persistence

The app must never delete a persistent store merely because `ModelContainer` initialization failed. Startup will attempt the persistent container once. On failure it will create an in-memory container only so SwiftUI can render a blocking recovery screen; the normal app UI, seeding, and Watch sync will remain disabled.

User-initiated SwiftData mutations will use `do`/`catch`, roll back failed changes, show an alert, and only dismiss or push Watch updates after a successful save. Background seed and Watch-ingest failures will be logged and rolled back instead of being discarded silently.

## Historical accuracy

New `Session` records will store an optional snapshot of their workout intervals and repeat count. Phone and Watch completion paths will populate the snapshot, and the Watch payload will carry it as plist-safe encoded `Data`. Existing sessions remain migration-compatible because the snapshot is optional. Their detail screen may show the current workout only under the explicit heading “CURRENT INTERVAL MIX.”

History's “this week” count will use `Calendar.dateInterval(of: .weekOfYear, for:)` so locale, calendar boundaries, and daylight-saving transitions are respected.

## Timing and Watch lifecycle

`TimerEngine` will derive elapsed time from monotonic system uptime. An injectable time closure will allow lifecycle tests to advance time deterministically without sleeping.

HealthKit startup will use a request token. `end()` invalidates the token, so a late authorization callback cannot create an orphan workout session. Delegate failures and terminal states will clear the retained session.

Completed Watch sessions will be encoded into a small `UserDefaults` outbox before transmission. Activation flushes the outbox. Reachable delivery removes an item after the phone acknowledges it; unreachable delivery removes it after `transferUserInfo` accepts it into WatchConnectivity's durable queue. Phone-side UUID deduplication remains the final duplicate-delivery guard.

## Wire format and documentation

`SessionDTO.toDictionary()` will add optional values only after unwrapping them. This guarantees all payloads are valid property lists, including legacy/default DTOs. Support documentation will describe playback in silent mode accurately and match the actual overflow-menu workout deletion affordance.

## Verification

Regression unit tests will cover calendar-week boundaries, nil DTO fields and snapshots, session snapshot persistence, and monotonic timer lifecycle behavior. After the complete unit suite passes, a temporary XCUITest target will smoke-test launch and primary navigation in a dedicated simulator. The temporary target will then be removed and the Xcode project regenerated, per repository guidance.
