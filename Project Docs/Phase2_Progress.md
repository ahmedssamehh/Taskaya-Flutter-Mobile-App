# Taskaya — Phase 2 Progress

Tracks completion of `Phase2_Remaining_Task_Split_Ahmed_Mostafa.md`, plus the
enhancements added after that split was written.

Legend: `[x]` done · `[~]` done, needs your manual sign-off · `[ ]` not done

---

## 3. Ahmed — Task Data & Discovery

### A. Replace the local task repository with Cloud Firestore
- [x] Created `FirestoreTaskRepository` ([lib/data/repositories/firestore_task_repository.dart](../lib/data/repositories/firestore_task_repository.dart)) behind a new abstract `TaskRepository` interface ([lib/data/repositories/task_repository.dart](../lib/data/repositories/task_repository.dart)).
- [x] Tasks stored at `users/{uid}/tasks/{taskId}`.
- [x] `watchAll()` returns a live `Stream<List<Task>>` from `collection.snapshots()`.
- [x] Create/edit/delete/restore/toggle-complete all write through `upsert`/`delete` to Firestore ([lib/providers/task_provider.dart](../lib/providers/task_provider.dart)).
- [x] `TaskProvider` exposes `isLoading`, `error`, `isSaving`, `isDeleting`; UI shows a spinner while loading and a dismissible error banner on failure.
- [x] `Task.toFirestoreMap()`/`Task.fromFirestore()` preserve title, description, priority, category, due date, reminder offset, completion state, created date, completed date (dates as Firestore `Timestamp`s).
- [x] Removed the old in-memory seeded `TaskRepository` entirely — no demo seed remains on the production path.

**Verified live:** tasks created on the emulator persist to Firestore and reload after an app restart.

### B. Search tasks
- [x] Search field on Home ([lib/screens/home/home_screen.dart](../lib/screens/home/home_screen.dart), `_SearchAndFilterBar`).
- [x] Matches title OR description, case-insensitive (`TaskProvider._matching`).
- [x] Applies across both pending and completed lists.
- [x] Clear (×) button appears once there's a query; dedicated "No matching tasks" state when a search/filter yields nothing.
- [x] Runs client-side over the already-streamed Firestore list, so it never re-queries and doesn't disturb the `StaggeredFadeIn` list animations.

### C. Filter completed and pending tasks
- [x] All / Pending / Completed chip row under the search field.
- [x] "All" still renders the existing Pending/Completed sections exactly as before.
- [x] `_NoResultsState` when the current filter/search combination matches nothing — distinct from the full-screen "add your first task" state, which only shows at zero tasks.
- [x] Search, status filter and category filter all compose.

### D. Optional bonus: Task Categories
- [x] `TaskCategory` enum ([lib/data/models/task_category.dart](../lib/data/models/task_category.dart)): Personal, Study, Work, Other — each with a label and icon.
- [x] Category chip picker in Add/Edit Task, matching the priority picker's pattern.
- [x] Persisted in Firestore via `Task.category`.
- [x] Shown on every task card as an icon badge.
- [x] **Dedicated category filter row on Home** with live per-category counts (see §6).

---

## 4. Mostafa — Firebase Auth, Reliability & Notifications

### A. Configure Firebase
- [x] `taskaya-1` connected for Android, iOS and web via FlutterFire CLI.
- [x] `firebase_core`, `firebase_auth`, `cloud_firestore` added to `pubspec.yaml`.
- [x] Config files added (`google-services.json`, `firebase_options.dart`) — client identifiers, not secrets; safe to commit.
- [x] `Firebase.initializeApp()` runs before `runApp()` in [lib/main.dart](../lib/main.dart).
- [x] Android Gradle updated with the Google Services plugin; release APK builds successfully.

### B. Replace mock authentication with Firebase Email/Password Auth
- [x] `FirebaseAuthRepository implements AuthRepository` ([lib/data/repositories/firebase_auth_repository.dart](../lib/data/repositories/firebase_auth_repository.dart)).
- [x] Signup calls `createUserWithEmailAndPassword` + `updateDisplayName`.
- [x] Login calls `signInWithEmailAndPassword`.
- [x] Splash restores the session via `authStateChanges().first`, avoiding a race with Firebase's async persistence restore.
- [x] Logout calls `FirebaseAuth.signOut()`.
- [x] Demo-account hint removed from the login screen.
- [x] `main.dart` provides `FirebaseAuthRepository()`; `MockAuthRepository` deleted.
- [x] **Google Sign-In added** as a second provider (see §6).

### C. Proper Firebase and network error handling
- [x] `FirebaseAuthException` codes mapped to friendly copy (invalid email, wrong password, email in use, weak password, network failure, too many requests, disabled account, `internal-error`, fallback).
- [x] `FirestoreTaskRepository` maps Firestore errors (`permission-denied`, `unavailable`/network) to friendly messages surfaced via `TaskProvider.error`.
- [x] Login/signup guard `_submit()` against re-entry; Add/Edit guards save/delete behind `_submitting`, disabling the button and showing a spinner.
- [x] Validation messages sit next to their inputs; loading indicators preserved.

### D. Optional bonus: True Local Notifications / Task Reminders
- [x] `flutter_local_notifications`, `timezone`, `flutter_timezone` added.
- [x] `LocalNotificationService` ([lib/services/local_notification_service.dart](../lib/services/local_notification_service.dart)) requests Android POST_NOTIFICATIONS + exact-alarm permission and iOS alert/badge/sound.
- [x] **Real OS notifications** via `zonedSchedule` with `exactAllowWhileIdle` and the device's true IANA timezone — they fire with the app closed, not just in-app.
- [x] Cancels before rescheduling, so edits never double-book a reminder.
- [x] `TaskProvider` schedules/cancels after every add, update, toggle, delete and restore.
- [x] Tapping a notification opens that task's edit screen via a global `navigatorKey`.
- [x] The in-app bell (`NotificationProvider`) still works as a complementary inbox regardless of OS permission state.
- [x] Manifest permissions added (`POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`).
- [x] **User-selectable reminder lead time** and **per-account isolation** (see §6).

---

## 5. Shared Finalization

### Firestore security and user isolation
- [x] `firestore.rules` restricts `users/{userId}/tasks/*` to `request.auth.uid == userId`; everything else denied by default.
- [x] **Deployed** to the live `taskaya-1` project (confirmed by reading the rules back).
- [x] Unauthenticated users cannot access task documents — enforced by `request.auth != null` in the rule itself.
- [~] Two-account isolation test — **needs you**: sign in with two real accounts and confirm neither sees the other's tasks. The rules guarantee it server-side, but I can't drive two live sessions from here.

### End-to-end QA
- [x] `flutter analyze` — **"No issues found!"** (zero errors, warnings and infos).
- [x] Debug build installs and runs on an Android emulator — validates the full Gradle/plugin/native wiring, not just Dart analysis.
- [x] Release APK builds (`flutter build apk --release`).
- [x] **Live emulator pass** (Pixel 9a, signed-in Firebase account, real Firestore data):
  - Session restored automatically on relaunch.
  - Category filter chips with live counts — selecting "Personal (1)" correctly hid the Study task.
  - Overdue task rendered with red border, alert icon and bold "Overdue · …" label.
  - Focus setup → duration select → task select → button enable.
  - Countdown ticking (14:57) with progress ring and breathing pulse.
  - "I finished early" → confetti celebration with self-drawing checkmark and "You focused for 15m."
  - Task flipped to COMPLETED (1 pending · 1 done) and persisted to Firestore.
  - Add-task: category picker, and the reminder picker correctly disabled ("set a due date first") then enabled with "At due time" preselected once a date was chosen.
  - Dark mode confirmed.
- [~] Physical-device pass — **needs you**. Everything above was verified on an emulator; a real device is worth one final sweep before submission.
- [~] Watching a scheduled reminder actually fire at its due time — implemented and verified as *scheduled*, but confirming delivery needs a device left running to the due moment.

### Submission deliverables
- [x] Release APK built successfully (after fixing a missing core-library-desugaring config — see Notes).
- [x] Phase 2 report ([Phase2_Report.pdf](Phase2_Report.pdf)) — **12 real screenshots, no placeholders**.
- [ ] APK added to the submission package — tell me where you want it.
- [ ] Project zipped and verified to build from a clean checkout — say the word and I'll do it.

---

## 6. Enhancements added after the original split

### Google Sign-In
- [x] Google provider enabled on `taskaya-1`; OAuth client created and the debug keystore's SHA-1 + SHA-256 fingerprints registered (these were missing and are genuinely required).
- [x] `google_sign_in` added; `loginWithGoogle()` exchanges the Google ID token for a Firebase credential.
- [x] "Continue with Google" on both Login and Signup, with an `or` divider and its own in-flight guard.
- [x] Sign-out clears the Google session too, so the account picker reappears next time.

### Smarter reminders — user-selected lead time
- [x] `ReminderOffset` model ([lib/data/models/reminder_offset.dart](../lib/data/models/reminder_offset.dart)): No reminder / At due time / 10 min / 30 min / 1 hour / 3 hours / 1 day before.
- [x] Picker in Add/Edit Task, greyed out with "— set a due date first" until a due date exists, then enabled with "At due time" preselected.
- [x] Persisted in Firestore; the service schedules at `dueDate − offset` and writes a context-aware body ("Due in 30 min" vs. the task description).

### Per-account notification isolation
- [x] `cancelAll()` and `resyncAll()` added to `LocalNotificationService`.
- [x] Sign-out cancels every scheduled reminder before clearing the session.
- [x] The first Firestore snapshot for a signed-in user re-arms reminders from scratch, so one account can never inherit another's reminders on a shared device.

### Category filters on Home
- [x] Horizontally-scrollable chip row: "All categories" + Personal/Study/Work/Other, each with a live task count.
- [x] Tapping a category filters; tapping it again clears. Composes with search and the Pending/Completed filter.

### Focus Mode (new feature)
- [x] `FocusSetupScreen` ([lib/screens/focus/focus_setup_screen.dart](../lib/screens/focus/focus_setup_screen.dart)): choose a duration (15/25/45/60 min) and a pending task.
- [x] `FocusTimerScreen` ([lib/screens/focus/focus_timer_screen.dart](../lib/screens/focus/focus_timer_screen.dart)): full-screen countdown with an animated progress ring, breathing pulse, pause/resume and "I finished early".
- [x] Entry points: a Focus FAB on Home (replacing the old voice placeholder) and "Focus on this task" in the long-press sheet.
- [x] Reads an **unfiltered** pending list, so a narrowed Home view never hides tasks from the picker.
- [x] Session end fires a real OS notification, then asks "Did you finish?" — Yes marks it done; otherwise add +5/+10/+15 min or exit.
- [x] `CelebrationOverlay` ([lib/widgets/celebration_overlay.dart](../lib/widgets/celebration_overlay.dart)): Duolingo-style reward — ballistic confetti, springy badge pop, self-drawing checkmark, staggered copy. Entirely `CustomPainter`-based (no Lottie/Rive asset) and honours reduced-motion.

### Feedback and animation polish
- [x] `AppToast` ([lib/widgets/app_toast.dart](../lib/widgets/app_toast.dart)) — icon-led floating snackbars: "Task \"…\" created", "Task updated", "Task completed", "Task deleted" + Undo, plus error variants.
- [x] The completion checkbox emits an expanding ring burst — only on unchecked → checked, so undoing doesn't celebrate.
- [x] Task cards flag **Overdue** (red border, alert icon, bold label) and **due within the hour** (stronger border, clock icon), transitioned with `AnimatedContainer`.

### Validation hardening
- [x] Signup passwords require 8+ characters with at least one letter and one number, shown as a live hint under the field and validated on interaction.
- [x] Login deliberately keeps a presence-only check (see Notes).
- [x] Also covered: stricter email pattern + length cap, name length bounds, empty confirm-password, task title length, description length (500), whitespace-only passwords.

---

## Notes / decisions made along the way

- **`TaskRepository` became an interface.** It was a concrete in-memory class with no abstraction; it's now an `abstract class` mirroring `AuthRepository`'s existing pattern, so `FirestoreTaskRepository` slots in the same way `FirebaseAuthRepository` does. The in-memory implementation was deleted rather than kept as a debug fallback.
- **`TaskProvider` is stream-driven, not synchronous.** Every mutation (`addTask`, `updateTask`, `deleteTask`, `toggleComplete`, `restoreTask`) returns `Future<String?>` — `null` on success, a friendly message on failure — so screens can await and surface errors.
- **Sign-out uses a placeholder `_SignedOutTaskRepository`** rather than pointing Firestore at an empty uid, so the app never issues a doomed query while logged out.
- **Login keeps a presence-only password check on purpose.** Applying the new 8-char/letter+number rule at login would lock out any account created under the old 6-character minimum; strength is enforced where passwords are *created*.
- **The celebration is hand-built**, not an imported animation asset: seeded-RNG ballistic confetti, a spring badge pop, a progressively-stroked checkmark and staggered copy, all in `CustomPainter` + `AnimationController`. It stays monochrome to match the app and collapses to a static state under reduced-motion.
- **Fixed a real release-build bug:** `flutter_local_notifications` requires Android core library desugaring, which wasn't enabled. Added `isCoreLibraryDesugaringEnabled = true` plus the `desugar_jdk_libs` dependency to [android/app/build.gradle.kts](../android/app/build.gradle.kts) — without it, `flutter build apk --release` fails outright.
- **Email/password signup hit a server-side Firebase issue, not a code bug.** Logcat showed `FirebaseAuth: Creating user with …` firing correctly, then `RecaptchaCallWrapper: … [ CONFIGURATION_NOT_FOUND ]` — newer Firebase Auth SDKs run a reCAPTCHA Enterprise check on sign-up, and that key hadn't finished provisioning for this new project. **Google Sign-In was added as the practical unblock**, and the account used for all verification below is signed in that way. Email/password should start working once provisioning completes — worth retesting on your side.
- **This machine's disk kept filling up** (down to ~300 MB free at one point), which crashed Gradle mid-build more than once. I cleared `~/.gradle/caches`, the project's `build/` folder, `npm-cache` and `go-build` — all regenerable dev caches; none of your own files were touched. Worth watching before the next big build.
