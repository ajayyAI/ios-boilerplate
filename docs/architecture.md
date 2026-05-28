# Architecture

This project uses a feature-first SwiftUI architecture with Clean Architecture boundaries inside each feature. The goal is to keep new apps understandable for humans and predictable for AI agents.

## Top-Level Layout

```text
TemplateApp/
├── App/
├── Core/
│   ├── DI/
│   ├── Device/
│   └── Errors/
├── Features/
│   ├── Home/
│   │   └── Presentation/
│   └── User/
│       ├── Domain/
│       └── Data/
├── Shared/
│   └── UI/
├── Assets.xcassets
├── Info.plist
└── Localizable.xcstrings
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
- Use `@Observable` for observable view models.
- Mark UI-facing view models `@MainActor`.
- Prefer `NavigationStack` over `NavigationView`.
- Keep UIKit out of SwiftUI views unless a platform integration requires it.
- Prefer small focused views over large screens with unrelated logic.
- Keep reusable UI in `Shared/UI` only after it is used by more than one feature or is clearly generic.

## Testing Layout

```text
TemplateAppTests/
├── Home/
├── User/
└── Sanity/

TemplateAppUITests/
└── Flows/
```

Use unit tests for view models, use cases, repositories, mapping, and error handling. Use XCUITest or Maestro for user journeys. Do not use end-to-end tests as a replacement for domain and view model tests.

## Adding A New Feature

1. Create `TemplateApp/Features/<FeatureName>/`.
2. Add `Presentation/`, `Domain/`, and `Data/` only as needed.
3. Define protocols and use cases in `Domain/`.
4. Implement concrete data access in `Data/`.
5. Register concrete dependencies in `Core/DI/Container.swift`.
6. Add tests under `TemplateAppTests/<FeatureName>/`.
