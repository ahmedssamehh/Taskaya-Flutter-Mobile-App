# Taskaya

A minimal, monochrome to-do list app built with Flutter — backed by Firebase Authentication and Cloud Firestore, with search, filtering, categories, scheduled reminders, and a built-in Focus Mode.

<p align="center">
  <img src="Project%20Docs/screenshots/welcome.png" width="200" alt="Welcome screen" />
  <img src="Project%20Docs/screenshots/home_tasks.png" width="200" alt="Home screen" />
  <img src="Project%20Docs/screenshots/darkmode.png" width="200" alt="Dark mode" />
  <img src="Project%20Docs/screenshots/focus_timer.png" width="200" alt="Focus Mode countdown" />
</p>

---

## Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Firebase Setup](#firebase-setup)
- [Project Structure](#project-structure)
- [Testing](#testing)
- [Team](#team)

---

## Features

### Core
- **Firebase Authentication** — email/password and **Google Sign-In**, with session restore on cold start
- **Cloud Firestore** — every task lives at `users/{uid}/tasks/{taskId}`, streamed live so changes reflect instantly across sessions
- **Per-user isolation** — enforced server-side by deployed Firestore security rules, not just client logic
- **Search** — matches title and description, case-insensitive, across pending and completed tasks
- **Filtering** — All / Pending / Completed, plus a category filter row with live counts, all composable together
- **Task priority** — High / Medium / Low, driving sort order
- **Due date & time** — with relative labels ("Tomorrow, 00:36") and overdue/due-soon highlighting
- **Task categories** — Personal, Study, Work, Other — each with its own icon and filter chip
- **Input validation** — stricter email pattern, signup passwords (8+ chars, letter + number), title/description length limits, empty-field guards
- **Error handling** — every Firebase Auth and Firestore error code is mapped to a short, actionable message; no raw exceptions ever reach the UI

### Reminders & Notifications
- **Real OS notifications**, not just in-app messages — scheduled with the device's true timezone so they fire even when the app is closed
- **User-selectable reminder lead time** per task: No reminder / At due time / 10 min / 30 min / 1 hour / 3 hours / 1 day before
- **Per-account isolation** — signing out cancels every scheduled reminder; a new sign-in re-arms only that user's own tasks
- A complementary **in-app notification bell** always works, regardless of OS permission state

### Focus Mode
A dedicated workspace for actually doing the work:
1. Pick a duration (15 / 25 / 45 / 60 minutes) and a pending task
2. A full-screen countdown with an animated progress ring and a breathing pulse
3. When time's up, a real notification fires and the app asks whether you finished
4. **Yes** → task marked complete + a hand-built confetti celebration (no external animation library)
5. **No** → add +5 / +10 / +15 minutes, or exit

### Bonus
- **Dark mode** — full theme, toggled from the header, respected everywhere including Focus Mode
- **Animations** — screen transitions, staggered list entry, an expanding-ring burst on task completion, overdue/due-soon card emphasis
- **Toast feedback** — every action confirms itself ("Task created", "Task deleted" + Undo, etc.)

---

## Screenshots

| | | |
|---|---|---|
| ![Welcome](Project%20Docs/screenshots/welcome.png) | ![Login](Project%20Docs/screenshots/login.png) | ![Signup](Project%20Docs/screenshots/signup.png) |
| Onboarding | Login (email/password + Google) | Signup (with password rules) |
| ![Home](Project%20Docs/screenshots/home_tasks.png) | ![Dark mode](Project%20Docs/screenshots/darkmode.png) | ![Category filter](Project%20Docs/screenshots/category_filter.png) |
| Home — search, filters, overdue flag | Dark mode | Category filter applied |
| ![Add task](Project%20Docs/screenshots/add_edit.png) | ![Reminder picker](Project%20Docs/screenshots/reminder_picker.png) | ![Focus setup](Project%20Docs/screenshots/focus_setup.png) |
| Add/Edit task | Reminder lead-time picker | Focus Mode setup |
| ![Focus timer](Project%20Docs/screenshots/focus_timer.png) | ![Celebration](Project%20Docs/screenshots/celebration.png) | ![Focus completed](Project%20Docs/screenshots/focus_completed.png) |
| Focus countdown | Completion celebration | Task synced to Firestore |

---

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter (Dart SDK ^3.12.0) |
| State management | [`provider`](https://pub.dev/packages/provider) |
| Auth | [`firebase_auth`](https://pub.dev/packages/firebase_auth), [`google_sign_in`](https://pub.dev/packages/google_sign_in) |
| Database | [`cloud_firestore`](https://pub.dev/packages/cloud_firestore) |
| Notifications | [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications), [`timezone`](https://pub.dev/packages/timezone), [`flutter_timezone`](https://pub.dev/packages/flutter_timezone) |
| Local prefs | [`shared_preferences`](https://pub.dev/packages/shared_preferences) |
| Fonts | [`google_fonts`](https://pub.dev/packages/google_fonts) |

---

## Architecture

The app follows a repository/provider pattern: screens depend only on abstract repository interfaces, so the backend can be swapped without touching UI code.

```
Screens  →  Providers (ChangeNotifier)  →  Repository interfaces  →  Firebase implementations
```

- **`AuthRepository`** (interface) → **`FirebaseAuthRepository`** — email/password + Google Sign-In, both behind the same contract
- **`TaskRepository`** (interface) → **`FirestoreTaskRepository`** — live-streamed, scoped to `users/{uid}/tasks`
- **`TaskProvider`** is stream-driven: every mutation (`addTask`, `updateTask`, `deleteTask`, `toggleComplete`) is `Future<String?>` — `null` on success, a friendly message on failure — so screens can await and surface errors without try/catch scattered everywhere
- **`LocalNotificationService`** is a singleton wrapping `flutter_local_notifications`, called by `TaskProvider` after every mutation to keep scheduled reminders in sync with Firestore state

### Data model

```
users/{uid}/tasks/{taskId}
  title: string
  description: string
  isCompleted: bool
  priority: "high" | "medium" | "low"
  category: "personal" | "study" | "work" | "other"
  dueDate: Timestamp | null
  reminderOffset: "none" | "atDueTime" | "minutes10" | "minutes30" | "hour1" | "hours3" | "day1"
  createdAt: Timestamp
  completedAt: Timestamp | null
```

### Security

```js
// firestore.rules
match /users/{userId}/tasks/{taskId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
match /{document=**} {
  allow read, write: if false;
}
```

Enforced server-side and deployed to the live project — a modified client can't bypass it.

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (channel stable)
- A Firebase project with **Authentication** (Email/Password + Google providers) and **Cloud Firestore** enabled
- Android Studio / Xcode for platform builds

### Run locally

```bash
flutter pub get
flutter run
```

### Build a release APK

```bash
flutter build apk --release
```

The output lands at `build/app/outputs/flutter-apk/app-release.apk`.

### Verify everything compiles cleanly

```bash
flutter analyze
```

---

## Firebase Setup

This repo already ships `lib/firebase_options.dart` and `android/app/google-services.json` for the project it was developed against. To point it at your own Firebase project instead:

1. Install the FlutterFire CLI: `dart pub global activate flutterfire_cli`
2. Run `flutterfire configure` and select your project
3. In the Firebase console, enable **Authentication → Sign-in method → Email/Password** and **Google**
4. For Google Sign-In on Android, register your debug/release keystore's SHA-1 and SHA-256 fingerprints against the Android app in Project Settings
5. Deploy the included security rules:
   ```bash
   firebase deploy --only firestore
   ```

---

## Project Structure

```
lib/
├── main.dart                    # DI wiring, Firebase init, provider tree
├── app.dart                     # MaterialApp, theming, global navigator key
├── core/
│   ├── motion/                  # Shared animation durations/curves
│   ├── routing/                 # Route names, custom page transitions
│   ├── theme/                   # Colors, spacing, text styles
│   └── utils/                   # Validators, date formatting
├── data/
│   ├── models/                  # Task, TaskCategory, TaskPriority, ReminderOffset, AppUser
│   └── repositories/            # Abstract interfaces + Firebase implementations
├── providers/                   # AuthProvider, TaskProvider, ThemeProvider, NotificationProvider
├── screens/
│   ├── splash/  welcome/  login/  signup/
│   ├── home/                    # Task list, search, filters
│   ├── add_edit/                # Create/edit task form
│   └── focus/                   # Focus Mode setup + countdown
├── services/
│   └── local_notification_service.dart
└── widgets/                     # Reusable UI: buttons, cards, toasts, celebration overlay
```

---

## Testing

- `flutter analyze` — static analysis, zero issues
- `flutter test` — widget tests under `test/`
- Manually verified end-to-end on an Android emulator against the live Firebase project: auth (email/password + Google), Firestore CRUD, search/filter/category composition, scheduled OS notifications (confirmed via the system notification shade), and the full Focus Mode → celebration flow

See [`Project Docs/Phase2_Report.pdf`](Project%20Docs/Phase2_Report.pdf) for the full requirements-coverage breakdown and [`Project Docs/Phase2_Progress.md`](Project%20Docs/Phase2_Progress.md) for the detailed build log.

---

## Team

| Role | Name |
|---|---|
| Team Leader | Ahmed Sameh |
| Member | Mostafa |

Built for the Mobile Application Development course.

---

## License

[MIT](LICENSE) © 2026 Ahmed Sameh
