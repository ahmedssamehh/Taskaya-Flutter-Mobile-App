# Taskaya — Premium UI Specification

Companion to `Phase1_Implementation_Plan.md`. This document **overrides** §4–§6 of that plan
wherever the two disagree. Produced by auditing the original mockup against the
UI/UX Pro Max rule set (accessibility, touch, style, layout, typography, animation, forms, navigation).

**Design thesis:** in a monochrome interface there is no colour to carry hierarchy, state, or
delight. All of it must come from **type weight, spacing rhythm, contrast steps, and motion**.
That constraint is what makes it read as premium rather than unfinished — but only if those four
are executed with discipline. Every rule below exists to protect one of them.

---

## 1. Brand

### 1.1 The mark

A rounded square (the task card) containing a checkmark whose ascending stroke **breaks out
through the top-right corner**. One gesture, pure geometry, single colour.

```svg
<svg viewBox="0 0 48 48" fill="none">
  <rect x="5" y="13" width="30" height="30" rx="8" stroke="currentColor" stroke-width="3.5"/>
  <path d="M13 29 L21 36 L43 7" stroke="currentColor" stroke-width="3.5"
        stroke-linecap="round" stroke-linejoin="round"/>
</svg>
```

Source: `Project Docs/brand/taskaya_mark.svg`

| Rule | Value |
|---|---|
| Colour | `currentColor` only — never hardcoded. Inherits `accent`, so it inverts for free in dark mode. |
| Stroke | 3.5 at 48px. **At ≤24px bump to 4.5** — a 3.5 stroke optically vanishes at small sizes. |
| Clear space | Minimum 25% of mark height on all sides. |
| Minimum size | 16px. Below that use the wordmark alone. |
| Never | Recolour, add a gradient, rotate, outline the outline, or place on a mid-grey background. |

### 1.2 Wordmark

`Task` at weight 500 + `aya` at weight 400 / 50% opacity. Letter-spacing `-0.02em`.
The weight split is the only hierarchy device available without colour — use it, and use it
*only* here (body text never mixes weights mid-string).

The split is deliberate: it surfaces the word `Task` inside the name, so the mark and the wordmark
say the same thing. Never hyphenate, space, or capitalise it as `TaskAya` — the lowercase `aya`
carries the split on its own.

### 1.3 App icon (launcher)

Solid black square, white mark centred at 60% of canvas. Adaptive icon for Android:
black background layer, white mark foreground layer. No rounded corners baked in — the OS masks.

---

## 2. Corrections to the Original Mockup

Nine issues found. These are the difference between "vibe-coded" and shippable.

| # | Issue | Rule violated | Fix |
|---|---|---|---|
| 1 | Section label `#9E9E9E` on white = **2.7:1** | `color-contrast` (CRITICAL, needs 4.5:1) | → `#757575` (4.6:1) |
| 2 | Task meta at 11sp, priority pill at 9.5sp | `readable-font-size`, no body text under 12px | meta → 12sp, pill removed entirely |
| 3 | Edit + delete icons at 16px, 65% opacity | `touch-target-size` (44pt min), `icon-contrast` | **Removed from the card** — see §4.2 |
| 4 | Card row holds checkbox + title + meta + pill + 2 icons | `no-precision-required`, `data-density` | Reduced to checkbox + title + meta |
| 5 | 20px checkbox with no expanded hit area | `touch-target-size` | 21px visual, 44×44 hit area |
| 6 | 44×24 toggle switch, no label | `touch-target-size`, `nav-label-icon` | 44×44 icon button, sun/moon, `Semantics` label |
| 7 | No `prefers-reduced-motion` handling | `reduced-motion` (CRITICAL) | Global motion kill-switch, §5.4 |
| 8 | Fixed 52px control heights | `dynamic-type` | Min-height + intrinsic growth |
| 9 | Instant mock login | `submit-feedback`, `progressive-loading` | Real async + loading state, §6.2 |

### The priority-pill decision

The mockup put a `HIGH` / `MED` / `LOW` outline chip on every card. Three problems: it adds a
fifth element to an already-crowded row, it sits at 9.5sp, and in monochrome the three pills are
visually identical — the chip conveys nothing the text doesn't.

**Replaced by a text fragment in the meta line:** `Today, 18:00 · High`.
Same information, one less element, no touch target, no contrast problem, and it satisfies
`color-not-only` for free. Medium priority renders nothing at all — the default is silence.

---

## 3. Design Tokens (revised)

### 3.1 Colour — with verified contrast ratios

**Light**

| Token | Hex | On bg | Ratio | Pass |
|---|---|---|---|---|
| `background` | `#FFFFFF` | — | — | — |
| `surface` | `#FAFAFA` | — | — | — |
| `textPrimary` | `#000000` | `#FFFFFF` | 21:1 | AAA |
| `textSecondary` | `#616161` | `#FAFAFA` | 6.0:1 | AA |
| `textTertiary` | `#757575` | `#FFFFFF` | 4.6:1 | AA |
| `accent` | `#000000` | — | — | — |
| `onAccent` | `#FFFFFF` | `#000000` | 21:1 | AAA |
| `border` | `#E0E0E0` | `#FFFFFF` | 1.3:1 | decorative |
| `borderStrong` | `#000000` | — | focus/pressed | — |
| `error` | `#B00020` | `#FFFFFF` | 8.0:1 | AAA |
| `disabled` | `#BDBDBD` | — | — | — |
| `scrim` | `rgba(0,0,0,0.5)` | — | modal backdrop | — |

**Dark**

| Token | Hex | On bg | Ratio | Pass |
|---|---|---|---|---|
| `background` | `#000000` | — | — | — |
| `surface` | `#121212` | — | — | — |
| `textPrimary` | `#FFFFFF` | `#000000` | 21:1 | AAA |
| `textSecondary` | `#B0B0B0` | `#121212` | 8.6:1 | AAA |
| `textTertiary` | `#8A8A8A` | `#000000` | 6.1:1 | AA |
| `accent` | `#FFFFFF` | — | — | — |
| `onAccent` | `#000000` | `#FFFFFF` | 21:1 | AAA |
| `border` | `#2C2C2C` | `#000000` | 1.6:1 | decorative |
| `borderStrong` | `#FFFFFF` | — | focus/pressed | — |
| `error` | `#CF6679` | `#000000` | 7.1:1 | AAA |
| `disabled` | `#3A3A3A` | — | added — PDF omitted it | — |
| `scrim` | `rgba(0,0,0,0.6)` | — | stronger on black | — |

Two tokens added beyond the PDF: `borderStrong` (focus + pressed states need a border that isn't
hairline grey) and `scrim`. Dark `disabled` is new — grey-on-black at the light-mode value was
invisible.

**Rule:** no widget ever reads a raw hex. Every colour comes from
`Theme.of(context).extension<AppColors>()`. A single hardcoded `Colors.grey` is the failure mode
that makes dark mode leak.

### 3.2 Type scale

Poppins. Weights **400 / 500 / 600 only** — three is a system, five is a mess.

| Style | Size | Weight | Tracking | Line height |
|---|---|---|---|---|
| `display` (splash) | 30 | 600 | -0.02em | 1.2 |
| `titleLarge` (screen headline) | 26 | 600 | -0.02em | 1.25 |
| `titleMedium` (app bar) | 22 | 600 | -0.02em | 1.3 |
| `taskTitle` | 15 | 500 | -0.01em | 1.35 |
| `body` | 15 | 400 | 0 | 1.5 |
| `label` (field labels) | 13 | 500 | 0 | 1.4 |
| `meta` (dates, counts) | 12 | 400 | 0 | 1.4 |
| `overline` (section labels) | 11 | 500 | **+0.09em** | 1.2 |
| `button` | 15 | 600 | -0.01em | 1 |

Two tracking rules, and they are what separate a considered type system from a default one:
**negative tracking on large text** (headlines tighten optically), **positive tracking on small
caps** (11sp uppercase needs air to stay legible). Body text stays at 0.

Numerals in dates, times, and counts use **tabular figures**
(`fontFeatures: [FontFeature.tabularFigures()]`) so a live countdown or a changing count doesn't
jitter the layout.

**Dynamic Type:** no fixed heights on anything containing text. Buttons use
`minimumSize: Size(double.infinity, 52)` — a floor, not a ceiling. Test at
`textScaler: TextScaler.linear(1.5)`.

### 3.3 Spacing & shape

Base **4pt**, primary rhythm **8pt**.

```
space:   4  8  12  16  24  32  48
radius:  card 12 · control 10 · pill 999 · sheet 20 (top corners only)
border:  hairline 1 · focus 2 · pressed 1.75
```

Vertical rhythm tiers — same-level elements get the same gap, always:
- Between cards in a list: **10**
- Between a section label and its first card: **10**
- Between the end of a section and the next section label: **24**
- Between form fields: **16**
- Between a form block and its CTA: **24**
- Screen top padding below safe area: **26**

Horizontal screen inset: **20** (raised from 16 — 20 reads calmer at 390pt and gives the card
border room to breathe).

### 3.4 Elevation

**There is no elevation scale.** Every surface is flat with a 1px hairline border.
Exactly two exceptions, both functional:
- **FAB** — `0 6px 16px rgba(0,0,0,0.24)` in light, none in dark (a white FAB on black needs no lift)
- **Bottom sheet / dialog** — the scrim provides separation, not a shadow

App bar `elevation: 0` with a 1px bottom border that appears **only once the list scrolls**
(`scrolledUnderElevation: 0` + a scroll-driven border). A static divider under a large title is a
default-Flutter tell.

---

## 4. Component Revisions

### 4.1 Home header — large title, not an AppBar

The mockup's centred-ish AppBar with a toggle is generic. Replace with a **large-title header**
that earns its space:

```
┌─────────────────────────────────────────┐
│  ◪ Taskaya                         ☾   │   mark 20px + wordmark 24/600
│  3 pending · 2 done                     │   meta 13, textSecondary
└─────────────────────────────────────────┘
```

The subtitle is not decoration — it is the only place in the app that summarises state, and it
gives the header a reason to be large. It updates live from `TaskProvider`.

On scroll, the large title collapses into a 22sp centred title with the hairline border fading in
(`SliverAppBar` + `FlexibleSpaceBar`, 200ms). This single behaviour does more for perceived
quality than any other item in this document.

### 4.2 Task card — what was removed

```
┌──────────────────────────────────────────────┐
│  ◯   Finish Phase 1 report                   │   15/500, -0.01em
│      Today, 18:00 · High                     │   12/400, tabular
└──────────────────────────────────────────────┘
   ↑ 21px visual, 44×44 hit area
```

- Card padding 15v / 14h, gap 14. Radius 12. 1px hairline.
- **Whole card is one tap target** → opens edit. No chevron, no icons.
- **Swipe left → delete** (`Dismissible`), revealing a black panel with a white trash icon and the
  word "Delete". Confirm dialog before the dismissal commits.
- **Long-press → context menu** (Edit / Duplicate / Delete). This is the `gesture-alternative`
  requirement: swipe is never the *only* route to a destructive action, and Delete also lives at
  the bottom of the Edit screen.
- Pressed state: card background steps to `#F2F2F2` / `#1C1C1C`. **No scale transform** on list
  rows — scaling a row shifts its neighbours optically.
- Completed: title → `textTertiary` + strikethrough, weight drops 500→400. Meta unchanged.

### 4.3 Checkbox

21px circle, 1.75px `accent` border, 44×44 hit area via `GestureDetector` + `SizedBox`.

Completion animation, 220ms total:
1. `0–80ms` — circle fill scales 0→1 from centre, `easeOutCubic`
2. `60–220ms` — check path draws via `CustomPainter` + `PathMetric`, `easeOutCubic`
3. `0–120ms` — light haptic (`HapticFeedback.selectionClick()`)

Uncompleting reverses at **150ms** (68% of enter — `exit-faster-than-enter`).

### 4.4 Buttons

| Variant | Fill | Text | Border | Height |
|---|---|---|---|---|
| Primary | `accent` | `onAccent` 15/600 | none | min 52 |
| Secondary | transparent | `textPrimary` 15/600 | 1px `border` | min 52 |
| Text | transparent | `textPrimary` 15/500 | none | min 44 |
| Destructive | transparent | `error` 15/600 | 1px `error` | min 52 |

Pressed: **opacity 0.85 + background step**, never a scale transform on full-width buttons.
Disabled: `disabled` fill, `onAccent` at 50%, `Semantics(enabled: false)`.
Loading: label swaps for an 18px 2px-stroke `CircularProgressIndicator`; **width does not change**
(reserve it with a `SizedBox` of the measured label width) — a button that resizes mid-submit is a
layout-shift tell.

### 4.5 Text field

```
Email                              ← label 13/500, always visible, never placeholder-only
┌───────────────────────────────┐
│ you@example.com               │  ← 15/400, min-height 52, radius 10
└───────────────────────────────┘
Enter a valid email address       ← 12/400, error colour, with a 14px alert icon
```

| State | Border |
|---|---|
| Rest | 1px `border` |
| Focus | **2px `borderStrong`** |
| Error | 2px `error` + icon + message |
| Disabled | 1px `disabled`, text at `disabled` |

- Validation on **blur**, not per-keystroke (`inline-validation`).
- On submit failure, focus jumps to the first invalid field (`focus-management`).
- Errors announced via `SemanticsService.announce` (`aria-live-errors`).
- `keyboardType` + `autofillHints` set on every field (`input-type-keyboard`, `autofill-support`).
- Password: trailing 44×44 eye toggle with `Semantics(label: 'Show password')`.

### 4.6 Empty state

Centred, but sitting at **38% of viewport height, not 50%** — optical centre beats mathematical
centre.

```
        ◪            mark at 56px, textTertiary
   Nothing here yet   titleMedium
 Tap + to add your    body, textSecondary, max 2 lines
    first task
    [ Add task ]      secondary button — a CTA, not just a message
```

### 4.7 Theme toggle

44×44 icon button, `ti-moon` in light / `ti-sun` in dark, top-right of the header.
`Semantics(label: 'Switch to dark theme')` — updated per state.
Transition: `AnimatedTheme` 300ms + a 180° icon rotation. Not a raw `setState` swap.

---

## 5. Motion System

### 5.1 Tokens

```dart
const durFast   = Duration(milliseconds: 150);  // press, micro
const durBase   = Duration(milliseconds: 220);  // state change
const durScreen = Duration(milliseconds: 280);  // navigation
const durExit   = Duration(milliseconds: 180);  // ~65% of enter

const easeEnter = Curves.easeOutCubic;
const easeExit  = Curves.easeInCubic;
const easeSpring = Curves.easeOutBack;  // checkbox fill only
```

One rhythm across the whole app. If a new animation needs a duration not in this list, the
animation is wrong.

### 5.2 Catalog

| Interaction | Motion | Duration |
|---|---|---|
| Splash → next | Fade | 280 enter |
| Login ↔ Signup | Slide X ±24px + fade | 280 / 180 |
| Auth → Home | Fade + scale 0.98→1 | 280 |
| Home → Add/Edit | Slide up from FAB origin + fade | 280 / 180 |
| Card tap → Edit | **Shared-element**: card morphs into the sheet | 300 |
| Checkbox toggle | Fill scale + path draw | 220 / 150 |
| Task insert | Slide X −16 + fade + size expand | 250 |
| Task remove | Fade + size collapse | 180 |
| Section reorder | `AnimatedSwitcher` crossfade | 220 |
| List first paint | Stagger **40ms per item, capped at 6 items** | 250 each |
| Large title collapse | Scroll-driven | continuous |

`Home → Add/Edit` animates **from the FAB's position**, not from the screen edge — `modal-motion`.

### 5.3 Prohibited

- Anything over 300ms
- Animating `width` / `height` / `top` / `left` — transform and opacity only
- Decorative motion with no cause-effect (`motion-meaning`)
- Blocking input during an animation (`no-blocking-animation`)
- Uninterruptible animations — a tap mid-transition must cancel it (`interruptible`)

### 5.4 Reduced motion — mandatory

```dart
final reduceMotion = MediaQuery.disableAnimationsOf(context);
final d = reduceMotion ? Duration.zero : durBase;
```

Wrap it once in an `AppMotion` helper and read from it everywhere. With reduced motion on:
transitions become instant crossfades, the stagger is dropped, the checkbox check appears without
drawing. **Nothing becomes unusable, nothing becomes invisible.**

---

## 6. Screen Revisions

### 6.1 Splash

Mark fades + scales `0.94 → 1.0` over 500ms `easeOutCubic`. Wordmark fades in at +120ms.
No tagline — it adds a second text block to a screen that exists for under two seconds.

**Timing changed from the original plan:** navigate as soon as the auth check resolves, with a
**minimum 1100ms** floor so the animation completes. Not a hard 2000ms wait. Making the user watch
a timer that isn't doing work is exactly the tell we are avoiding.

Safe area respected. No progress indicator — under 1.5s, a spinner reads as slowness.

### 6.2 Login / Signup

- Header block: mark 32px, then `titleLarge` headline, then `body` subtitle. Left-aligned, not
  centred — left-aligned headers read as considered, centred ones as template.
- 26px top padding below safe area, 40px between header and first field, 16px between fields,
  24px before the CTA.
- One primary CTA per screen (`primary-action`). "Sign Up" on Login is a **text button**, visually
  subordinate.
- **Mock auth is deliberately async**: 600ms delay + real loading state on the button. Phase 2's
  Firebase latency then changes nothing about how the screen feels or behaves. This also gives the
  loading state a reason to exist in the Phase 1 demo.
- Failure → inline error above the CTA, not a SnackBar. SnackBars for form errors are a
  `error-placement` violation; the message belongs near the problem.
- `SingleChildScrollView` + `resizeToAvoidBottomInset: true`. CTA stays reachable above the keyboard.

### 6.3 Home

Structure per §4.1 and §4.2. Additional rules:

- `CustomScrollView` with `SliverAnimatedList` per section.
- Bottom content inset **96px** so the last card clears the FAB (`scroll-and-fixed-coexistence`).
- FAB **56×56**, bottom-right, inset 20 right / 26 bottom, clear of the gesture bar.
- Deleting the last task crossfades to the empty state — no hard swap.
- Undo SnackBar: floating, `accent` background, 4s, `Undo` action in `onAccent`. Restores at the
  original index (`undo-support`).
- Android predictive back on Home → exit confirm, never a silent stack reset
  (`back-stack-integrity`).

### 6.4 Add / Edit — presented as a sheet

Changed from a full page to a **draggable bottom sheet** at 92% height, radius 20 on the top
corners, with a 36×4 grab handle. Reasons: it preserves spatial context with the list underneath
(`continuity`), it makes swipe-down-to-dismiss the natural gesture (`modal-escape`), and it makes
the "this is a quick capture, not a destination" intent legible.

```
        ────                          grab handle
 New task                    ✕        titleMedium + 44×44 close
 ─────────────────────────────────
 Title
 [                              ]     autofocus
 Notes
 [                              ]     3 lines, optional
 Priority
 [ High ][ Medium ][ Low ]            segmented, selected = filled accent
 Due
 [ ti-calendar  Add date ]            optional, chip-style
 ─────────────────────────────────
 [        Save task        ]          pinned above keyboard + safe area
```

- Priority is a **segmented control**, not three loose chips — it communicates "pick exactly one".
  Default **Medium**, and Medium renders nothing on the card.
- Date and time are one combined optional chip that expands, not two always-visible empty fields.
  Progressive disclosure (`progressive-disclosure`).
- Save button pinned to the bottom above the keyboard inset, inside `SafeArea`.
- Dismissing with unsaved changes → confirm (`sheet-dismiss-confirm`).
- Edit mode adds a `Delete task` destructive text button at the bottom, visually separated by 24px
  and a divider (`destructive-nav-separation`).
- Date pickers wrapped in a local monochrome `Theme` — the default Material picker will otherwise
  render in blue and break the entire design in one screenshot.

---

## 7. Accessibility Requirements

Non-negotiable, all CRITICAL-tier:

- [ ] Every icon-only control has a `Semantics(label:)` — FAB, close, eye, theme toggle
- [ ] Every touch target ≥44×44, verified with the Flutter inspector
- [ ] All text pairs meet 4.5:1; verified in **both** themes independently
- [ ] `MediaQuery.disableAnimationsOf` respected globally
- [ ] `textScaler` 1.0 → 2.0 without clipping, overflow, or overlap
- [ ] Focus order matches visual order; visible 2px focus ring on every focusable
- [ ] Priority and completion state are conveyed by **text and shape**, never contrast alone
- [ ] Form errors announced to screen readers
- [ ] Safe areas honoured top and bottom on every screen
- [ ] Modal scrim ≥50% so the background never competes

---

## 8. The Anti-Pattern List

Things that would immediately make this look generated. None of them appear in this spec:

1. Emoji as icons — use a single outline icon family throughout
2. Mixed icon stroke weights — 1.75px everywhere, one family
3. Drop shadows on cards — hairline borders only
4. A purple or blue accent sneaking in via an unstyled Material widget
5. Centred body text
6. Default Flutter `AppBar` elevation and its grey shadow
7. Placeholder text used as the label
8. Grey-on-grey secondary text below 4.5:1
9. `Colors.grey[400]` hardcoded anywhere
10. Five font weights
11. A spinner for anything under 300ms
12. Animation durations picked ad hoc instead of from the token set
13. An empty state that only says "No data"
14. Destructive actions with no confirm and no undo
15. A default blue `DatePicker` in a black-and-white app

---

## 9. Ownership Impact

The changes above shift a small amount of work but no ownership:

| Change | Owner | Delta |
|---|---|---|
| Large-title collapsing header | Ahmed | +1 sliver, moderate |
| Card icons → swipe + long-press | Ahmed | net simpler card, `Dismissible` added |
| Add/Edit page → bottom sheet | Ahmed | neutral, same form |
| Async mock auth + loading state | Mostafa | +30 min |
| Inline auth errors instead of SnackBar | Mostafa | neutral |
| `AppMotion` reduced-motion helper | Mostafa (owns routing/motion) | +30 min |
| Theme toggle as 44×44 icon button | Wafaa | simpler than a custom switch |
| Logo asset + app icon | Mostafa (leader/build) | assets provided |
