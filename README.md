<div align="center">

<img src="Scaffold/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="104" alt="App icon" />

# Scaffold

**The SwiftUI foundation for shipping premium iOS apps.**

Strict Swift 6, fail-closed purchases, production-grade Sentry and PostHog, a
tokenised design system with haptics, and one gate that runs identically on a laptop
and in CI. Every vendor integration is dormant until it has a key.

<br/>

[![CI](https://github.com/ajayyAI/ios-boilerplate/actions/workflows/ci.yml/badge.svg)](https://github.com/ajayyAI/ios-boilerplate/actions/workflows/ci.yml)
[![Swift 6.3](https://img.shields.io/badge/Swift-6.3-fa7343?logo=swift&logoColor=white)](https://swift.org)
[![iOS 18+](https://img.shields.io/badge/iOS-18%2B-000000?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Xcode 26.6](https://img.shields.io/badge/Xcode-26.6-1575F9?logo=xcode&logoColor=white)](https://developer.apple.com/xcode/)
[![Strict Concurrency](https://img.shields.io/badge/concurrency-strict-6E4AFF)](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/)
[![Swift Testing](https://img.shields.io/badge/tests-Swift%20Testing-3fb950)](#testing)
[![MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

</div>

---

## Setup

```bash
brew bundle          # SwiftLint, SwiftFormat, xcbeautify, Periphery, lefthook
lefthook install
make check
```

`make check` is the gate: doctor, format, lint, build, test. CI runs the same target.
It passes on a clean checkout with no vendor accounts.

## What's inside

| | |
|---|---|
| **Swift 6, strict** | Main-actor default isolation, complete concurrency checking, warnings as errors, no suppressions. |
| **One gate** | `make check` locally and in CI. Hooks format and lint staged Swift, enforce Conventional Commits, and run tests before push. |
| **Fail-closed paywall** | A RevenueCat gate that never unlocks on a network error. Pinned by tests. |
| **Env-gated SDKs** | No key, no vendor. Every integration resolves to a no-op until configured, enforced by tests. |
| **Observability** | Sentry with tracing, profiling, app hangs, MetricKit, masked replay on error and PII scrubbing. PostHog with feature flags and super properties. dSYMs uploaded from CI. Caught errors reach Sentry through one call. |
| **Design system** | Semantic tokens for colour, spacing, radius and type. Press feedback that respects Reduce Motion. A five-word haptic vocabulary. |
| **Store readiness** | Privacy manifest, export-compliance declaration, Xcode 26 Enhanced Security, device-only Keychain, an accessibility audit in the UI tests. |
| **Agent-ready** | `AGENTS.md` conventions and six pinned skills, including Apple's SwiftUI guidance from Xcode 27. |

## Development

```bash
make check       # the gate
make format      # rewrite sources
make lint
make build
make test
make deadcode    # Periphery, on demand
make help
```

Hooks: pre-commit formats and lints staged Swift, commit-msg enforces Conventional
Commits, pre-push blocks `main`, refuses a push at a remote whose name doesn't match
`APP_NAME`, and runs tests. `SKIP_BRANCH_PROTECTION=1` and `SKIP_REPO_GUARD=1` override
the two guards.

> [!IMPORTANT]
> Client-side hooks are a convenience. The control that holds is a server-side ruleset:
> ```bash
> gh api -X POST repos/:owner/:repo/rulesets --input .github/main-ruleset.json
> ```

## Configuration

Build-time, through `Config/*.xcconfig`, read back by `AppConfig`. There is no `.env`
because there is no runtime environment on iOS.

```bash
cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig
```

Every key is optional. An absent key selects the no-op client. Details, and the two
xcconfig traps worth knowing: [`docs/configuration.md`](docs/configuration.md).

> [!WARNING]
> An xcconfig is not a secret store. Anything in the binary is recoverable with
> `strings` ([OWASP MASWE-0005](https://mas.owasp.org/MASWE/MASVS-AUTH/MASWE-0005/)).
> The keys here are publishable client keys. Anything that authorises spend belongs
> behind a backend.

## Architecture

Feature-first, Clean Architecture layers inside each feature. Rules and rationale:
[`docs/architecture.md`](docs/architecture.md).

```
Scaffold/
├── App/          entry point, app delegate, root view
├── Core/         DI, configuration, networking, analytics, crash reporting, flags, purchases, storage, diagnostics
├── Features/     product areas: Presentation / Domain / Data as each earns it
└── Shared/       design system, reusable UI, errors
```

`Scaffold/` is the source root. The folder name is bound to the target by Xcode's
file-system-synchronized groups.

## Design system

Every visual decision is a token in
[`Theme.swift`](Scaffold/Shared/UI/DesignSystem/Theme.swift). Views read tokens off
`\.theme` and nothing else names a colour or a point value.

```swift
RootView().environment(\.theme, .acme)
```

| Group | Tokens |
|---|---|
| `color` | `accent` `onAccent` `background` `surface` `border` `textPrimary` `textSecondary` `danger`, each an adaptive pair |
| `spacing` | `xs` 4 · `sm` 8 · `md` 16 · `lg` 24 · `xl` 32 |
| `radius` | `sm` 8 · `md` 12 · `lg` 20 |
| `font` | `screenTitle` `sectionTitle` `body` `label` `caption`, all from system text styles |
| `Haptic` | `.tap` `.selection` `.success` `.warning` `.error` via `.haptic(_:trigger:)` |

Ships with `.buttonStyle(.primary)`, `.buttonStyle(.secondary)`, `.card()` and
`AsyncButton`. Rules: [`docs/design-system.md`](docs/design-system.md).

## Integrations

| Client | Backed by | Without a key |
|---|---|---|
| `PurchaseClient` | RevenueCat 5.88 | Nobody is entitled; SDK never configured |
| `AnalyticsClient` | PostHog 3.74 | Events dropped |
| `FeatureFlagClient` | PostHog 3.74 | Every flag answers with its code default |
| `CrashReporter` | Sentry 9.28 | Nothing reported |
| `KeyValueStore` | UserDefaults / Keychain | Always active |
| `HTTPClient` | `URLSession` | Sample data, no request |

SDKs start in `didFinishLaunchingWithOptions`, never in an initializer, so the
composition root is side-effect free. Every vendor option is set once with its reason
inline. The decisions, the App Store privacy answers and the dSYM upload:
[`docs/observability.md`](docs/observability.md).

`PaywallGate` reads entitlement fail-closed. A failed read shows a retry, never the
gated content. RevenueCat's own `presentPaywallIfNeeded` fails open, which is why the
gate does its own read.

## Testing

```bash
make test
```

Swift Testing for units in `ScaffoldTests/<Feature>/`, XCUITest for flows in
`ScaffoldUITests/Flows/`, including Xcode's accessibility audit on the home screen.
The security-critical paths are pinned: a failed entitlement read does not grant
access, a failed restore is not silently retryable, an unconfigured build locks premium.

## CI/CD

| Workflow | Trigger | Does |
|---|---|---|
| `ci.yml` | PRs and pushes to `main` | `make check` |
| `build.yml` | push to `release/**` | archive, upload dSYMs to Sentry, upload to TestFlight |

<details>
<summary><strong>Secrets</strong></summary>

<br/>

| Secret | Purpose |
|---|---|
| `BUILD_CERTIFICATE_BASE64` | base64 of the `.p12` |
| `P12_PASSWORD` | its password |
| `KEYCHAIN_PASSWORD` | temporary CI keychain password |
| `APP_STORE_CONNECT_API_KEY_BASE64` | base64 of the `.p8` |
| `APP_STORE_CONNECT_API_KEY_ID` | key ID |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | issuer ID |
| `SENTRY_AUTH_TOKEN` `SENTRY_ORG` `SENTRY_PROJECT` | optional; absent, the dSYM step is skipped |

`ExportOptions.plist` carries no `teamID`; the team comes from the archive and
`Config/Secrets.xcconfig`.

</details>

Release: bump `MARKETING_VERSION`, push a `release/<version>` branch, submit from App
Store Connect.

## Capabilities

Widgets, push notifications, HealthKit and deep links are not shipped. Each has a
recipe that plugs into a seam already here: [`docs/recipes/`](docs/recipes/README.md).

## Agents

Conventions in [`AGENTS.md`](AGENTS.md). Skills pinned in `skills-lock.json`; restore
with `npx skills experimental_install`.

## Contributing

[`CONTRIBUTING.md`](CONTRIBUTING.md) · [`SECURITY.md`](SECURITY.md) ·
[`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md)

## License

[MIT](LICENSE).
