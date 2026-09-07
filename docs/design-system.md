# Design System

Every visual decision lives in one value, `Theme`, in
[`Scaffold/Shared/UI/DesignSystem/Theme.swift`](../Scaffold/Shared/UI/DesignSystem/Theme.swift).
Views read tokens off `\.theme`; nothing else in the app names a colour, a corner radius or
a point value. This is the same contract as a CSS variable block — change the values in one
place and every screen follows.

## Rebranding

Three steps, and only the first is required.

```swift
// 1. Define your theme. A `static let`, not a computed property — see "Why static let".
extension Theme {
    static let acme = Theme(
        color: ColorTokens(
            accent: Color(light: .init(red: 0.85, green: 0.25, blue: 0.10), dark: …),
            …
        ),
        spacing: .init(xs: 4, sm: 8, md: 16, lg: 24, xl: 32),
        radius: .init(sm: 4, md: 6, lg: 10),   // squarer corners, whole app
        font: .init(screenTitle: .system(.largeTitle, design: .serif, weight: .black), …)
    )
}
```

```swift
// 2. Point the root at it. `RootView` is the only injection site.
.environment(\.theme, .acme)
```

```swift
// 3. Optional: a second theme for a preview, a demo mode, or a per-tenant build.
#Preview("Acme") { RootView().environment(\.theme, .acme) }
```

To start from the shipped values instead of writing a whole theme, copy `Theme.scaffold`
and edit the lines you care about.

## The tokens

| Group | Tokens | Notes |
|---|---|---|
| `color` | `accent`, `onAccent`, `background`, `surface`, `border`, `textPrimary`, `textSecondary`, `danger` | Every one is an adaptive light/dark pair |
| `spacing` | `xs` 4, `sm` 8, `md` 16, `lg` 24, `xl` 32 | A 4pt scale |
| `radius` | `sm` 8, `md` 12, `lg` 20 | Controls, buttons, cards |
| `font` | `screenTitle`, `sectionTitle`, `body`, `label`, `caption` | All built from system text styles |

Tokens are named by **role**, not by appearance. `surface` rather than `white`, because in
dark mode it is not white. `onAccent` is a token rather than a hardcoded `.white` for the
same reason: an accent light enough to read against a dark background is too light to carry
white text.

## Components

| API | What it is |
|---|---|
| `.buttonStyle(.primary)` | Filled. At most one per screen — it is the thing you want tapped |
| `.buttonStyle(.secondary)` | Outlined. Real choices that are not *the* choice |
| `.card()` | Lifts content onto a surface: padding, radius, hairline border, shallow shadow |
| `AsyncButton` | A `Button` whose action is `async`; disables itself and shows a spinner after 150ms |

Both button styles carry press feedback that respects Reduce Motion, and dim when disabled.

## Rules

**Never hardcode a value a token covers.** `.padding(16)` and `.padding(theme.spacing.md)`
render identically today; only one of them follows when the theme changes.

**Add a token when a second view needs the same decision.** A token used once is a
hardcoded value with extra steps.

**Build fonts from text styles, never `.system(size:)`.** A fixed point size does not scale
with Dynamic Type, which is the usual way a design system quietly breaks accessibility.

**Check the contrast of every pair you add.** `onAccent` against `accent`, `textSecondary`
against `surface`. Aim for 4.5:1 on body text.

## Why `static let`

SwiftUI compares environment values to decide what to re-render, and two separately
constructed adaptive `Color`s never compare equal. A theme built inline in a body —
`.environment(\.theme, Theme(…))` — is a new value on every evaluation, so every view that
reads the theme invalidates on every pass. Bind a stored `static let` instead.

The same applies to the environment default: `@Entry var theme: Theme = .scaffold` re-runs
that expression on each fallback read, which is cheap and stable only because `.scaffold`
is a stored constant.

## Where the pieces live

```text
Scaffold/Shared/UI/
├── DesignSystem/
│   ├── Theme.swift          the tokens, the default theme, the environment key
│   ├── ButtonStyles.swift   .primary / .secondary and their press feedback
│   └── Card.swift           .card()
├── Components/
│   └── AsyncButton.swift
└── ViewModifiers/
    └── ErrorAlert.swift
```

`Features/Home/Presentation/HomeView.swift` is the reference for using them: a thin parent
that composes sections, each section its own `View` with narrow inputs, every value read off
the theme.
