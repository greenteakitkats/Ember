# Weave

iOS personal CRM: track the people you care about, see who's drifting, get prompted to reach out. Full product spec in [SPEC.md](SPEC.md) — read it before adding features; phasing and P0/P1/P2 priorities live there.

## Stack

- SwiftUI + SwiftData, iOS 18+, no dependencies
- Xcode project uses folder-synced groups (Xcode 16 style): new files added under `Weave/` are picked up automatically, no pbxproj edits needed
- Bundle ID `ryantdo.Weave`, team `VGF2H2R97B` (free dev account)

## Hard constraints

- **No CloudKit/iCloud** until a paid dev account exists, but every SwiftData model must stay CloudKit-compatible: defaults on all stored properties, optional relationships, no `@Attribute(.unique)`.
- **Local-only**: no network calls, no analytics, no accounts. This is a privacy stance, not an oversight.
- iOS cannot read call/message history. Interaction capture is: outreach initiated from Weave (auto-logged), calendar matching (P1, suggestion + confirm only), and manual logging.

## Architecture

Two targets: the app and `WeaveWidgetExtension` (WidgetKit). They share one SwiftData store through the app group `group.ryantdo.Weave` (`SharedStore`); if the group container is unavailable (unsigned simulator builds), it falls back to the local default store so nothing breaks.

- `Shared/` — compiled into BOTH targets: `Person` (health math lives here: `overdueRatio`, `healthState`), `Interaction`, `SharedStore`
- `Weave/Managers/` — `ContactsManager` (CNContactStore sync; people link via `contactIdentifier`, cached fields refresh on launch), `DemoData`
- `Weave/Views/` — `ContentView` (ranked list grouped by health), `PersonDetailView` (recall-first card: ask-about + notes + loves, then outreach buttons), sheets for logging/capturing/adding
- `WeaveWidget/` — home screen widget ("N people miss you" + top drifting people)

## Tone & design

Warm, not sterile: terracotta accent, rounded type (`.fontDesign(.rounded)` at the app root), human copy ("Been too long", "quiet 3mo", "Resting", "N people would love to hear from you"). Never clinical CRM language in UI copy.

Visual system lives in `Weave/Theme.swift`: cream canvas + warm card surfaces (every List/Form hides scroll background and uses `Theme.canvas`/`Theme.card`), a six-hue warm avatar palette hashed stably per person name, and warm health colors in `HealthState.color` (Shared, so the widget matches). The relationship "battery" is `Person.ringFraction` rendered as a depleting ring in `AvatarView` — full after contact, small ember when overdue, deliberately never empty. Serif (`.fontDesign(.serif)`) is reserved for the home greeting and lock screen. `Haptics.logged()` fires on every interaction log. Settings (gear on home) has appearance override and an optional Face ID lock (`appLockEnabled`, LocalAuthentication in `WeaveApp`).

Health thresholds (on track <0.8, drifting 0.8–1.2, overdue >1.2 of cadence) are in `Person.healthState` — the spec says keep them tunable in one place.

## Simulator demo data

`Managers/DemoData.swift` (DEBUG only) seeds a sample network via launch arguments — used for screenshots and manual testing since `simctl` can't tap:

```
xcrun simctl launch <device> ryantdo.Weave -demoData            # wipe + seed sample people
xcrun simctl launch <device> ryantdo.Weave -demoData -openFirstPerson  # jump to most overdue detail
xcrun simctl launch <device> ryantdo.Weave -showManualAdd       # present the add-person sheet
```

Combined with `-openFirstPerson`: `-simulateOutreach` (log a call + show the post-log banner), `-showCaptureSheet` (quick-note sheet), `-showLogSheet` (manual log sheet).

Current UI screenshots live in `Screenshots/`.

## Product tone

Anti-guilt by design: snoozing never penalizes, no streak shaming, warm copy. If a feature makes the user feel bad about their relationships, it's wrong for this app.
