# Weave

A personal CRM for iOS. Track the people you care about, see who's drifting, and get prompted to reach out before relationships quietly fade.

Weave started from living overseas: without the casual everyday moments that keep relationships warm, it was easy to lose touch with people I genuinely cared about, even with good intentions.

## What it does

- Imports the people you choose from iOS Contacts and keeps names, photos, and birthdays in sync
- Logs interactions automatically when you call, message, or email someone from inside the app
- Ranks your network by relationship health: time since last contact relative to the cadence you set per person (weekly for your best friend, quarterly for your aunt)
- Manual logging with backdating for everything that happens away from the phone

## Status

Phase 1 (core loop) is built: import, interaction history, cadence-based health, ranked list. Phase 2 adds a daily digest notification, birthday and milestone reminders, and onboarding triage. See [SPEC.md](SPEC.md) for the full product spec.

## Stack

SwiftUI + SwiftData, iOS 18+, no dependencies. All data stays on device: no accounts, no servers, no analytics.
