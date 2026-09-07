<div align="center">

<img src="Scaffold/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="104" alt="App icon" />

# iOS App Starter

**A production SwiftUI starter. Clone it per app, rename, ship.**

Subscriptions, analytics and crash reporting wired but dormant — a clone with no keys
still builds, runs and tests green, and contacts nobody.

<br/>

[![CI](https://github.com/ajayyAI/ios-boilerplate/actions/workflows/ci.yml/badge.svg)](https://github.com/ajayyAI/ios-boilerplate/actions/workflows/ci.yml)
[![Swift 6.3](https://img.shields.io/badge/Swift-6.3-fa7343?logo=swift&logoColor=white)](https://swift.org)
[![iOS 18+](https://img.shields.io/badge/iOS-18%2B-000000?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Xcode 26.6](https://img.shields.io/badge/Xcode-26.6-1575F9?logo=xcode&logoColor=white)](https://developer.apple.com/xcode/)
[![Strict Concurrency](https://img.shields.io/badge/concurrency-strict-6E4AFF)](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/)
[![Swift Testing](https://img.shields.io/badge/tests-Swift%20Testing-3fb950)](#-testing)
[![MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

</div>

---

## 🚀 Start a new app

```bash
git clone <this-repo> MyApp && cd MyApp
rm -rf .git && git init -b main

python3 ./scripts/rename-project.py   # enter MyApp
rm ./scripts/rename-project.py

brew bundle          # SwiftLint, SwiftFormat, xcbeautify, Periphery, lefthook
lefthook install     # git hooks
make check           # must pass before you write any code

git add -A && git commit -m "chore: initial scaffold"
gh repo create MyApp --private --source . --remote origin --push
```

Then set `APP_BUNDLE_ID` in `Config/Shared.xcconfig` — it still says `com.example.MyApp`.
Replace the placeholder icon at `MyApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png`.

## ⚡ What you get

|  | |
|---|---|
| 🧪 **One gate** | `make check` — doctor, format, lint, build, test. CI runs the identical target. |
| 🔒 **Fail-closed paywall** | RevenueCat gate that never gives the product away on a network error. |
| 🔌 **Env-gated SDKs** | No keys? Every integration no-ops. Clone-to-green with zero accounts. |
| 🪝 **Hooks that hold** | Format + lint staged Swift, Conventional Commits, tests before push. |
| 🧵 **Swift 6 strict** | Main-actor default isolation, warnings as errors, zero suppressions. |
| 🤖 **Agent-ready** | Six pinned skills including Apple's own SwiftUI guidance from Xcode 27. |

## 🛠 Development

```bash
make check     # doctor → format-check → lint → build → test
```

That is the gate, and CI runs the identical target. Individual steps: `make format`,
`make lint`, `make build`, `make test`, `make deadcode`. `make help` lists them.

Hooks: pre-commit formats and lints staged Swift, commit-msg enforces Conventional
Commits, pre-push blocks `main` and runs tests. Override the branch check with
`SKIP_BRANCH_PROTECTION=1`.

> [!IMPORTANT]
> The pre-push branch check is a convenience, not a control — `--no-verify` bypasses
> it, and lefthook skips it when local has diverged from the remote. Protect `main`
> with a server-side ruleset:
> ```bash
> gh api -X POST repos/:owner/:repo/rulesets --input .github/main-ruleset.json
> ```

`make deadcode` (Periphery) is deliberately outside `check` — it rebuilds and
re-indexes, and a starter's shared surface is unused by design. Run it once you have
real features.

## ⚙️ Configuration

iOS has no runtime environment, so there is no `.env`. Configuration is baked in at
build time through `Config/*.xcconfig` and read back by `AppConfig`.

```bash
cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig
```

**Every integration key is optional.** An absent key selects the no-op client, so a
fresh clone builds, runs and tests green with no vendor accounts and contacts nobody.
`AppEnvironmentTests` enforces that; keep it true when you add an integration.

> [!WARNING]
> An xcconfig is **not** a secret store. Anything baked into the binary is recoverable
> with `strings` ([OWASP MASWE-0005](https://mas.owasp.org/MASWE/MASVS-AUTH/MASWE-0005/)).
> Keys that authorize real spend belong behind your own backend. See
> [`docs/configuration.md`](docs/configuration.md), which also covers the two xcconfig
> traps that will otherwise bite you.

## 🏛 Architecture

Feature-first, with Clean Architecture layers inside a feature. Full rules:
[`docs/architecture.md`](docs/architecture.md).

```
Scaffold/
├── App/          entry point, app delegate, root view
├── Core/         DI, configuration, networking, analytics, crash reporting, purchases, storage
├── Features/     product areas — Presentation / Domain / Data as needed
└── Shared/       design system, reusable UI, errors
```

There is no `src/`. `Scaffold/` is the source root, and the folder name is tied to
the target by Xcode's file-system-synchronized groups.

Add a layer when it holds something. `GetUserUseCase` is a demonstration shape, not a
template to copy into a screen with no logic — see the table in `docs/architecture.md`.

## 🎨 Design system

Every visual decision is a token in one file,
[`Shared/UI/DesignSystem/Theme.swift`](Scaffold/Shared/UI/DesignSystem/Theme.swift). Views
read them off `\.theme`; nothing else in the app names a colour or a point value. Same
contract as a CSS variable block — swap the values, every screen follows.

```swift
RootView()
    .environment(\.theme, .acme)   // the whole app rebrands
```

| Group | Tokens |
|---|---|
| `color` | `accent` `onAccent` `background` `surface` `border` `textPrimary` `textSecondary` `danger` — each an adaptive light/dark pair |
| `spacing` | `xs` 4 · `sm` 8 · `md` 16 · `lg` 24 · `xl` 32 |
| `radius` | `sm` 8 · `md` 12 · `lg` 20 |
| `font` | `screenTitle` `sectionTitle` `body` `label` `caption` — all built from system text styles, so Dynamic Type keeps working |

Ships with `.buttonStyle(.primary)`, `.buttonStyle(.secondary)`, `.card()` and
`AsyncButton`. How to rebrand, and the rules that keep it from rotting:
[`docs/design-system.md`](docs/design-system.md).

> [!NOTE]
> `AppIcon.png` is a placeholder in the accent colour. Replace it with one
> 1024x1024 PNG with no transparency - Xcode derives every other size.

## 🔌 Integrations

| Client | Backed by | Without a key |
|---|---|---|
| `PurchaseClient` | RevenueCat 5.88 | Nobody is entitled; SDK never configured |
| `AnalyticsClient` | PostHog 3.71 | Events dropped |
| `CrashReporter` | Sentry 9.27 | Nothing reported |
| `KeyValueStore` | UserDefaults / Keychain | Always active, no vendor |
| `HTTPClient` | `URLSession` | No `API_BASE_URL`? The sample data source returns a fixed user and makes no request |

SDKs start in `didFinishLaunchingWithOptions`, never in an initializer, so building the
composition root has no side effects.

`HTTPClient` is the whole networking layer: `URLSession` plus the one thing it does not
do, which is treat a non-2xx response as an error instead of handing back the error page
as `Data`. Set `API_BASE_URL` and `UserRemoteDataSource` makes a real request; leave it
empty and it serves sample data, so a fresh clone still contacts nobody.

`PaywallGate` wraps content and shows a RevenueCat paywall when the user is not
entitled. It reads entitlement **fail-closed**: a network failure shows a retry, never
the gated content and never a free unlock. RevenueCat's own `presentPaywallIfNeeded`
fails *open* — an offline device gets the paid experience — so the gate does its own
read instead.

## 🧪 Testing

```bash
make test
```

Unit tests in `ScaffoldTests/<Feature>/`, XCUITest flows in
`ScaffoldUITests/Flows/`. Swift Testing for units, XCTest for UI.

The security-critical cases are pinned: a failed entitlement read does not grant
access, a failed restore is not silently retryable, and an unconfigured build locks
premium rather than granting it.

## 🚢 CI/CD

| Workflow | When | What |
|---|---|---|
| `ci.yml` | PRs and pushes to `main` | `make check` |
| `build.yml` | push to `release/**` | archive + upload to TestFlight |

<details>
<summary><strong>TestFlight secrets</strong></summary>

<br/>

| Secret | Purpose |
|---|---|
| `BUILD_CERTIFICATE_BASE64` | base64 of the `.p12` bundle |
| `P12_PASSWORD` | password for that bundle |
| `KEYCHAIN_PASSWORD` | temporary CI keychain password |
| `APP_STORE_CONNECT_API_KEY_BASE64` | base64 of the `.p8` key |
| `APP_STORE_CONNECT_API_KEY_ID` | key ID |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | issuer ID |

Encode a file: `base64 -i Certificates.p12 | pbcopy`.

`ExportOptions.plist` intentionally has no `teamID` — the team comes from the archive
and `Config/Secrets.xcconfig`.

</details>

**Release:** bump `MARKETING_VERSION`, commit on `main`, push a `release/<version>`
branch. CI archives and uploads to TestFlight; submit from App Store Connect.
[SemVer](https://semver.org/): MAJOR for breaking UX, MINOR for features, PATCH for fixes.

## 🤖 Agent skills

Six skills are pinned in `skills-lock.json` — Apple's SwiftUI guidance exported from
Xcode 27, plus concurrency, testing and simulator tooling. Restore on a fresh clone:

```bash
npx skills experimental_install
```

Conventions agents must follow: [`AGENTS.md`](AGENTS.md).

## 🤝 Contributing

Setup, the invariants a PR is judged against, and the commit convention:
[`CONTRIBUTING.md`](CONTRIBUTING.md). Vulnerability reports:
[`SECURITY.md`](SECURITY.md) — private advisories, never a public issue.
Community expectations: [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).

> [!NOTE]
> Contributing to the starter itself? Do **not** run `scripts/rename-project.py` —
> that is for people starting an app *from* it.

## 📄 License

[MIT](LICENSE). Clone it, rename it, ship it — no attribution required in your app.
