# Pregnancy Companion

A secure, offline-first, AI-assisted pregnancy application for **mothers, partners, family members and doctors**.

- **Frontend:** Flutter (Material 3), Riverpod, GoRouter
- **Backend:** Firebase (Auth, Firestore, Storage, Functions, Messaging, Crashlytics, Analytics)
- **Offline:** Hive (encrypted) + Firestore offline persistence
- **Architecture:** Clean Architecture + MVVM + Repository pattern

---

## 🎨 For designers — where the screens live

Every screen (UI page) lives under `lib/features/<feature>/presentation/`, in a file
ending in `_screen.dart` (a few use `_view.dart`). The naming makes any screen easy to
find — e.g. the kick counter is `lib/features/kick_counter/presentation/kick_counter_screen.dart`.

**Design tokens** (edit these to change the look app-wide):

| What | File |
|------|------|
| Colors / palette | `lib/core/theme/app_colors.dart` |
| Typography / fonts | `lib/core/theme/app_typography.dart` |
| Spacing / sizing | `lib/core/theme/app_spacing.dart` |
| Overall Material 3 theme | `lib/core/theme/app_theme.dart` |

**Reusable components** live in `lib/core/widgets/` (used everywhere) and per-feature
`.../presentation/widgets/` folders.

**Main navigation tabs** (the app shell — `lib/features/app_shell/`):

- **Home** → `dashboard/presentation/screens/dashboard_screen.dart`
- **Tracker** → `week_tracker/presentation/screens/week_tracker_screen.dart`
- **Tools** → `tools/presentation/tools_screen.dart`
- **Profile** → `profile/presentation/screens/profile_tab_screen.dart`

**All screens** (grouped by area):

- **Auth & onboarding:** `auth/…` (login, register, forgot password, phone, onboarding carousel), `onboarding/…/profile_setup_screen.dart`, `splash/…/splash_screen.dart`
- **Core trackers:** `medicine`, `appointments`, `symptoms`, `water`, `weight`, `blood_pressure` (bp), `blood_sugar` (glucose), `mood`, `sleep`, `kick_counter`, `contractions`
- **Content & tools:** `nutrition`, `exercise`, `calendar`, `journal`, `memories`, `hospital_bag`, `shopping`, `birth_plan`, `baby_names`, `vaccination`, `recovery`, `reminders`
- **AI features:** `ai_assistant`, `ai_tools` (meal planner, symptom checker, weekly summary, wellness plan), `document_scan` (prescription/lab analysis)
- **People & roles:** `partner`, `doctor` (portal + patient detail), `admin`, `community`, `blood_donors`
- **Reports & insights:** `reports` (hub, health report), `insights`, `emergency`, `premium`, `settings`

> Tip: to see a screen running, open its `_screen.dart` file, then run `flutter run` and
> navigate to it in the app. Routing is defined in `lib/core/` (GoRouter).

---

## Prerequisites

1. **Flutter SDK** ≥ 3.24 (stable channel) — <https://docs.flutter.dev/get-started/install>
2. **Dart** ≥ 3.5 (bundled with Flutter)
3. A **Firebase project** (Blaze plan required for Cloud Functions)
4. **FlutterFire CLI**: `dart pub global activate flutterfire_cli`

## First-time setup

```bash
# 1. Install dependencies
flutter pub get

# 2. Connect Firebase (generates lib/firebase_options.dart + native config)
flutterfire configure

# 3. Run
flutter run
```

> The app is designed to boot and render the UI **even before Firebase is configured** —
> `bootstrap.dart` initializes Firebase inside a guarded block so you can develop the UI
> layer immediately. Auth/data features require Firebase to be configured.

## Project layout

See the [folder structure](#folder-structure) below. In short:

```
lib/
  core/       # cross-cutting: theme, router, DI, services, widgets, utils
  features/   # one vertical slice per feature (data / domain / presentation)
  shared/     # cross-feature models & global providers
  l10n/       # localization (English + Hindi-ready)
functions/    # Cloud Functions (TypeScript) — added in later phases
```

## Scripts

```bash
flutter analyze          # static analysis
flutter test             # unit + widget tests
flutter test integration_test   # integration tests
flutter build apk --release      # Android release
flutter build ipa --release      # iOS release
```

## Phase status

- ✅ **Phase 1** — Discovery, architecture, schema, roadmap
- ✅ **Phase 2** — Foundation: theming, routing, DI, core services, component library, Firebase config
- ✅ **Phase 3** — Authentication (email, Google, Apple, phone OTP, guest, reset), onboarding wizard, profile & pregnancy creation, role-guarded routing
- ✅ **Phase 4** — Tabbed app shell (Home/Tracker/Tools/Profile), home dashboard, 40-week pregnancy tracker (offline content + Hive cache), emergency/SOS screen, settings
- ✅ **Phase 5** — Core trackers: medicine scheduler (dose alarms, adherence, refill), appointments (reminders), symptoms (severity + history), water (progress ring), weight (BMI + gain + fl_chart), all offline via Firestore persistence
- ⏳ **Phase 6** — Safety features: baby kick counter, contraction timer + reports

### Enabling sign-in methods

In the Firebase console → Authentication → Sign-in method, enable: **Email/Password**,
**Google**, **Apple** (iOS), **Phone**, and **Anonymous** (guest mode). For Google/Apple you
must also add the platform OAuth config (SHA-1 for Android, URL scheme / Services ID for
Apple). Phone auth needs an APNs key (iOS) and Play Integrity / reCAPTCHA (Android).

> **Roles & custom claims:** the app stores each user's `role` on their `users/{uid}`
> document immediately. The Firestore rules that grant *doctor/admin* privileges read a
> `role` **custom claim**, which is set server-side by a Cloud Function (added in the
> backend phase). Until that Function is deployed, mother/partner flows work fully (they
> rely on pregnancy ownership/membership, not the claim); elevated doctor/admin access
> activates once claims are wired.

## Firebase rules

Security rules live in `firestore.rules` / `storage.rules`. Deploy with:

```bash
firebase deploy --only firestore:rules,storage:rules
```
