# Taskaya — Phase 1 Implementation Plan

Complete design system, screen structure, data model, and build order.
Derived from `Mobile_Application_Development_Project_Form.docx`, `Phase1_Task_Split_and_Theme.pdf`,
and `noirlist_light_dark_screens.html`.

---

## 1. Identity & Scope

| | |
|---|---|
| App name | **Taskaya** |
| Package | `taskaya` |
| Tagline (splash) | *Minimal tasks. Nothing else.* |
| Design language | Full monochrome (black & white), flat, bordered — no drop shadows except the FAB |
| Flutter / Dart | 3.44.0 stable / 3.12.0 |

### Phase 1 screens (5)
Splash → Login → Signup → Home → Add/Edit Task

### In scope for Phase 1
- Splash screen with auto-navigation
- Login + Signup with **mock/local auth** (no Firebase yet — Phase 2 swaps the implementation behind the same interface, zero UI change)
- Home: task list, mark complete/incomplete, delete, navigate to add/edit
- Add/Edit Task: one screen, two modes
- **Bonus pulled forward:** Dark Mode, Animations

### Explicitly out of scope (Phase 2)
Firebase Auth, Cloud Firestore, per-user data isolation, search, filter chips, error handling for network failures.

### Decision: priority + due date
The mockup renders **priority pills** and **due-date meta lines** on Home, but the course form lists those as Phase 2 features. **Recommendation: build them now.** They are pure local model fields, the mockup already depends on them, and doing it now means Phase 2 is only "swap the storage layer" instead of "redesign the card." They cost roughly 30 lines total.

---

## 2. Tech Stack

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2          # state management (task list, auth, theme)
  google_fonts: ^6.2.1      # Poppins
  shared_preferences: ^2.3.2 # theme persistence (Wafaa) + mock session
  intl: ^0.19.0             # due-date formatting
  uuid: ^4.5.1              # task IDs
```

No Firebase in Phase 1. State via `ChangeNotifier` + `Provider` — simple enough to explain in the report, structured enough to survive Phase 2.

---

## 3. Folder Structure

```
lib/
├── main.dart                          # runApp + MultiProvider wiring
├── app.dart                           # MaterialApp, theme selection, routes
│
├── core/
│   ├── theme/
│   │   ├── app_colors.dart            # every hex token, light + dark
│   │   ├── app_theme.dart             # ThemeData lightTheme / darkTheme
│   │   ├── app_text_styles.dart       # Poppins type scale
│   │   └── app_spacing.dart           # 8px scale + radii constants
│   ├── routing/
│   │   ├── app_routes.dart            # route name constants + generator
│   │   └── page_transitions.dart      # fade & slide PageRouteBuilders
│   └── utils/
│       ├── validators.dart            # email / password / required / match
│       └── date_formatter.dart        # "Today · 6:00 PM", "Yesterday", ...
│
├── data/
│   ├── models/
│   │   ├── task.dart                  # Task entity + copyWith + toMap/fromMap
│   │   ├── task_priority.dart         # enum high/medium/low + label
│   │   └── app_user.dart              # id, name, email
│   └── repositories/
│       ├── auth_repository.dart       # ABSTRACT — Phase 2 seam
│       ├── mock_auth_repository.dart   # in-memory + SharedPreferences
│       └── task_repository.dart       # in-memory list (Firestore in Phase 2)
│
├── providers/
│   ├── auth_provider.dart             # current user, login/signup/logout
│   ├── task_provider.dart             # CRUD + derived pending/completed lists
│   └── theme_provider.dart            # ThemeMode + persistence   [Wafaa]
│
├── screens/
│   ├── splash/splash_screen.dart
│   ├── login/login_screen.dart
│   ├── signup/signup_screen.dart
│   ├── home/home_screen.dart
│   └── add_edit/add_edit_task_screen.dart
│
└── widgets/
    ├── primary_button.dart            # filled black, 10px radius
    ├── secondary_button.dart          # outlined / text
    ├── app_text_field.dart            # label + border states + error text
    ├── task_card.dart                 # the list row
    ├── animated_checkbox.dart         # circular, scale-in check
    ├── priority_pill.dart             # HIGH / MED / LOW outline chip
    ├── section_label.dart             # "PENDING" / "COMPLETED"
    ├── empty_state.dart               # icon + message when list is empty
    ├── confirm_dialog.dart            # delete confirmation
    └── theme_toggle.dart              # AppBar switch            [Wafaa]

assets/
└── fonts/  (or google_fonts at runtime — see §4.2)
```

---

## 4. Design System

### 4.1 Color tokens

`app_colors.dart` exposes two classes so every widget reads from a token, never a raw hex.

**Light mode (default)**

| Token | Usage | Hex |
|---|---|---|
| `background` | Screen backgrounds | `#FFFFFF` |
| `surface` | Cards, sheets, dialogs | `#FAFAFA` |
| `textPrimary` | Titles, main content | `#000000` |
| `textSecondary` | Subtitles, hints, completed tasks | `#616161` |
| `textTertiary` | Section labels | `#9E9E9E` |
| `accent` | Buttons, FAB, active icons, checkmarks | `#000000` |
| `onAccent` | Text/icon on accent | `#FFFFFF` |
| `border` | Card borders, dividers | `#E0E0E0` |
| `error` | Validation errors | `#B00020` |
| `disabled` | Disabled buttons/fields | `#BDBDBD` |

**Dark mode**

| Token | Usage | Hex |
|---|---|---|
| `background` | Screen backgrounds | `#000000` |
| `surface` | Cards, sheets, dialogs | `#121212` |
| `textPrimary` | Titles, main content | `#FFFFFF` |
| `textSecondary` | Subtitles, hints, completed | `#B0B0B0` |
| `textTertiary` | Section labels | `#8A8A8A` |
| `accent` | Buttons, FAB, active icons | `#FFFFFF` |
| `onAccent` | Text/icon on accent | `#000000` |
| `border` | Card borders, dividers | `#2C2C2C` |
| `error` | Validation errors | `#CF6679` |
| `disabled` | Disabled | `#3A3A3A` |

> Dark `disabled` is not in the PDF — `#3A3A3A` added so disabled states stay visible on black.

### 4.2 Typography

Font family **Poppins**, applied via `GoogleFonts.poppinsTextTheme()` in `ThemeData`.
(If offline builds are a concern, vendor the `.ttf` files into `assets/fonts/` and declare in `pubspec.yaml` instead — same result, no network at first launch. **Recommended for the APK deliverable.**)

| Style | Size | Weight | Color token | Used on |
|---|---|---|---|---|
| `splashTitle` | 28sp | Bold (700) | textPrimary | Splash app name |
| `screenTitle` | 24sp | Bold (700) | textPrimary | Login/Signup headline |
| `appBarTitle` | 19sp | Bold (700) | textPrimary | AppBar |
| `taskTitle` | 15sp | Medium (500) | textPrimary | Task card title |
| `taskTitleDone` | 15sp | Regular (400) | textSecondary + `lineThrough` | Completed task |
| `taskMeta` | 11sp | Regular (400) | textSecondary | "Today · 6:00 PM" |
| `sectionLabel` | 11sp | Bold (700), `letterSpacing: .05em`, UPPERCASE | textTertiary | PENDING / COMPLETED |
| `body` | 13sp | Regular | textSecondary | Hints, helper text |
| `label` | 13sp | Medium | textPrimary | Field labels |
| `button` | 15sp | SemiBold (600) | onAccent | All buttons — **Title Case** |
| `priority` | 9.5sp | Bold (700) | textPrimary | Priority pill |

Button casing: **Title Case everywhere** ("Log In", "Sign Up", "Save Task"). Pick once, never mix.

### 4.3 Spacing & shape

```dart
// app_spacing.dart
const double xs = 4, sm = 8, md = 16, lg = 24, xl = 32;
const double screenPaddingH = 16;   // minimum horizontal screen padding
const double cardRadius   = 12;
const double buttonRadius = 10;
const double fieldRadius  = 10;
const double borderWidth  = 1;
```

- Base unit **8px** — all padding/gaps are multiples (8/16/24/32).
- Gap between task cards: **10px**.
- Card elevation: **flat**. A 1px border replaces every shadow.
- FAB is the single exception: soft shadow, 52×52, bottom-right, inset 20px right / 22px bottom.

### 4.4 Motion catalog

| Interaction | Animation | Duration | Curve |
|---|---|---|---|
| Splash → Login | Fade | 300ms | `easeInOut` |
| Login ↔ Signup | Slide horizontal + fade | 250ms | `easeInOut` |
| Login/Signup → Home | Fade | 300ms | `easeInOut` |
| Home → Add/Edit | Slide up from bottom + fade | 250ms | `easeOutCubic` |
| Checkbox toggle | Scale 0→1 on the check mark + fill | 150ms | `easeOutBack` |
| Task insert | Slide in from left + fade | 250ms | `easeOut` |
| Task remove | Slide out right + fade + size collapse | 250ms | `easeIn` |
| Task moves Pending↔Completed | Same insert/remove pair | 250ms | — |
| Splash logo entry | Fade + scale 0.9→1.0 | 600ms | `easeOut` |

Rule: nothing exceeds 300ms. Subtle polish, not flash.

---

## 5. Component Specs

### 5.1 `PrimaryButton`
Filled `accent` background, `onAccent` text, 10px radius, height 52, full width by default.
Disabled → `disabled` background, `onAccent` text at 70% opacity, no ripple.
Loading variant → replaces label with a 20px `CircularProgressIndicator` in `onAccent`.

### 5.2 `SecondaryButton`
Transparent background, `accent` text, optional 1px `accent` outline. Same height/radius.
Used for "Cancel", "Create an account", "Already have an account? Log In".

### 5.3 `AppTextField`
```
┌ Label (13sp, medium, textPrimary)
│ ┌──────────────────────────────────┐
│ │ hint / value                     │   ← surface bg, 1px border, 10px radius
│ └──────────────────────────────────┘      height 52, padding 16h
└ Helper or error text (12sp)
```
| State | Border | Helper |
|---|---|---|
| Default | `border` 1px | hint in textSecondary |
| Focused | `accent` 1.5px | — |
| Error | `error` 1.5px | error text in `error`, 12sp, 4px below |
| Disabled | `disabled` 1px | field text at `disabled` |

Password fields get a trailing outline eye icon toggling obscurity.

### 5.4 `TaskCard`
```
┌────────────────────────────────────────────────┐
│ ◯   Finish Phase 1 report            ⌜HIGH⌝ ✎ 🗑 │
│     Today · 6:00 PM                             │
└────────────────────────────────────────────────┘
  ↑                                    ↑
 checkbox 20px, 1.6px border    outline icons 18px, 65% opacity
```
- `surface` background, 1px `border`, 12px radius, padding 14v / 12h, gap 12px.
- Tap anywhere on the body → open Add/Edit in edit mode.
- Tap the checkbox → toggle complete (does **not** open the editor).
- Completed: title grey + strikethrough; priority pill hidden; meta stays.
- Long title → single line with ellipsis.
- Icons: `Icons.edit_outlined`, `Icons.delete_outline`.

### 5.5 `AnimatedCheckbox`
20×20 circle, 1.6px `accent` border, transparent when pending.
Complete → fills solid `accent`, white/black check draws in with a 150ms scale (`easeOutBack`).

### 5.6 `PriorityPill`
Outline chip: 1px `textPrimary` border, 20px radius, padding 2v/7h, 9.5sp bold.
Labels **HIGH / MED / LOW**. Monochrome — priority is conveyed by the label and by sort order, not colour (the design system has no colour to spare).

### 5.7 `SectionLabel`
11sp bold uppercase, `textTertiary`, letterSpacing .05em, margin 6px top / 4px left.
Rendered only when its section is non-empty.

### 5.8 `EmptyState`
Centred column: 64px outline icon (`Icons.checklist_outlined`) at `textTertiary`, 16px gap,
"No tasks yet" (`screenTitle`), 8px gap, "Tap + to add your first one" (`body`).

### 5.9 `ConfirmDialog`
`surface` background, 12px radius, no elevation, 1px border.
Title "Delete task?" · body "This can't be undone." · actions: `SecondaryButton` Cancel + `PrimaryButton` Delete.

### 5.10 SnackBar
Floating, `accent` background, `onAccent` text, 10px radius, 2s.
Used for: task deleted (with **Undo** action), task saved, login failed.

---

## 6. Screen Structure

### 6.1 Splash — `/` — **[Mostafa]**

```
Scaffold(background)
└── Center
    └── Column(mainAxisSize.min)
        ├── AnimatedOpacity + scale
        │   └── Icon check_circle_outline, 72px, accent
        ├── SizedBox(24)
        ├── Text "Taskaya"        splashTitle 28sp bold
        ├── SizedBox(8)
        └── Text "Minimal tasks. Nothing else."   body, textSecondary
```
Behaviour: logo fades+scales in over 600ms, holds, then after **2000ms total** navigates.
Destination: `AuthProvider.isLoggedIn ? Home : Login` (mock session read from SharedPreferences).
Navigation uses `pushReplacement` with a fade transition — splash must not be reachable via back.

### 6.2 Login — `/login` — **[Mostafa]**

```
Scaffold(background) → SafeArea → SingleChildScrollView (padding 24h)
└── Column(crossAxisAlignment.stretch)
    ├── SizedBox(72)
    ├── Text "Welcome back"            screenTitle 24sp bold
    ├── SizedBox(8)
    ├── Text "Log in to continue."     body
    ├── SizedBox(40)
    ├── AppTextField  Email       keyboardType.emailAddress
    ├── SizedBox(16)
    ├── AppTextField  Password    obscure + eye toggle
    ├── SizedBox(8)
    ├── Align.right → TextButton "Forgot password?"   (inert in Phase 1)
    ├── SizedBox(24)
    ├── PrimaryButton "Log In"
    ├── SizedBox(16)
    └── Row(center)
        ├── Text "Don't have an account?"  body
        └── SecondaryButton "Sign Up"  → push Signup
```
Validation (on submit, `Form` + `GlobalKey<FormState>`):
- Email: required, must match email regex → *"Enter a valid email address"*
- Password: required, ≥6 chars → *"Password must be at least 6 characters"*
- Credentials not found in mock store → SnackBar *"Incorrect email or password"*

Success → `pushReplacementNamed(Home)` with fade.
`SingleChildScrollView` + `resizeToAvoidBottomInset` so the keyboard never overflows.

### 6.3 Signup — `/signup` — **[Ahmed]**

```
Scaffold(background) → SafeArea → SingleChildScrollView (padding 24h)
└── Column(stretch)
    ├── SizedBox(56)
    ├── BackButton (outline arrow, accent)        ← top-left, above headline
    ├── Text "Create account"          screenTitle
    ├── Text "Start organising today." body
    ├── SizedBox(32)
    ├── AppTextField  Full name
    ├── AppTextField  Email
    ├── AppTextField  Password           obscure + eye
    ├── AppTextField  Confirm password   obscure + eye
    ├── SizedBox(24)
    ├── PrimaryButton "Sign Up"
    ├── SizedBox(16)
    └── Row(center) "Already have an account?" + SecondaryButton "Log In"  → pop
```
Validation:
- Name: required, ≥2 chars → *"Enter your name"*
- Email: required + regex; already registered → *"That email is already registered"*
- Password: required, ≥6 chars
- Confirm: must equal password → *"Passwords do not match"*

Success → create user in mock store, auto-login, `pushReplacementNamed(Home)`.

### 6.4 Home — `/home` — **[Ahmed]**  (toggle **[Wafaa]**)

```
Scaffold(background)
├── AppBar  (elevation 0.5, background, 1px bottom border)
│   ├── title: "Taskaya"        appBarTitle
│   └── actions: [ ThemeToggle(44×24 pill switch), logout icon ]
│
├── body: Consumer<TaskProvider>
│   ├── if tasks.isEmpty        → EmptyState
│   └── else CustomScrollView (padding 16h, top 16)
│       ├── SliverToBoxAdapter  SectionLabel "PENDING"      (if any)
│       ├── SliverAnimatedList  pending tasks → TaskCard
│       ├── SliverToBoxAdapter  SectionLabel "COMPLETED"    (if any)
│       └── SliverAnimatedList  completed tasks → TaskCard
│
└── FAB: 52px circle, accent bg, onAccent "+" (Icons.add), bottom-right
        → push AddEdit in *create* mode (slide-up transition)
```
Ordering: pending sorted by priority (High→Med→Low) then by due date ascending, undated last.
Completed sorted by most recently completed first.

Interactions:
- Checkbox tap → `toggleComplete(id)`; card animates out of its section and into the other.
- Card body tap → AddEdit in *edit* mode.
- Delete icon → `ConfirmDialog`; on confirm, animated removal + SnackBar with **Undo**.
- Logout → clears mock session, `pushNamedAndRemoveUntil(Login)`.

The theme toggle matches the mockup exactly: 44×24 pill, 20px knob. Light = grey track, knob left. Dark = white track, knob right. Knob is black in both.

### 6.5 Add / Edit Task — `/task` — **[Ahmed]**

One screen, two modes, decided by whether a `Task` argument was passed.

```
Scaffold(background)
├── AppBar  leading: close (X) icon
│   └── title: "New Task"  |  "Edit Task"
│
├── body: SingleChildScrollView (padding 16h, 24 top)
│   └── Form
│       ├── AppTextField  Title          required, autofocus, max 60 chars
│       ├── SizedBox(16)
│       ├── AppTextField  Description    optional, maxLines 4
│       ├── SizedBox(24)
│       ├── Text "Priority"              label
│       ├── SizedBox(8)
│       ├── Row of 3 selectable pills    HIGH / MED / LOW
│       │      selected = filled accent + onAccent text
│       │      unselected = outline + textPrimary
│       ├── SizedBox(24)
│       ├── Text "Due date"              label
│       ├── SizedBox(8)
│       └── Row
│           ├── OutlinedTile  calendar icon + "Select date"|formatted
│           ├── SizedBox(8)
│           └── OutlinedTile  clock icon + "Select time"|formatted
│               (a small X clears each once set)
│
└── bottomNavigationBar: SafeArea + padding 16
    └── Row
        ├── Expanded SecondaryButton "Cancel"   → pop
        ├── SizedBox(12)
        └── Expanded PrimaryButton "Save Task" | "Save Changes"
```
Validation: title required, trimmed, non-empty → *"Task title can't be empty"*.
`showDatePicker` / `showTimePicker` themed to the monochrome palette via a local `Theme` wrapper.
Defaults in create mode: priority = **MED**, no due date.
On save → `addTask` or `updateTask`, pop, SnackBar confirmation.
Back/close with unsaved edits → discard-changes confirm dialog.

---

## 7. Data Model & State

### 7.1 `TaskPriority`
```dart
enum TaskPriority { high, medium, low }
// label => "HIGH" | "MED" | "LOW";  sortOrder => 0 | 1 | 2
```

### 7.2 `Task`
```dart
class Task {
  final String id;              // uuid v4
  final String title;
  final String description;     // '' when unset
  final bool isCompleted;
  final TaskPriority priority;
  final DateTime? dueDate;      // date + time combined, null = no due date
  final DateTime createdAt;
  final DateTime? completedAt;

  Task copyWith({...});
  Map<String, dynamic> toMap();       // Phase 2: Firestore document
  factory Task.fromMap(Map<String, dynamic>);
}
```
`toMap`/`fromMap` exist now even though nothing persists tasks in Phase 1 — it is the Firestore seam, and it costs nothing to write today.

### 7.3 `AppUser`
```dart
class AppUser { final String id, name, email; }
```

### 7.4 `TaskProvider extends ChangeNotifier`
```dart
List<Task> get pending;        // filtered + sorted
List<Task> get completed;
bool get isEmpty;

void addTask(Task task);
void updateTask(Task task);
void deleteTask(String id);      // returns the removed task for Undo
void toggleComplete(String id);  // sets/clears completedAt
void restoreTask(Task task, int index);  // Undo
```
Seeded with 2–3 sample tasks on first run so the Home screen and the report screenshots are never empty. (Remove or keep — team call; keeping them makes the demo smoother.)

### 7.5 `AuthProvider extends ChangeNotifier`
Wraps `AuthRepository`. Exposes `currentUser`, `isLoggedIn`, `isLoading`,
`Future<String?> login(email, password)`, `signup(...)`, `logout()` — returning `null` on success or an error message string.

### 7.6 The Phase 2 seam
```dart
abstract class AuthRepository {
  Future<AppUser> login(String email, String password);
  Future<AppUser> signup(String name, String email, String password);
  Future<void> logout();
  AppUser? get currentUser;
}
```
Phase 1 ships `MockAuthRepository` (in-memory user map + SharedPreferences session).
Phase 2 ships `FirebaseAuthRepository`. **One line changes in `main.dart`. No screen is touched.**

---

## 8. Routing

```dart
class AppRoutes {
  static const splash = '/';
  static const login  = '/login';
  static const signup = '/signup';
  static const home   = '/home';
  static const task   = '/task';   // arguments: Task? (null = create mode)
}
```

Navigation map:
```
Splash ──(logged in)──► Home
   └───(logged out)───► Login ◄──► Signup
                          └──────────┴──► Home ──► Add/Edit ──► back to Home
```
- Splash→next and Login/Signup→Home use `pushReplacement` (no back into auth).
- Logout uses `pushNamedAndRemoveUntil` to clear the stack.
- Android hardware back on Home → confirm-exit dialog, not a jump back to Login.

`page_transitions.dart` provides `fadeRoute(page)`, `slideRightRoute(page)`, `slideUpRoute(page)` — all built on `PageRouteBuilder` at the durations in §4.4.

---

## 9. Ownership

| Area | Mostafa (202202211) | Ahmed (202202151) | Wafaa (202202056) |
|---|---|---|---|
| **Screens** | Splash, Login | Signup, Home, Add/Edit | Theme toggle widget |
| **Logic** | Login validation, mock auth, routing setup | Signup validation, Task model, full CRUD, state mgmt | Theme persistence |
| **Testing** | Navigation flow, all 5 screens | CRUD + validation edge cases | Final QA, light+dark, clean build |
| **Extra** | Leader: APK build, zip, merge | — | PDF report + screenshots |

**Shared foundation** (`core/theme/`, `core/routing/`, `pubspec.yaml`, scaffold) is not owned by anyone in the split. Recommendation: build it once, up front, before anyone starts screens — otherwise Mostafa and Ahmed each invent their own colours and the app looks like two apps.

`theme_provider.dart` and `theme_toggle.dart` are **Wafaa's**. Build `app_theme.dart` (both `ThemeData` objects) as shared foundation, but leave the provider and toggle as stubs for her.

---

## 10. Build Order

**Step 0 — Scaffold** *(shared, do first)*
`flutter create`, dependencies, `app_colors` / `app_text_styles` / `app_spacing` / `app_theme`, `page_transitions`, `app_routes`, `main.dart` with `MultiProvider`. Verify: app boots to a black-on-white blank screen in both themes.

**Step 1 — Shared widgets** *(shared)*
`PrimaryButton`, `SecondaryButton`, `AppTextField`, `ConfirmDialog`. Everything downstream depends on these.

**Step 2 — Mostafa: Splash + routing** — splash animates, waits, navigates. Routes registered.

**Step 3 — Mostafa: Login + mock auth** — `AuthRepository`, `MockAuthRepository`, `AuthProvider`, Login UI + validation.

**Step 4 — Ahmed: Signup** — reuses the auth stack from step 3; validation + registration.

**Step 5 — Ahmed: Task model + provider** — `Task`, `TaskPriority`, `TaskRepository`, `TaskProvider`. Pure logic, no UI.

**Step 6 — Ahmed: Home** — `TaskCard`, `AnimatedCheckbox`, `PriorityPill`, `SectionLabel`, `EmptyState`, sectioned animated list, FAB.

**Step 7 — Ahmed: Add/Edit** — form, priority selector, date/time pickers, save wiring.

**Step 8 — Wafaa: Dark mode** — `ThemeProvider` + `ThemeToggle` + SharedPreferences.

**Step 9 — Polish & QA** — `flutter analyze` clean, all transitions verified, both themes walked end to end.

**Step 10 — Deliverables** — release APK, screenshots (both themes, all 5 screens), PDF report, zip.

Steps 2–3 and 4–7 are independent once step 1 lands — Mostafa and Ahmed can work in parallel on separate branches.

---

## 11. Test Checklist

**Navigation [Mostafa]**
- [ ] Splash auto-navigates within ~2s
- [ ] Logged-out splash → Login; logged-in splash → Home
- [ ] Login ↔ Signup both directions
- [ ] Back button cannot return to Splash, or to Login after auth
- [ ] Home → Add/Edit → back returns to Home with the list updated
- [ ] Android hardware back on Home prompts exit
- [ ] Every transition animates; none janks or flashes white in dark mode

**CRUD & validation [Ahmed]**
- [ ] Add task with title only
- [ ] Add with title + description + priority + due date
- [ ] Empty title rejected; whitespace-only title rejected
- [ ] Edit persists every field
- [ ] Delete asks for confirmation; Undo restores at the right position
- [ ] Toggle complete moves the card between sections, both directions
- [ ] Empty state shows when the last task is deleted
- [ ] Login: empty email, malformed email, short password, wrong credentials
- [ ] Signup: short name, duplicate email, mismatched passwords
- [ ] Keyboard never overflows any form

**QA [Wafaa]**
- [ ] `flutter analyze` → 0 issues
- [ ] Release APK builds and installs
- [ ] Every screen legible in both themes; no hardcoded colour leaks
- [ ] Toggle persists across a full app restart

---

## 12. Deliverables

| Item | Owner |
|---|---|
| Flutter project folder (zipped) | Mostafa |
| Source code (git, `main`) | All |
| Release APK (`flutter build apk --release`) | Mostafa |
| PDF report — team members, description, screenshots, contributions | Wafaa |

---

## 13. Open Decisions

1. **Priority & due date in Phase 1** — recommended yes (§1). Needs a team call.
2. **Poppins delivery** — bundle the TTFs rather than `google_fonts` runtime fetch, so the APK works offline on the grader's device. Recommended.
3. **Seed tasks** — keep 2–3 samples on first run for demo/screenshots, or ship empty? Recommended: keep.
4. **"Forgot password?"** — render it inert in Phase 1 (visual completeness) or omit it? Recommended: render, wire in Phase 2.
