# Pregnancy Companion — Launch Kit (Phase 12)

Everything needed to publish to the Google Play Store. Copy the listing text
straight into the Play Console.

---

## 1. App identity
- **App name:** Pregnancy Companion
- **Package / applicationId:** `com.pregnancycompanion.pregnancy_companion`
- **Version:** 1.0.0 (versionCode 1) — bump `version:` in `pubspec.yaml` for each release
- **Category:** Health & Fitness (alt: Medical)
- **Content rating:** Everyone (see §5)
- **Default language:** English (also ships Hindi for core screens)

---

## 2. Store listing copy

**Short description (≤80 chars):**
> Track your pregnancy week by week — reminders, AI help, and gentle daily care.

**Full description (≤4000 chars):**
> Pregnancy Companion is your warm, week-by-week guide through pregnancy — built
> India-first, with English and Hindi.
>
> 🍼 Week-by-week tracker
> Follow your baby's growth, size, and your body's changes every week, with
> clear, reassuring information.
>
> ⏰ Medicine & appointment reminders
> Add prescriptions (or scan them with your camera) and get dose reminders.
> Never miss an appointment.
>
> 🤖 Ask Mira — your AI companion
> Ask anything about your pregnancy and get gentle, easy-to-understand answers.
> Get AI meal plans, safe yoga & movement, symptom guidance, and a daily
> pregnancy myth explained — tailored to your stage.
>
> 📊 Health tracking & insights
> Log weight, blood pressure, blood sugar, sleep, symptoms, water, kicks and
> contractions. See your trends in simple charts and export health reports.
>
> 🧾 Scan prescriptions & lab reports
> Snap a photo and let the app read the medicines or explain your lab results in
> plain language. Your original photos stay on your device.
>
> 💛 Everything in one place
> Kick counter, contraction timer, hospital-bag & shopping checklists, baby
> names, birth plan, a mood calendar, a photo memories timeline, and emergency
> SOS with your contacts.
>
> 👨‍👩‍👧 Share with family & your doctor
> Choose exactly what your partner, family, or doctor can see.
>
> Pregnancy Companion provides general information and gentle support. It is not
> a medical device and does not replace professional medical advice. Always
> consult your doctor for medical decisions.

**Keywords / tags (for ASO):** pregnancy tracker, pregnancy app, baby tracker,
week by week pregnancy, contraction timer, kick counter, prenatal, maternity,
due date calculator, garbh, pregnancy care.

---

## 3. Graphic assets to prepare (Play requires these)
- **App icon:** 512×512 PNG (use `assets/icon/icon.png` upscaled, teal heart).
- **Feature graphic:** 1024×500 PNG (teal→blush gradient + heart + "Pregnancy
  Companion" — can be generated the same way as the icon via `worker/gen_*.mjs`).
- **Phone screenshots:** at least 2 (recommend 4–8), 1080×2400. Capture:
  1. Home with the baby-growth ring, 2. Week tracker, 3. Ask Mira chat,
  4. Health insights charts, 5. Medicine reminders, 6. Mood calendar.
  (Take on the emulator/phone; the app's teal redesign looks best in light mode.)
- **Optional:** 7-inch tablet screenshots if targeting tablets.

---

## 4. Privacy & required URLs
- **Privacy policy URL:** https://pregnancy-companion-ad7b7.web.app/privacy.html
- **Terms URL:** https://pregnancy-companion-ad7b7.web.app/terms.html
- These are served from `web/privacy.html` / `web/terms.html`. Deploy with:
  `flutter build web` then `firebase deploy --only hosting`.

---

## 5. Play "Data safety" form answers
Based on how the app actually behaves:
- **Does the app collect or share user data?** Yes (collect); **no data sold**;
  **no third-party advertising**.
- **Data collected & why (all: app functionality; not shared for ads):**
  - Personal info: name, email, phone (account), age.
  - Health & fitness: pregnancy/health entries you log.
  - Photos/videos: **processed on-device only** for Memories; prescription/lab
    **images are sent for AI processing** only when you use the scanner
    (transient, not stored by us) — declare "Photos" collected, processed
    ephemerally.
  - App activity: community posts (user-generated).
  - Device IDs: push notification token.
- **Encryption in transit:** Yes.
- **Can users request deletion?** Yes — in-app "Delete account".
- **Is data processed ephemerally?** AI request content: yes.

> Review each toggle against the app before submitting; this is guidance, not a
> substitute for reading the form.

---

## 6. Content rating questionnaire (IARC)
- No violence, no sexual content, no profanity, no gambling.
- Medical/health information: yes (general wellness).
- User-generated content / social features: **Yes** (community feed) — Play may
  ask about moderation; the app has admin moderation (delete posts) and rule-level
  content validation. Expected rating: Everyone / PEGI 3.

---

## 7. Release build (signed .aab for Play)
Upload keystore already exists at `C:\Users\ASUS\pregnancy-companion-upload.jks`
(config in `android/key.properties`). Build the App Bundle:
```
flutter build appbundle --release
```
→ `build/app/outputs/bundle/release/app-release.aab`.

**SHA-1 fingerprints to register in Firebase** (for Google/Phone sign-in in
release, and again for Play App Signing after upload):
- Debug: `A8:2C:BA:27:5A:BB:CC:38:44:FA:16:6C:0B:94:39:BE:A6:41:6C:A2`
- Upload/release: `14:B7:83:16:BD:5E:8F:43:AD:48:38:97:98:27:B5:A2:61:E2:1F:12`
- **After first upload:** copy Play App Signing's SHA-1 from Play Console →
  Setup → App integrity, and add it in Firebase too (else Google sign-in fails
  on Play-distributed builds).

---

## 8. Pre-launch QA checklist (verify on a real phone)
- [ ] App opens (no crash) — release build.
- [ ] Sign in with Google / email; onboarding creates the pregnancy.
- [ ] Home: baby-growth ring, quick actions, Ask Mira card, myth-of-the-day.
- [ ] Ask Mira replies; AI meal/yoga plans from tracker sections work.
- [ ] Add a medicine (manual) → "Medicine saved"; reminders test (⋮ → Test
      reminder) fires; disable battery optimisation if not.
- [ ] Scan a prescription → medicines extracted → added to tracker.
- [ ] Trackers save & read (weight/BP/sugar/sleep/symptoms/water).
- [ ] Insights charts animate; Mood calendar saves.
- [ ] Tracker sections show illustrations; Hindi toggle switches core UI + AI.
- [ ] Emergency SOS + WhatsApp share.
- [ ] Admin: set your role=admin in console → Admin tile appears → can provision
      a doctor + moderate a post.
- [ ] Privacy & Terms links open the hosted pages.

---

## 9. Post-launch
- Monitor Play Console → Pre-launch report & crashes.
- Add Play App Signing SHA-1 to Firebase (see §7).
- Consider re-enabling R8 with keep rules later for a smaller APK (currently off
  for stability — see `android/app/build.gradle.kts`).
