# Changelog

All notable changes to Pregnancy Companion are documented here.

## [Unreleased]

### Phase 11 — doctor portal, shopping & premium
- **Doctor portal** — accounts with the Doctor role see their linked patients
  (pregnancies joined via invite code) with a read-only summary: gestational week,
  due date, risk, and the latest blood-pressure, blood-sugar, and weight readings
  pulled from the mother's own trackers. The portal tile only appears for doctors.
- **Shopping list** — a curated, India-first baby-&-mom essentials checklist grouped
  by category (mom, baby clothing, nursery & gear, feeding, health & care) with a
  progress bar, custom items, and swipe-to-delete, stored per pregnancy.
- **Premium** — a paywall/management screen listing the Premium benefits and plans.
  In this build "Go Premium" toggles the entitlement locally; **real in-app billing
  (Play Billing / Razorpay) with server-side verification is still to come** — the
  client must not be the source of truth for entitlements at launch.

### Phase 10 — AI assistant, community, baby names & birth plan

Engagement & guidance features, plus the first server-side backend.

### Added
- **AI assistant ("Ask Mira")** — a conversational pregnancy companion powered by
  Claude, reached through a new `aiAssistant` Cloud Function proxy so the API key
  stays server-side. The system prompt is safety-first (educational only, escalates
  red-flag symptoms, never diagnoses/prescribes) and is tailored with the mother's
  gestational week and trimester. Chat is held in memory for the session.
- **Community feed** — a shared `community_posts` collection where moms post updates,
  like, and comment. Includes a feed, compose sheet, and post-detail with comments.
- **Baby names** — a curated, India-first catalog searchable by name/meaning and
  filterable by gender, with favourites synced to the pregnancy
  (`pregnancies/{pid}/favoriteNames`).
- **Birth plan** — a structured preferences form (delivery, pain management, after-birth,
  environment, special requests) stored per pregnancy, exportable as a shareable text
  summary via the shared `ReportView` (copy/email).

### Backend
- New `functions/` Node 20 codebase with the `aiAssistant` callable function
  (`@anthropic-ai/sdk`, `ANTHROPIC_API_KEY` as a Secret Manager secret). Requires the
  Firebase Blaze plan and `firebase deploy --only functions`.

## [1.0.0-beta] — 2026-08-04

First feature-complete MVP, hardened for offline use and testing.

### Added
- **Baby kick counter** — count-to-10 movement sessions with a live stopwatch,
  progress, history, and auto-complete on reaching the target.
- **Contraction timer** — one-tap start/stop timing with a live 5-1-1 rule
  analysis (interval, duration, sustained-hour) and per-contraction history.
- **Movement & contraction report** — a shareable plain-text summary (copy or
  email) of kicks and contractions; works fully offline, no PDF tooling needed.
- **Offline banner** — an app-wide indicator that reassures users their changes
  save locally and sync on reconnect.

### Hardened
- Expanded automated tests: error layer (`Result`, `ErrorMapper`), connectivity
  service, local storage, the offline banner, empty state, and a kick-counter
  flow test — alongside the existing tracker/calculator/serialization suites.
- Confirmed Firestore offline persistence covers write queueing for all
  trackers; the reserved `syncQueue` Hive box remains for future non-Firestore
  queued work.

### Known gaps (pre-launch)
- `flutterfire configure` not yet run (app boots without Firebase via guarded
  init; auth/data need it configured).
- No Cloud Functions yet (AI proxy, role custom-claims) — Phase 10.
- App icons / splash / native flavors not set up.

## Earlier

Phases 1–5 delivered the architecture, foundation, authentication + onboarding,
the tabbed shell with the 40-week tracker and emergency screen, and the core
trackers (medicine, appointments, symptoms, water, weight).
