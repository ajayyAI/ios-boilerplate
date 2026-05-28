# Agent Instructions

This repository is a SwiftUI iOS app foundation. Keep changes aligned with the feature-first architecture documented in `docs/architecture.md`.

## Architecture Rules

- Put product code under `TemplateApp/Features/<FeatureName>/`.
- Split feature code by responsibility:
  - `Presentation/` for SwiftUI views, view models, view state, screen-specific UI.
  - `Domain/` for models, protocols, use cases, and business rules.
  - `Data/` for repositories, DTOs/entities, API clients, persistence, and mapping.
- Put app bootstrap code under `TemplateApp/App/`.
- Put cross-cutting infrastructure under `TemplateApp/Core/`.
- Put reusable UI that is not owned by one feature under `TemplateApp/Shared/UI/`.
- Do not recreate old layer-first folders such as `Views/`, `Domain/`, `Data/`, `UIComponents/`, or `ViewModifiers/` at the app root.

## Dependency Direction

- `Presentation` may depend on `Domain`.
- `Data` may implement `Domain` protocols.
- `Domain` must not depend on SwiftUI, Factory, UIKit, networking clients, persistence frameworks, or concrete data sources.
- Dependency injection registrations belong in `TemplateApp/Core/DI/Container.swift`.
- Prefer initializer injection for domain and data types. Avoid `@Injected` outside composition code unless there is a clear reason.

## SwiftUI Standards

- Prefer SwiftUI-native APIs and `NavigationStack`.
- Prefer `@Observable` for observable view models.
- Mark UI-facing view models `@MainActor`.
- Prefer `final class` for reference types that are not designed for inheritance.
- Use `async`/`await` over Combine for new asynchronous work.
- Keep files small and focused; one main type per Swift file.

## Testing Rules

- Place unit tests under `TemplateAppTests/<FeatureName>/` when they test a feature.
- Place cross-cutting or smoke tests under `TemplateAppTests/Sanity/`.
- Place XCUITest flows under `TemplateAppUITests/Flows/`.
- For every new feature, add at least view model/use case tests before relying on UI tests.

## Before Finishing

Run the narrowest useful verification command. For architecture or folder changes, run:

```bash
xcodebuild test -project TemplateApp.xcodeproj -scheme TemplateApp -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'
```
