# Pregnancy Companion App - UI/UX & Feature Documentation

This document provides a comprehensive overview of all screens, UI/UX flows, button locations, and feature details within the Pregnancy Companion App.

## 🎨 Global UI/UX Principles & Aesthetics

- **Theme & Colors:** 
  - **Primary:** Soft Baby Pink (`#F48FB1`) and Pure White (`#FFFFFF`). 
  - **Accents:** Warm Peach, Soft Lavender, and Pastel Yellow for highlights.
  - The goal is a "Polished Whimsy" aesthetic—a light, airy, and undeniably cute style that still feels highly functional and trustworthy (professional).
- **Animations & Doodles:**
  - **Cute Doodles:** Hand-drawn style pastel icons and empty-state illustrations (e.g., a sleeping baby, a stork, a little rattle).
  - **Micro-animations (Lottie):** Bouncing hearts, a softly breathing baby illustration on the home screen, and smooth page transitions.
- **Gestures:** 
  - "Double tap to send love" on weekly updates (triggers a flurry of pink hearts).
- **Categorization:** Strict card-based and tab-based layouts to prevent clutter. Nothing should feel overwhelming.
- **Baby Loading Bar:** A persistent, cute progress bar at the top of the dashboard tracking the pregnancy weeks.

---

## 1. Authentication & Onboarding
**Path:** `lib/features/auth/` & `lib/features/onboarding/`

### Splash Screen
- **Description:** Initial loading screen showing the app logo.
- **Actions:** Auto-navigates to Onboarding or Dashboard based on auth state.

### Onboarding Carousel
- **Description:** A swipeable carousel introducing key features (AI Assistant, Trackers, Community).
- **Buttons:**
  - `Skip` (Top Right)
  - `Next` (Bottom Right)
  - `Get Started` (On the last slide, Bottom Center)

### Login / Register
- **Description:** Sign-in options for users.
- **Input Fields:** Email, Password.
- **Buttons:**
  - `Login with Email` (Center)
  - `Sign in with Google` (Bottom)
  - `Sign in with Apple` (Bottom)
  - `Continue with Phone` (Bottom)
  - `Forgot Password?` (Below Email Login)
  - `Continue as Guest` (Bottom text link)

### Profile Setup (Mother / Partner)
- **Description:** Collects basic user details and pregnancy timeline.
- **Input Fields:** Name, Role (Mother/Partner/Doctor), Last Menstrual Period (LMP) or Due Date.
- **Buttons:**
  - `Calculate Due Date` (Below date picker)
  - `Complete Setup` (Bottom full-width button)

---

## 2. Main App Shell (Navigation)
**Path:** `lib/features/app_shell/`
The app uses a persistent bottom navigation bar.

### Bottom Navigation Tabs
1. **Home** (Dashboard)
2. **Tracker** (Weekly Pregnancy Tracker)
3. **Tools** (Hub for all utilities)
4. **Profile** (User settings and health profile)

---

## 3. Core Tabs & Screens

### 3.1 Home (Dashboard)
**Path:** `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- **Description:** A personalized daily overview.
- **UI Elements:**
  - **Greeting Header:** "Good morning, [Name]" + Current Trimester / Week info.
  - **Daily AI Tip Card:** Dynamic tip generated based on the current pregnancy week.
  - **Quick Actions (Grid/Row):** Circular icon buttons for `Log Water`, `Add Symptom`, `Take Medicine`, `AI Chat`.
  - **Upcoming Appointments Card:** Next doctor visit details.
- **Buttons:**
  - `SOS / Emergency` (Top Right App Bar - Red Icon)
  - `View All` (Next to Upcoming Appointments)

### 3.2 Tracker (Week-by-Week)
**Path:** `lib/features/week_tracker/presentation/screens/week_tracker_screen.dart`
- **Description:** Details baby's development for the current week.
- **UI Elements:**
  - **3D/Image Baby Visualization:** Center visual of baby size (e.g., "Size of an avocado").
  - **Swipeable Tabs/Carousel:** To view past or future weeks.
  - **Information Cards:** "Baby's Development", "Mother's Body Changes", "To-Dos this Week".
- **Buttons:**
  - `Share Progress` (Top Right)
  - `Read More` (On information cards)

### 3.3 Tools Hub
**Path:** `lib/features/tools/presentation/tools_screen.dart`
- **Description:** Grid or list menu of all app utilities categorized logically.
- **Categories & Icons:**
  - **Vitals & Health:** Blood Pressure, Weight, Blood Sugar, Medicine.
  - **Daily Logs:** Symptoms, Water, Sleep, Mood.
  - **Pregnancy Specific:** Kick Counter, Contraction Timer, Birth Plan.
  - **Preparation:** Hospital Bag, Baby Names, Shopping List.
- **Interaction:** Tapping any tool icon routes to its specific screen.

### 3.4 Profile & Settings
**Path:** `lib/features/profile/presentation/screens/profile_tab_screen.dart`
- **Description:** User management and app settings.
- **UI Elements:**
  - User Avatar & Name.
  - **List Tiles:**
    - Edit Health Profile
    - Partner Sharing (Invite/Manage Partner)
    - Connected Doctor
    - Premium Subscription
    - App Settings (Theme, Notifications)
- **Buttons:**
  - `Log Out` (Bottom text button, red color)

---

## 4. Specific Tool Screens & Details

### Health Trackers
- **Medicine:** List of daily meds. `+ Add Medicine` FAB (Floating Action Button). Checkboxes to mark taken.
- **Symptoms:** Calendar view. `+ Log Symptom` FAB. Sliders for severity.
- **Water:** Circular progress ring. Quick add buttons: `+ 100ml`, `+ 250ml` (Bottom).
- **Weight:** Line chart showing trend (fl_chart). `+ Add Weight` FAB. Shows BMI and recommended gain zone.
- **Blood Pressure & Sugar:** Form inputs for readings. Historical list view. `Save` button at the bottom of the form.

### Safety Trackers (Phase 6)
- **Kick Counter:** 
  - **UI:** Large central circular button to register a kick.
  - **Buttons:** `Start Session`, `Tap to Record Kick`, `End Session`.
  - **Details:** Auto-calculates time taken for 10 kicks.
- **Contraction Timer:** 
  - **UI:** Prominent timer interface.
  - **Buttons:** `Start Contraction` (Turns to `Stop Contraction`), `Reset`.
  - **Details:** Logs duration and frequency. Alerts user if patterns match labor.

### AI Features
- **AI Assistant Chat:** Standard chat UI. Input field at bottom, send button. Suggested prompt chips above input.
- **Document Scan (Labs/Prescriptions):** Camera overlay UI. `Capture` button (bottom center). `Analyze` button after photo is taken.
- **AI Tools (Meal/Wellness Plan):** Form to select dietary preferences/restrictions, followed by a generated Markdown text view. `Generate Plan` button.

### Preparation & Planning
- **Hospital Bag:** Checklist UI categorized by (For Mother, For Baby, For Partner). `+ Add Custom Item` button.
- **Birth Plan:** Form-based wizard (Pain management, Environment, Cord cutting). `Export to PDF` button (Top Right).
- **Baby Names:** Tinder-style swipe interface (Swipe Right for Yes, Left for No). List view of saved names.

---

## 5. Global UI/UX Principles
- **Color Palette:** Soft, calming tones defined in `app_colors.dart`.
- **Typography:** Legible, modern sans-serif (Material 3 Typography) defined in `app_typography.dart`.
- **Accessibility:** High contrast text, scalable fonts, and clear semantic labels on all icons.
- **Offline States:** Skeleton loaders for data fetching. Clear "You are offline" banners at the top of screens when disconnected, while still allowing local data entry.
- **Navigation:** Deep linking enabled via GoRouter. Back buttons always present in the top-left of the App Bar on sub-screens.
- **Feedback:** SnackBar notifications appear at the bottom for successful saves, errors, or alerts.
