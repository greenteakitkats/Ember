# Weave — Product Spec (v1)

**Platform:** iOS 17+, SwiftUI + SwiftData
**Author:** Ryan
**Status:** Draft for v1 build
**Last updated:** July 1, 2026

---

## Problem Statement

Living far from the people you care about removes the casual everyday moments that keep relationships warm. Without bumping into friends at work, the gym, or around the neighborhood, staying in touch requires deliberate effort, and good intentions reliably lose to busy weeks. The cost is real: relationships you value quietly decay, and by the time you notice, reaching out feels awkward.

Weave is a personal CRM that makes deliberate outreach nearly effortless: it tracks who you know, when you last connected, and who is drifting, then prompts you at the rhythm you choose.

## Goals

1. **Never unknowingly lose touch.** Every tracked relationship has a visible health state at all times; nobody goes "red" without the app having surfaced them first.
2. **Make logging nearly free.** Logging an interaction takes one tap in the common case (outreach started from Weave, or a calendar match confirmed).
3. **Prompt without nagging.** Reminders arrive on the user's schedule, respect snoozes, and never guilt-trip. The app should feel like a thoughtful assistant, not a chore tracker.
4. **Be trustworthy with intimate data.** All relationship data lives on device. No accounts, no servers, no analytics.
5. **Ship a usable v1 within ~4 weeks of part-time work,** then iterate through daily personal use across a 100+ person network.

## Non-Goals (v1)

- **No automatic reading of calls/messages.** iOS does not allow it; designing around a capability that doesn't exist wastes effort. Smart logging comes from Weave-initiated outreach and calendar matching instead.
- **No iCloud/CloudKit sync.** Requires a paid developer account (same constraint hit on Evenly). Data model should be CloudKit-compatible so sync can be enabled later without migration pain.
- **No social features.** No sharing, no "networks," no comparing. This is a single-player tool by design.
- **No Android/web version.** iOS-only keeps focus. The concept doc's "web app" framing is portfolio narrative, not a build target.
- **No AI-drafted messages.** v1 nudges you to reach out; what you say is yours. Revisit only if daily use shows real friction at the "what do I even say" step.

## Target User

Ryan (and people like him): someone with a large, geographically scattered network of friends and family they genuinely care about, who has good intentions but no system. Not a sales tool, not a networking tool.

## User Stories

Ordered by priority.

**Core loop**
- As someone with a scattered network, I want to import the people I care about from my iPhone contacts so that setup takes minutes, not hours.
- As a busy person, I want to see a ranked list of who I haven't talked to in too long so that I know exactly who to reach out to today.
- As someone reaching out, I want to call/text/email a person directly from their card in Weave so that the interaction is logged automatically the moment I start it.
- As a forgetful logger, I want interactions inferred from my calendar (events with matched attendees) so that dinners and calls count without manual entry.
- As someone who saw a friend spontaneously, I want to log a past interaction with a backdate in two taps so that my history stays accurate.

**Health & cadence**
- As a user, I want to set a per-person cadence (weekly / monthly / quarterly / yearly) so that my college roommate and my aunt aren't held to the same rhythm.
- As a user, I want each contact's health shown as a simple visual state (on track / drifting / overdue) so that I can scan my whole network in seconds.

**Reminders & milestones**
- As a user, I want one daily digest notification ("3 people are due, plus Dan's birthday Thursday") so that I'm prompted once, not spammed per person.
- As a user, I want birthday reminders with configurable lead time so that I can send something rather than scramble day-of.
- As a user, I want to add custom milestones (anniversary, "starts new job in March," "baby due in August") so that I reach out at moments that matter, not just birthdays.
- As a user, I want to snooze or dismiss a reminder from the notification itself so that a busy day doesn't turn the app into a guilt machine.

**Context & memory**
- As someone with 100+ tracked people, I want a notes field and quick "talking points" per contact (kids' names, what we discussed last, things to ask about) so that reconnecting after months doesn't feel cold.
- As someone with friends across time zones, I want each contact's current local time visible so that I don't call someone at 3am.

**Organization & lifecycle**
- As a user, I want to group contacts into circles (family, college friends, work, abroad) so that I can filter and set cadence defaults by group.
- As a user, I want to pause a contact (traveling together, staying with them, or the relationship changed) without deleting history so that health math stays honest.

**Edge cases**
- As a new user with zero data, I want an onboarding flow that imports contacts and bulk-assigns cadences quickly (triage-style) so that the app is useful on day one.
- As a user whose contact has no birthday in iOS Contacts, I want to add one in Weave without editing the system contact.
- As a privacy-conscious user, I want to export all my data (JSON/CSV) so that I'm never locked in.

## Requirements

### Must-Have (P0)

**P0-1. Contact import & sync**
Import via contact picker (curated selection, not full address book). Each Weave contact links to its `CNContact` identifier; name, photo, phones, emails, and birthday stay synced from the system.
- [ ] User can multi-select contacts from the system picker during onboarding and anytime after
- [ ] Weave reflects changes to a linked system contact (name/photo/number) on next launch
- [ ] A contact deleted from iOS Contacts degrades gracefully (Weave keeps its copy, flags the broken link)
- [ ] User can create a Weave-only contact manually (person not in address book)

**P0-2. Interaction log**
Per-contact chronological history of interactions with type (call, message, email, in person, other), timestamp, and optional note.
- [ ] Manual log in ≤2 taps from contact card or ranked list (long-press quick action)
- [ ] Manual log supports backdating
- [ ] Interactions can be edited and deleted
- [ ] Log entry shows how it was captured (manual, via Weave outreach, calendar)

**P0-3. Weave-initiated outreach = automatic log**
Call / Message / Email buttons on the contact card deep-link to the system app and log the interaction.
- [ ] Given a contact with a phone number, when user taps Call or Message, then the system app opens and an interaction is logged with the correct type
- [ ] A just-logged outreach shows an undo affordance (tapped by accident ≠ interaction)

**P0-4. Cadence & health**
Per-contact cadence: weekly, biweekly, monthly, quarterly, twice a year, yearly. Health = days since last interaction ÷ cadence length.
- [ ] Health states: **on track** (<80% of cadence), **drifting** (80–120%), **overdue** (>120%); thresholds tunable in one place in code
- [ ] Home screen shows the network ranked by overdue ratio, worst first
- [ ] New contacts with no interactions yet are "unranked" until first log or a user-set "last talked around..." estimate during onboarding
- [ ] Paused contacts are excluded from health math and reminders

**P0-5. Daily digest notification**
One local notification per day at a user-chosen time summarizing who is due and upcoming milestones.
- [ ] Fires only when there's something to say (no empty digests)
- [ ] Notification actions: open app; snooze person(s) for N days
- [ ] Snoozing suppresses that contact from digests for the chosen period without changing their health state

**P0-6. Birthdays & milestones**
Birthdays imported from Contacts; custom milestones (one-off or recurring) per contact with configurable lead-time reminders.
- [ ] Birthday appears in digest at lead time (default 3 days) and day-of
- [ ] User can add a birthday in Weave without modifying the system contact
- [ ] Custom milestone with title, date, recurrence (none/yearly), lead time

**P0-7. Onboarding triage**
After import, a fast flow to assign cadence and rough "last talked" to each person (bulk-assign by selection or swipe-through).
- [ ] A 100-contact import can be fully triaged in under ~10 minutes
- [ ] Skippable; untriaged contacts default to monthly/unranked

**P0-8. Local-first privacy**
- [ ] All data in SwiftData on device; zero network calls in v1
- [ ] Contacts and Notifications permission prompts appear in context with a plain-language explanation, not at cold launch

### Nice-to-Have (P1)

**P1-1. Calendar matching (EventKit).** Scan recent/upcoming events, match attendees to Weave contacts by email/name, suggest interactions ("Dinner with Sarah on Tuesday — log it?"). Suggestions require one-tap confirmation, never auto-log. *This is the biggest magic-feel feature; it's P1 only because the core loop works without it. Build it first among P1s.*

**P1-2. Local time per contact.** City/time zone field; contact card and list rows show their current local time and a "probably asleep" hint. Directly serves the overseas origin story.

**P1-3. Circles (tags).** Assign contacts to groups; filter ranked list by circle; new-contact cadence defaults per circle.

**P1-4. Talking points.** Lightweight structured prompts on the contact card ("last time you talked about…", "ask about…"), shown when composing outreach and in the digest.

**P1-5. Home screen widget.** Small/medium widget: top 3 overdue people with tap-through to their card.

**P1-6. Data export.** JSON export of contacts, interactions, milestones from Settings.

**P1-7. Monthly recap.** A simple stats view: interactions logged, relationships moved from red to green, longest streaks. Warm tone, no shame mechanics.

### Future Considerations (P2)

- **iCloud sync** (blocked on paid dev account; keep SwiftData models CloudKit-compatible: no unique constraints CloudKit can't handle, optional relationships, UUID ids)
- **Smart cadence suggestions** based on observed interaction rhythm
- **Share extension** ("log interaction with…" from anywhere)
- **Siri/Shortcuts intents** ("Hey Siri, log that I called Mom")
- **Journaling Suggestions API** as a data source (requires Apple entitlement; likely limited to journal-category apps — investigate, don't assume)
- **On-device notification suggestions** for what to open with (uses only local data)

## Success Metrics

Personal-use product, so metrics are honest self-measures plus portfolio outcomes.

**Leading (first 30 days of daily use)**
- ≥5 interactions logged per week, with ≥50% captured automatically (Weave-initiated or calendar-confirmed) rather than manual
- Daily digest opened ≥4 days/week
- Onboarding triage of full network completed within first week

**Lagging (60–90 days)**
- ≥70% of tracked network in "on track" or "drifting" (vs. red) at the 60-day mark
- At least 5 reconnections with people who had gone >2× their cadence
- Zero months where the app itself is abandoned (the meta-metric: a relationship tool you stop opening has failed)
- Portfolio: shipped build on personal device + written case study with real usage data to replace the aspirational copy

## Open Questions

- **(design, blocking-ish)** Does health need a numeric score anywhere, or are the three states + ranking enough? Lean: states only; numbers invite anxiety.
- **(engineering, non-blocking)** Free dev account provisioning expires after 7 days per install. Fine for development; decide later whether v1 "ship" means paid account + TestFlight, or personal sideload cadence is acceptable.
- **(design, non-blocking)** Where does a logged-but-unanswered outreach land? v1 position: an attempt counts as an interaction (the habit being built is *reaching out*). Revisit if it feels dishonest in practice.
- **(engineering, non-blocking)** Calendar matching accuracy: match on attendee email first, fuzzy name second? Needs a spike with real calendar data.

## Phasing

**Phase 1 (weeks 1–2): Core loop.** P0-1 through P0-4, P0-8. Usable with manual + outreach logging, ranked health list. Start daily personal use immediately; the rest of the spec gets validated or corrected by this.

**Phase 2 (weeks 3–4): Rhythm.** P0-5, P0-6, P0-7. Digest, milestones, onboarding polish. This is the "v1 done" line.

**Phase 3 (fast follows, prioritized by felt friction):** P1-1 calendar matching first, then local time, circles, widget, talking points, export, recap.

---

## QOL Additions Beyond the Original Concept

For traceability, everything above that wasn't in the initial idea:

1. **Daily digest instead of per-contact notifications** — one prompt per day; per-person pings across 100+ people would train you to disable notifications entirely
2. **Snooze from the notification** with no health penalty — anti-guilt design
3. **Local time per contact** — born directly from the overseas origin story
4. **Talking points / notes** — solves the *second* half of losing touch: not knowing what to say after months
5. **Custom milestones beyond birthdays** — anniversaries, job starts, due dates
6. **Circles with cadence defaults** — makes 100+ contacts manageable
7. **Pause/archive without data loss** — relationships change; the math should stay honest
8. **Onboarding triage flow** — the difference between an app that's useful day one and one abandoned during setup
9. **Undo on auto-logged outreach** — accidental tap shouldn't fake an interaction
10. **Backdating** — real life happens away from the phone
11. **Home screen widget** — health visibility without opening the app
12. **Data export + local-only privacy stance** — it's intimate data; treat it that way
13. **Monthly recap with warm tone** — positive reinforcement, deliberately no streaks-shaming
14. **CloudKit-compatible data model now** — so the free-account iCloud constraint (hit on Evenly) doesn't force a migration later
