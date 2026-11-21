# Stark VMS Design

*Locked 2026-11-21 · Direction: **Number Plate***

Every screen reads tokens from this file. Never invent a colour, size, radius or duration.
A new value means this file changed first (through `/feedback`).

## The idea

Stark VMS is a fleet register for Stark Group office staff in Bangladesh. They are
record keepers at a desk; they identify a vehicle by its plate and need to see at a
glance what needs attention (an expiring paper, a vehicle in the workshop).

- **One signature:** the vehicle number is always drawn as a real Bangladeshi number
  plate (`DHAKA METRO-GA` over `11-9001`). This is the only bold element. Everything
  around it stays quiet.
- **Registry feel:** navy frame, light blue-grey workspace, one white surface per page.
  Square, exact, official.
- **Course guideline kept:** left menu, light workspace, blue as the main colour,
  green = active/valid, red = delete/errors only.

## Colour tokens

| Token | Hex | Use |
|---|---|---|
| `navy` | `#0E2240` | Side menu, landing hero, toasts, selected filter chip |
| `navy2` | `#1A3560` | Menu hover and current page |
| `blue` | `#1F5FD1` | Primary buttons, links, focus ring |
| `bluePress` | `#194FB0` | Primary button hover/pressed |
| `tarmac` | `#EEF1F5` | Workspace background (blue-tinted grey, never pure grey) |
| `paper` | `#FFFFFF` | Register surface, form card, panel, plates |
| `ink` | `#142036` | Body text |
| `muted` | `#5A6780` | Secondary text, hints, column headers |
| `line` | `#D8DEE8` | Borders and dividers |
| `rowLine` | `#E8ECF2` | Dividers between rows inside a surface |
| `rowHover` | `#F5F8FD` | Row hover |
| `green` | `#17834F` | Active status, valid papers |
| `amber` | `#A8620E` | Maintenance status, papers within 30 days |
| `red` | `#C2302A` | Delete actions, expired papers, errors. Nothing else |
| `onNavyText` | `#EDF2FA` | Headings on navy |
| `onNavyMuted` | `#B9C7DE` | Body text on navy |

**Status colours are semantic, not decoration.** Active = green, Maintenance = amber,
Inactive = `muted` with a `#9AA6BA` dot. Always pair colour with a word (never colour alone).

**Paper expiry:** valid (> 30 days) green · expiring (0–30 days) amber · expired red.
The bar shows time left measured against one year.

Single light theme by choice (course guideline). No dark mode in Assignment 1 or 2.

## Type

| Role | Face | Settings |
|---|---|---|
| Display (page titles, hero, big figures) | **Archivo** (variable, width axis) | width 112–118, weight 700–800, letter-spacing −0.01em |
| Body and UI | **Public Sans** | 400 / 500 / 600 / 700 |
| Plate only | **Barlow Condensed** | 600 / 700, letter-spacing 0.05em, tabular figures |

Barlow Condensed appears **only inside plates**. No monospace anywhere.

Scale (px): 13 · 14 · 15 (body) · 17 · 19 · 30 (page title) · 36 (section) · 60 (hero, clamps down to 34).
Line height 1.55 body, 1.1 headings. Sentence case everywhere. Numbers that line up use tabular figures.

Fonts are bundled as assets in `frontend/assets/fonts/` (OFL licence, from Google Fonts), not
fetched at runtime and not via the `google_fonts` package.

## Spacing, radius, elevation

- Spacing scale (px): 4 · 6 · 8 · 10 · 12 · 14 · 16 · 18 · 20 · 24 · 28 · 40 · 48 · 72
- Page padding 28 top; content max width 1120 (app) / 1160 (landing); side gutter min 16
- Radius: **4** controls and chips' container · **6** surfaces (register, form card, dialog) · **999** filter chips only · plates 3 (8 for the hero plate)
- Shadows only on things that float: detail panel, dialog, toast. Surfaces use a 1px `line` border, never a shadow.

## Motion

| Token | Value | Use |
|---|---|---|
| `fast` | 140 ms | Hover, press, colour changes |
| `base` | 220 ms | Page enter, panel slide, dialog pop |
| `ease` | `Cubic(0.2, 0.7, 0.2, 1)` | Everything |

- **Page enter:** fade + 6px rise, `base`.
- **Detail panel:** slides in from the right 40px + fade, `base`; scrim fades.
- **Dialog:** scale 0.97 → 1 + fade.
- **Toast:** rises 10px + fade, stays 3.2s, bottom-right.
- **New/edited row:** background flashes `#E3ECFC` and fades out over 1.8s.
- **Removed row:** slides 16px right + fades, 260ms, then the list closes up.
- **Hero plate:** flips (rotateX) to the next fleet vehicle every 3.2s. The only ambient motion in the product.
- **Reduce motion:** when the OS asks for it (`MediaQuery.disableAnimations`), all durations become 0 and the hero plate stops cycling.

No scroll-triggered reveals, no staggered card entrances, no parallax.

## Interaction rules

1. **Intuitive without a manual.** Every page has one title and one obvious primary action.
   Buttons say what happens ("Register vehicle", "Save changes", "Remove vehicle"), and the
   toast repeats the same verb ("Registered DHAKA METRO-GA 11-9001").
2. **Content loading → skeletons.** Lists and panels show shimmering placeholder rows shaped like the real rows. Never a centred spinner on a blank page.
3. **Button actions → inline spinner.** The button locks, shows a spinner and a verb ("Registering"), and can't be pressed twice. Form input survives a failed save.
4. **Errors sit next to their field**, in plain words that say how to fix it. Duplicate plate (409) shows under the number field with a link to the existing vehicle. Wrong sign-in shows one message above the form, without saying which field was wrong.
5. **Destructive actions confirm** in a dialog showing the plate. Buttons: "Keep vehicle" (focused by default) and "Remove vehicle" (red).
6. **Empty states invite action:** "No vehicles yet. Register the first vehicle…" with the button. A search with no matches offers "Clear search and filter".
7. **Everything clickable has hover, pressed and keyboard-focus states.** Focus ring: 2px `blue`, 2px offset. Rows open on click, Enter or Space. Escape closes panels and dialogs.
8. **Every page has a URL** (`/`, `/login`, `/dashboard`, `/vehicles`, `/vehicles/new`, `/vehicles/:id/edit`); the detail panel opens over the list. Signed-out visitors to an app URL go to sign-in, then back to where they were going.
9. **Lists are paged with visible page numbers, not infinite scroll.** The page lives in the URL (`/vehicles?page=2`), so refresh and Back keep your place. Changing page shows skeleton rows shaped like the register and scrolls to the top of the list; the page count and "Showing x–y of z" come from the same server response, so they always agree. Changing a filter or search returns to page 1.
10. **Live plate preview** on the register/edit form updates as you type; the number field auto-inserts the dash.

## Components

| Component | Spec |
|---|---|
| Plate (sm) | white, 1.5px `#1B1B1B` border, radius 3, top line 10px/600, number 19px/700, min width 104 |
| Plate (lg) | 2px border, top 13px, number 32px. Used in panel, dialog, form preview |
| Plate (xl) | 4px border, radius 8, double inner rule, number 54–96px. Landing and sign-in only |
| Side menu | 232px, `navy`; current page `navy2` + 3px inset left bar `#6E9BEF`; becomes a top bar under 820px |
| Register (list) | one `paper` surface, header row `#F8F9FB`, columns: plate · vehicle · driver · papers · status · actions; stacks under 960px |
| Pagination | under the register, inside the page width: left "Showing 11–20 of 21 vehicles" (`muted`, tabular figures); right "‹ Previous", page numbers, "Next ›" as quiet buttons, current page `navy` fill with white text and `aria-current="page"`. Long ranges collapse to `1 … 4 [5] 6 … 12`. Previous/Next disabled (not hidden) at the ends. Hidden when there is only one page. Phone width: just "‹ Previous · Page 2 of 3 · Next ›" |
| Filter chip | pill, `paper` with `line` border; selected = `navy` fill, white text; shows count |
| Status | coloured dot + word, no pill background |
| Figures (dashboard) | one surface split by 1px lines; Archivo 34px numbers; no icons |
| Detail panel | 460px right sheet; plate + status, facts grid, papers; footer: Remove (quiet, red text) + Edit vehicle |
| Waking notice | Toast styling (`navy`, radius 4, bottom-right, floating shadow, rises 10px + fade `base`) but stays until the server answers. Shows after a request has waited 3s: `Spinner` + "Waking up the server…" (14/600 `onNavyText`) over one `onNavyMuted` 13px line. No answer: "Can't reach the server." + **Try again** (outline on navy). Above every page |

## Copy

- Talk about the job, not the system: "papers", "in the workshop", "register a vehicle".
- Plate is written `CITY METRO-CLASS NN-NNNN` in messages.
- Errors don't apologise and aren't vague: "Enter the number as two digits, a dash, then four digits, like 11-9001."

## This design will NOT

- Use gradients, glass, or decorative illustrations
- Use all-caps labels, `A · B · C` meta strings, monospace labels, or `→` on buttons
- Put content in identical rounded cards with soft shadows, or icon-in-a-circle stat tiles
- Use red for anything except delete, expired and errors
- Animate things the user didn't trigger (except the hero plate)

## Flutter tokens

The kit stays `shadcn_ui`. Tokens live in `frontend/lib/theme/stark_tokens.dart` and feed
`ShadThemeData`. Verify the `ShadColorScheme` constructor against shadcn_ui 0.59 when this
file is first created (Phase 4).

```dart
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

abstract final class StarkColors {
  static const navy = Color(0xFF0E2240);
  static const navy2 = Color(0xFF1A3560);
  static const blue = Color(0xFF1F5FD1);
  static const bluePress = Color(0xFF194FB0);
  static const tarmac = Color(0xFFEEF1F5);
  static const paper = Color(0xFFFFFFFF);
  static const ink = Color(0xFF142036);
  static const muted = Color(0xFF5A6780);
  static const line = Color(0xFFD8DEE8);
  static const rowLine = Color(0xFFE8ECF2);
  static const rowHover = Color(0xFFF5F8FD);
  static const freshRow = Color(0xFFE3ECFC);
  static const green = Color(0xFF17834F);
  static const amber = Color(0xFFA8620E);
  static const red = Color(0xFFC2302A);
  static const inactiveDot = Color(0xFF9AA6BA);
  static const onNavyText = Color(0xFFEDF2FA);
  static const onNavyMuted = Color(0xFFB9C7DE);
  static const plateInk = Color(0xFF1B1B1B);
}

abstract final class StarkFonts {
  static const display = 'Archivo';       // use FontVariation('wdth', 112..118)
  static const body = 'PublicSans';
  static const plate = 'BarlowCondensed'; // plates only
}

abstract final class StarkRadius {
  static const control = 4.0;
  static const surface = 6.0;
  static const plate = 3.0;
  static const plateXl = 8.0;
  static const chip = 999.0;
}

abstract final class StarkMotion {
  static const fast = Duration(milliseconds: 140);
  static const base = Duration(milliseconds: 220);
  static const rowLeave = Duration(milliseconds: 260);
  static const freshFade = Duration(milliseconds: 1800);
  static const toast = Duration(milliseconds: 3200);
  static const heroCycle = Duration(milliseconds: 3200);
  static const ease = Cubic(0.2, 0.7, 0.2, 1);
}

// ShadThemeData mapping (main.dart):
// ShadColorScheme(
//   background: StarkColors.tarmac,   foreground: StarkColors.ink,
//   card: StarkColors.paper,          cardForeground: StarkColors.ink,
//   popover: StarkColors.paper,       popoverForeground: StarkColors.ink,
//   primary: StarkColors.blue,        primaryForeground: StarkColors.paper,
//   secondary: StarkColors.paper,     secondaryForeground: StarkColors.ink,
//   muted: StarkColors.tarmac,        mutedForeground: StarkColors.muted,
//   accent: StarkColors.rowHover,     accentForeground: StarkColors.ink,
//   destructive: StarkColors.red,     destructiveForeground: StarkColors.paper,
//   border: StarkColors.line,         input: Color(0xFFC5CEDC),
//   ring: StarkColors.blue,           selection: Color(0x331F5FD1),
// )
// radius: BorderRadius.circular(StarkRadius.control)
```
