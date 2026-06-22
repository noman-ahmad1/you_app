# You — Color Scheme

The single source of truth for color in the app is [`lib/ui/common/app_colors.dart`](../lib/ui/common/app_colors.dart).
Use the `AppColors` constants everywhere — avoid inline `Color(0x...)` literals so the
palette stays consistent and themeable.

The overall design language is a calm, muted mental-wellness aesthetic: a sage/slate
**primary**, a deep mauve **secondary**, soft frosted-white surfaces, and a set of warm
accent hues reserved for illustrations, mood/streak cards, and category tags.

---

## Brand — Primary (sage / slate blue)

Used for backgrounds, primary buttons, app bars, and the main gradient washes.

| Token | Hex | Preview | Usage |
|---|---|---|---|
| `primary` | `#A7BABE` | ▰ muted sage | Default brand color, buttons, app bar |
| `primaryLight` | `#CBD2D3` | ▰ pale sage | Gradient tops, disabled/soft fills |
| `primaryDark` | `#8199A4` | ▰ slate blue | Pressed states, emphasis |
| `primaryVeryDark` | `#4B575F` | ▰ charcoal slate | High-contrast text on light, icons |

## Brand — Secondary (mauve / wine)

Used for accents, secondary CTAs, the volunteer flow, and labelled-button gradients
(`secondary → secondaryLight`).

| Token | Hex | Preview | Usage |
|---|---|---|---|
| `secondary` | `#6D3D4C` | ▰ deep mauve | Secondary CTAs, accents, headings |
| `secondaryLight` | `#A14E67` | ▰ rosy wine | Gradient ends, hover/active |
| `secondaryVeryLight` | `#CDBABE` | ▰ dusty pink | Soft backgrounds, chips |
| `peachDark` | `#7C5C69` | ▰ muted plum | Secondary-family detail tone |

## Surfaces & Backgrounds

| Token | Hex | Preview | Usage |
|---|---|---|---|
| `background` | `#F0F0F0` | ▰ light grey | Default scaffold background |
| `surface` | `#FBF8F5` | ▰ frosted white | Cards, notification banners, drawers |
| `backgroundGradient` | `#CDBABE` | ▰ dusty pink | Gradient wash (pairs with `primary`) |
| `darkBackground` | `#121212` | ▰ near-black | Dark surfaces / dark mode base |

## Text

| Token | Hex | Preview | Usage |
|---|---|---|---|
| `textPrimary` | `black87` | ▰ near-black | Primary body & headings |
| `textSecondary` | `black54` | ▰ grey | Captions, hints, metadata |

## Status & Feedback

| Token | Hex | Preview | Usage |
|---|---|---|---|
| `error` | `#B00020` | ▰ crimson | Validation errors, destructive |
| `red` | `#D34641` | ▰ soft red | Alerts, delete, warnings |
| `green` | `#4C6D3D` | ▰ forest green | Success, confirmations |

## Accent Palette (illustrations, mood & streak cards, category tags)

Warm, saturated hues used sparingly for emotional/visual variety — never for core
navigation chrome.

| Token | Hex | Preview | Usage |
|---|---|---|---|
| `teal` | `#87BED3` | ▰ sky teal | Accents, charts, tags |
| `lightPurple` | `#C2D6EF` | ▰ periwinkle | Soft accent backgrounds |
| `pink` | `#E374AD` | ▰ bright pink | Highlights, mood accents |
| `lightPink` | `#E3C9D3` | ▰ blush | Soft fills, chips |
| `peach` | `#D0919E` | ▰ dusty peach | Mood / category accents |
| `darkYellow` | `#F8BC16` | ▰ amber | Streaks, badges, highlights |
| `yellow` | `#FFE78D` | ▰ pale yellow | Soft highlight fills |
| `camel` | `#E69454` | ▰ warm tan | Accents, illustrations |
| `darkOrange` | `#ED6937` | ▰ orange | Energetic accents, alerts |

---

## Common gradients

- **Primary wash:** `primaryLight (#CBD2D3) → primary (#A7BABE)` — main screen backgrounds.
- **Secondary button:** `secondary (#6D3D4C) → secondaryLight (#A14E67)` — filled pill CTAs
  (e.g. volunteer info "Next" / "Submit Application").
- **Frosted card:** `surface (#FBF8F5)` over a faint `backgroundGradient (#CDBABE)` tint with
  soft shadows and ~22 rounded corners.

## Conventions

- Reference colors via `AppColors.<token>` — do not hardcode hex values in widgets.
- Pick from the **brand** ramps for chrome (nav, buttons, app bars); reserve the **accent
  palette** for mood/streak/category visuals and illustrations.
- Use `error` for validation/destructive intent and `green` for success confirmations.
- A handful of one-off inline hexes still exist in legacy widgets (e.g. `#A5C4A3`,
  `#9CA3C8`, `#7B7890`, `#6FCF77`, `#F6E7B0`, `#EDAD98`). Prefer migrating these into
  `AppColors` rather than introducing new literals.
