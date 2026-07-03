# App Store Connect — Submission Info

Everything needed to fill out the App Store Connect listing for Interval Pulse Timer.

## App Information

| Field | Value |
|---|---|
| App Name | Interval Pulse Timer |
| Subtitle | HIIT & custom interval timer |
| Bundle ID | `com.normanhoang.intervaltimer` |
| SKU | `com-normanhoang-intervaltimer-20260630` (or any unique string — only used internally) |
| Primary Category | Health & Fitness |
| Secondary Category | Sports (optional) |
| Team / Apple Developer | DZRPJF9JB6 |
| Version (Marketing) | 1.2 |
| Build number | 3 |
| Price | Free (or your choice) |
| Copyright | © 2026 Norman Hoang |

## URLs

| Field | Value |
|---|---|
| Privacy Policy URL | `https://normanhoang.github.io/interval_timer/privacy.html` |
| Support URL | `https://normanhoang.github.io/interval_timer/support.html` |
| Marketing URL | optional, can reuse support URL |

**Setup needed:** GitHub Pages isn't live yet. In the repo: Settings → Pages → Source: Deploy
from branch → `main` / folder `/docs`. Pages only serves from `main` (or `gh-pages`), so
merge this branch into `main` before enabling, or point Pages at `swift-rewrite` if you'd
rather not merge yet.

## Age Rating

No objectionable content, no user-generated content, no web access, no gambling. Answer
"None" to all Age Rating questionnaire content categories → results in **4+**.

## App Privacy (App Store Connect → App Privacy questionnaire)

Answer **"Data Not Collected"** for every category. The app has no network access, no
accounts, no analytics, no third-party SDKs. All data (workouts, session history) stays in
local SwiftData storage on-device.

## Description

```
Build your own HIIT workouts and run them with a clean, focused interval timer.

Interval Pulse Timer lets you create custom sequences of named, color-coded intervals — work, rest,
warm-up, whatever you need — repeat them for as many rounds as you want, and run them with
a big countdown ring, sound cues, and haptic feedback so you always know what's next
without looking at your phone.

FEATURES
• Build unlimited custom workouts with named, colored, timed intervals
• Optional warm-up and cool-down segments that run once, not per round
• Repeat any workout for 1–99 rounds, or instantly re-run it from the finish screen
• Drag to reorder workouts and intervals
• Big countdown ring with round progress and "next up" preview
• Audio + haptic cues for interval changes and the final countdown
• Screen stays awake during a workout
• History tab with streaks, weekly totals, and a habit-tracking calendar
• Light, Dark, and System appearance
• 100% offline — no account, no ads, no tracking. All data stays on your device.

Whether it's Tabata, EMOM, or your own custom split, Interval Pulse Timer keeps the workout simple
and the setup out of your way.
```

## Keywords

```
hiit,interval timer,tabata,workout timer,fitness timer,circuit training,gym timer,emom
```

## Promotional Text (optional, editable without review)

```
Build any interval workout you can imagine — run it with a big countdown ring and haptic
cues. 100% offline, no account needed.
```

## What's New (Version 1.2)

```
- Twice the color choices: the interval color picker now offers 12 colors.
```

## What's New (Version 1.1)

```
- Add optional warm-up and cool-down segments to any workout — they run once,
  before round 1 and after your last round, and don't count toward your rounds.
- Repeat a workout right from the finish screen without leaving the timer.
- Performance and battery improvements throughout.
```

## What's New (Version 1.0)

```
Initial release.
```

## App Review Information

| Field | Value |
|---|---|
| Sign-in required | No |
| Demo account | Not applicable — no accounts in the app |
| Contact email | normanhoang@gmail.com |
| Notes for reviewer | App is fully offline and requires no login. Two sample workouts ("Tabata 20/10", "Classic HIIT 40/20") are pre-seeded on first launch so History/Workouts aren't empty. |

## Screenshots

Located in [`docs/screenshots/`](screenshots/). App is portrait-only
(`UISupportedInterfaceOrientations` = Portrait), so only portrait sizes are needed —
landscape isn't applicable to this app's supported orientations.

| File | Size (px) | Satisfies App Store display size |
|---|---|---|
| `screenshots/6.5in-workouts.png` | 1242 × 2688 | 6.5" (iPhone 11 Pro Max class) |
| `screenshots/6.5in-history.png` | 1242 × 2688 | 6.5" (iPhone 11 Pro Max class) |

Both captured on Simulator: Workouts tab (seeded workouts) and History tab with one
completed session, showing streak/stats and the habit-tracking calendar.

## Contact / Support Info (App Store Connect → App Information → General App Information)

| Field | Value |
|---|---|
| Support Email | normanhoang@gmail.com |
| Support URL | `https://normanhoang.github.io/interval_timer/support.html` |
