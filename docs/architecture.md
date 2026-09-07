# Architecture

This project uses a feature-first SwiftUI architecture with Clean Architecture boundaries inside each feature. The goal is to keep new apps understandable for humans and predictable for AI agents.

## Top-Level Layout

```text
Scaffold/
├── App/                    entry point, app delegate, root view
├── Core/
│   ├── Analytics/
│   ├── Configuration/      AppConfig, read from xcconfig via Info.plist
│   ├── CrashReporting/
│   ├── DI/                 the Factory container
│   ├── Device/
│   ├── Errors/
│   ├── Networking/         HTTPClient
│   ├── Purchases/
│   └── Storage/            KeyValueStore, UserDefaults and Keychain backed
├── Features/
│   ├── Home/
│   │   └── Presentation/
│   ├── Paywall/
│   │   └── Presentation/
│   └── User/
│       ├── Data/
│       └── Domain/
├── Shared/
│   ├── Errors/
│   └── UI/
│       ├── Components/     AsyncButton
│       ├── DesignSystem/   Theme, button styles, card
│       └── ViewModifiers/
├── Assets.xcassets
├── Info.plist
├── Localizable.xcstrings
└── PrivacyInfo.xcprivacy
```

## Folder Responsibilities

`App/` contains the app entry point, app delegate, root view, and app-level navigation shell.

`Core/` contains infrastructure that is used across features but is not product UI: dependency injection, device/environment helpers, shared errors, logging, analytics, and other platform services.

`Features/` contains product behavior. Add a new folder for each meaningful product area, for example `Authentication`, `Profile`, `Settings`, or `Orders`.

`Shared/` contains reusable UI and utilities that are genuinely shared across multiple features. Do not put feature-specific views here.

## Feature Structure

Use these folders inside a feature when they are needed:

```text
Features/Example/
├── Presentation/
├── Domain/
└── Data/
```

`Presentation/` contains SwiftUI views, view models, view state, view-specific formatters, and screen-level components.

`Domain/` contains plain Swift models, protocols, use cases, validation, and business rules. Domain code should be portable and easy to unit test.

`Data/` contains concrete repositories, API clients, persistence, entities, DTOs, and mapping between data and domain models.

Small features do not need all three folders on day one. Add folders when the responsibility exists.

### A feature is a bounded context, not a screen

`Features/User/` has `Domain/` and `Data/` but no `Presentation/`, while `Features/Home/`
has only `Presentation/`. That asymmetry is deliberate and worth stating, because it
looks like a mistake.

A feature folder names a *bounded context* — a slice of the product's meaning. User
identity is one; it currently has no screen of its own and is consumed by Home. Home is
another; it renders and owns no persistence. Both are legitimate. A feature earns each
folder independently.

The rule this replaces — "a feature is a screen" — would force `User` to be merged into
`Home`, coupling user identity to whichever screen happened to need it first.

### When a layer earns its place

Layers cost indirection, so each one is added when it holds something, not by default.
The current `GetUserUseCase` is a single forwarding call; it exists to demonstrate the
shape. Copying that shape into a screen with no logic is the failure mode to avoid.

| Layer | Add it when | Skip it when |
|---|---|---|
| View model | The screen coordinates async work, transforms domain data into presentation state, validates input, or holds behaviour worth testing | The view renders the inputs it is handed |
| Use case | Real business logic lives there — orchestration across repositories, validation, policy | It would only forward one call to one repository; the view model calls the repository |
| Repository | There is more than one source, or you want a test seam | Never — this is the seam that makes the rest testable |
| Entity + mapping | The wire or storage shape differs from the domain shape | The two are field-for-field identical |

### State types are Equatable

The `@Observable` macro generates a setter that skips invalidating observing views when
the new value equals the current one — but only when it can compare them. A view state
that is not `Equatable` re-renders on every assignment, including redundant ones.

`HomeViewState` conforms, which is why it carries `PresentableError` rather than `Error`:
`Error` has no `Equatable` conformance, so holding one directly would forfeit the skip.
Flattening a domain error to what the UI renders is the view model's job regardless.

### Sections are separate View types

Each distinct region of a screen is its own `View` struct taking only the fields it reads,
never a `private var header: some View` computed property. A computed property is inlined
into the parent's body and shares its invalidation boundary, so it reduces nothing. See
the `swiftui-specialist` skill's `structure.md` for the full reasoning.

## Dependency Direction

Dependencies should point inward:

```text
Presentation -> Domain <- Data
Core/DI wires concrete implementations together.
```

Rules:

- Domain defines protocols; Data implements them.
- Presentation calls use cases or domain services.
- Core/DI creates concrete objects and connects dependencies.
- Domain must not import SwiftUI, UIKit, Factory, networking, database frameworks, or concrete data sources.
- Prefer initializer injection for types with dependencies.

## SwiftUI 2026 Standards

- Use Swift 6-era concurrency and `async`/`await`.
- The project sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; types are main-actor
  isolated unless marked `nonisolated`.
- Use `@Observable` for observable view models.
- Mark UI-facing view models `@MainActor`.
- Prefer `NavigationStack` over `NavigationView`.
- Keep UIKit out of SwiftUI views unless a platform integration requires it.
- Prefer small focused views over large screens with unrelated logic.
- Keep reusable UI in `Shared/UI` only after it is used by more than one feature or is clearly generic.

## Testing Layout

```text
ScaffoldTests/
├── Home/
├── User/
└── Sanity/

ScaffoldUITests/
└── Flows/
```

Use unit tests for view models, use cases, repositories, mapping, and error handling. Use XCUITest or Maestro for user journeys. Do not use end-to-end tests as a replacement for domain and view model tests.

## Adding A New Feature

1. Create `Scaffold/Features/<FeatureName>/`.
2. Add `Presentation/`, `Domain/`, and `Data/` only as needed.
3. Define protocols and use cases in `Domain/`.
4. Implement concrete data access in `Data/`.
5. Register concrete dependencies in `Core/DI/Container.swift`.
6. Add tests under `ScaffoldTests/<FeatureName>/`.
