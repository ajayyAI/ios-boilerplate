# AGENTS.md

A SwiftUI iOS app starter. Cloned once per new app, then renamed via `scripts/rename-project.py`.

## Stack

Swift 6.3.3 · Xcode 26.6 · iOS 18+ · SwiftUI with `@Observable` · Swift Testing + XCUITest · [Factory 3](https://github.com/hmlongco/Factory) for DI · SPM only.

The project sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` alongside `SWIFT_STRICT_CONCURRENCY = complete`. Every type is main-actor isolated unless marked `nonisolated` — which is why domain and data types carry that keyword.

## Verify

```bash
make check
```

Doctor, format check, lint, build, test. Individual steps are `make format`, `make lint`,
`make build`, `make test`, `make deadcode`.

Run it and paste real output. "Tests pass" without a run is a claim, not a result.

## Architecture

Feature-first, with Clean Architecture layers inside each feature. Full layout and rationale: [`docs/architecture.md`](docs/architecture.md).

Product code lives in `Scaffold/Features/<Feature>/`, split into `Presentation/`, `Domain/`, and `Data/`. Add a layer when the responsibility exists, not before.

Dependencies point inward. `Presentation` calls `Domain`; `Data` implements `Domain` protocols; `Domain` imports Foundation and stops there — no SwiftUI, UIKit, Factory, networking, or persistence. Wiring lives in `Scaffold/Core/DI/Container.swift`; everything else uses initializer injection.

**Not every view needs a view model.** A view that renders its inputs takes them directly. Add a `ViewModel` when the screen coordinates async work, transforms domain data into presentation state, validates input, or holds behaviour worth testing.

## SwiftUI

Apple's own guidance is installed as skills and supersedes prior training. Reach for it rather than recalling:

- Writing or reviewing a view, an `@Observable` model, or a `ForEach` → `swiftui-specialist`. Covers invalidation boundaries, environment, bindings, localization, and soft-deprecated APIs.
- A `@State` compile error after an SDK bump, or adding reorder, swipe actions, or toolbar overflow → `swiftui-whats-new-27`.
- An actor-isolation or `Sendable` error, or any `async`/`await` boundary → `swift-concurrency-pro`. This project runs strict concurrency with main-actor default isolation, so these come up often.
- Writing or reviewing tests → `swift-testing-pro`.
- Driving a simulator — screenshots, gestures, accessibility audits → `ios-simulator-skill`.
- Hardening build settings → `audit-xcode-security-settings`.

Restore all six on a fresh clone with `npx skills experimental_install` (pinned in `skills-lock.json`).

Two rules from `swiftui-specialist` that generated code reliably gets wrong:

- Each distinct section of a screen is its own `View` struct taking only the fields it reads. A `private var header: some View` computed property shares the parent's invalidation boundary and buys nothing.
- Types stored on an `@Observable` model conform to `Equatable`, so the generated setter skips redundant invalidations.

## Design system

Views read every colour, spacing, radius and font off `@Environment(\.theme)`. A literal — `.padding(16)`, `.foregroundStyle(.blue)`, `.font(.headline)` — renders identically today and stops following when the theme changes, so it is a defect here, not a style preference. Tokens and the reasoning behind each: [`docs/design-system.md`](docs/design-system.md).

Reach for `.buttonStyle(.primary)` / `.secondary`, `.card()` and `AsyncButton` before writing a new control. Add a token only once a second view needs the same decision.

`Features/Home/Presentation/HomeView.swift` is the reference screen: thin parent, one `View` per section, narrow inputs, tokens throughout.

## Integrations

**Every integration is env-gated.** A client whose key is absent resolves to its no-op
implementation, so a clone with no `Config/Secrets.xcconfig` builds, runs and tests
green and contacts no vendor. `AppEnvironment` is the only place that decision is made
— never branch on a key at a call site.

Adding an integration means: a protocol and a no-op in `Core/`, a branch in
`AppEnvironment`, a key in `AppConfig` **and** `Info.plist` **and**
`Config/Secrets.example.xcconfig`, and a test that the absent key selects the no-op.

Vendor SDKs start in `ScaffoldAppDelegate`, never in an initializer. Constructing
the composition root must stay free of side effects, which is what lets tests build
the real clients without booting anything.

Entitlement reads are fail-closed. A failure shows a retry, never the gated content.
`PaywallGateTests` pins this; if a change makes a failed read grant access, that is a
defect regardless of what else it fixes.

## Testing

Feature tests go in `ScaffoldTests/<Feature>/`, cross-cutting ones in `ScaffoldTests/Sanity/`, XCUITest flows in `ScaffoldUITests/Flows/`.

Every feature earns view model and use case tests before it earns a UI test.

## Git

Conventional Commits. Commit on the current branch; pushing, branching, and remote changes wait for an explicit ask.

## Conventions

Product code, shipped docs, and user-facing strings never name the starter this came from.

Comments carry non-obvious *why* — a platform trap, an invariant, an ordering constraint, a concurrency boundary. Types, names, and tests carry the *what*.
