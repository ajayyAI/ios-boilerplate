# iOS App Starter

A production-ready SwiftUI iOS app foundation. Clean Architecture, Factory DI, XCUITest, GitHub Actions → TestFlight.

This repo is a **reusable app starter** — clone it for each new iOS app, rename via the script, push to a fresh GitHub repo.

## Requirements

- Xcode 26+
- iOS 17.6+ deployment target
- macOS 14+ for development

## Starting a new app from this project

```bash
# 1. Clone into a folder named after your new app
git clone <your-repo-url> MyApp
cd MyApp

# 2. Wipe this repo's git history, start fresh
rm -rf .git
git init -b main

# 3. Rename TemplateApp -> MyApp everywhere (folders, files, identifiers)
python3 ./scripts/rename-project.py
# (enter MyApp at the prompt)
rm ./scripts/rename-project.py

# 4. First commit on your new repo
git add -A && git commit -m "chore: initial app scaffold"

# 5. Create a new GitHub repo and push
gh repo create MyApp --private --source . --remote origin --push
```

Then in Xcode:

1. **Set your bundle ID.** Target → Signing & Capabilities. Bundle IDs currently use `com.example.*` — replace `example` with your reverse-DNS (e.g. `com.yourname.MyApp`).
2. **Set your Apple Developer Team.** Same screen.
3. **Replace the app icon.** `MyApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png` is a placeholder.
4. **Open + build:** `open MyApp.xcodeproj` → `Cmd+R` to run, `Cmd+U` to test.

## Architecture

Feature-first SwiftUI architecture with Clean Architecture boundaries inside each feature:

- **Features** — product areas grouped by feature, with `Presentation`, `Domain`, and `Data` subfolders as needed
- **App** — app entry point, app delegate, root navigation, and bootstrapping
- **Core** — cross-cutting infrastructure such as dependency injection, device helpers, and shared errors
- **Shared** — reusable UI components and view modifiers that are not owned by one feature

Dependency injection via [Factory 3](https://github.com/hmlongco/Factory). All registrations live in `TemplateApp/Core/DI/Container.swift`.

```
TemplateApp/
├── App/                       App entry, app delegate, root view
├── Core/
│   ├── DI/                    Dependency registrations
│   ├── Device/                Device/app environment helpers
│   └── Errors/                Shared error types
├── Features/
│   ├── Home/
│   │   └── Presentation/      SwiftUI views and view models
│   └── User/
│       ├── Domain/            Models, protocols, use cases
│       └── Data/              Repositories and data sources
├── Shared/
│   └── UI/                    Reusable UI components and modifiers
└── Assets.xcassets            Images, colors, app icon
```

## Code style

- 4-space indentation
- `async`/`await` over Combine
- `@Observable` over `ObservableObject` where possible
- Lean into Apple platform conventions; don't fight them

Lint + format:

```bash
brew install swiftlint swiftformat
swiftlint . --fix
swiftformat .
```

## Testing

- **Unit tests** — `TemplateAppTests/` — business logic, view models, use cases
- **UI tests** — `TemplateAppUITests/` — XCUITest

```bash
xcodebuild test \
  -project TemplateApp.xcodeproj \
  -scheme TemplateApp \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'
```

## CI/CD

GitHub Actions workflows in `.github/workflows/`:

| Workflow | When | What |
|---|---|---|
| `test.yml` | every PR | runs tests |
| `build.yml` | push to `release/**` | archives + uploads to TestFlight |

To enable TestFlight uploads, set these GitHub Actions secrets:

| Secret | Purpose |
|--------|---------|
| `BUILD_CERTIFICATE_BASE64` | base64 of `.p12` certificate bundle (dev + distribution) |
| `P12_PASSWORD` | password for the `.p12` bundle |
| `APP_STORE_CONNECT_API_KEY_BASE64` | base64 of `.p8` App Store Connect API key |
| `APP_STORE_CONNECT_API_KEY_ID` | API key ID |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | API key issuer ID |

Encode a file to base64: `base64 -i Certificates.p12 | pbcopy`.

## Release process

1. Bump the version in Xcode → target → General. Commit on `main`.
2. Branch `release/<version>` and push. GitHub Actions builds and uploads to TestFlight.
3. Draft a GitHub release with tag `<version>` targeting the release branch.
4. Submit the TestFlight build to the App Store via App Store Connect.
5. Publish the GitHub release and merge `release/<version>` back to `main`.

[SemVer](https://semver.org/): MAJOR for breaking UX, MINOR for features, PATCH for fixes.
