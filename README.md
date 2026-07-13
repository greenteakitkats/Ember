<div align="center">

# Ember

**Never let a relationship quietly fade.**

A native iOS personal CRM that tracks the people you care about, surfaces who's drifting
before it's too late, and makes reaching out effortless — one tap logs the outreach.

Swift · SwiftUI · SwiftData · WidgetKit · iOS 18+

</div>

---

## Overview

Ember started from living overseas: without the casual everyday moments that keep relationships warm, it was easy to lose touch with people I genuinely cared about, even with the best intentions. **Ember** keeps a ranked list of the people you choose, tracks how long it's been since you last connected relative to the cadence you set per person, and gently surfaces who needs a nudge — weekly for your best friend, quarterly for your aunt. No guilt, no streaks, no clinical CRM language. Everything stays on-device.

## Features

- **📇 Import from Contacts** — pick the people you want to track; names, photos, and birthdays stay in sync.
- **🔥 Relationship health** — a warm "battery" ring per person, full after contact and slowly depleting toward an ember as it overdues relative to their cadence.
- **📞 Auto-logged outreach** — call, message, or email someone from inside Ember and the interaction logs itself; manual logging with backdating covers everything else.
- **🔔 Daily digest** — a local notification each morning previews who's drifting, rebuilt every time the app backgrounds. Quiet days schedule nothing — anti-guilt by design.
- **🧠 Recall-first detail view** — ask-about topics, notes, and things they love surface before outreach buttons, so you never open a conversation cold.
- **📱 Home screen widget** — "N people miss you" and the top drifting people, always one glance away.
- **🔒 Private by design** — no accounts, no servers, no analytics. Local-only storage that stays CloudKit-compatible for when sync is ready.

## Tech Stack

| Area | Technology |
|------|-----------|
| Language | Swift 5 |
| UI | SwiftUI (`.fontDesign(.rounded)`, warm custom theme) |
| Persistence | SwiftData, shared across app + widget via App Group |
| Widget | WidgetKit |
| Contacts | Contacts framework (`CNContactStore`) |
| Notifications | UserNotifications (daily digest) |
| Security | LocalAuthentication (optional Face ID lock) |
| Monetization | StoreKit 2 (tip jar, post-paid-account) |
| Architecture | MVVM |

## Architecture

```
Ember/
├── Shared/         # Compiled into BOTH targets — Person (health math), Interaction, SharedStore
├── Ember/
│   ├── Managers/    # ContactsManager, DigestManager, TipJarManager, DemoData
│   └── Views/       # ContentView (ranked list), PersonDetailView, logging/capture sheets
└── EmberWidget/     # Home screen widget — "N people miss you" + top drifting people
```

`Shared/` is compiled into both the app and widget targets so relationship-health math (`Person.overdueRatio`, `Person.healthState`) stays identical everywhere it's shown. The app and widget read from one SwiftData store through the app group `group.ryantdo.Ember`.

## Building

Requires **Xcode 16+** and **iOS 18+**.

```bash
git clone https://github.com/greenteakitkats/Ember.git
cd Ember
open Ember.xcodeproj
```

Then build and run on a simulator or device. No third-party dependencies.

## Status

Phase 1 (core loop) is built: import, interaction history, cadence-based health, ranked list. Phase 2 adds the daily digest notification, birthday/milestone reminders, and onboarding triage. See [SPEC.md](SPEC.md) for the full product spec.

## Author

Built by **Ryan Do** — [help@ryantdo.com](mailto:help@ryantdo.com)
