# Configuration

## Why there is no `.env`

`.env` is a runtime mechanism: the process reads variables from the shell that
launched it. An iOS app has no such shell — it is a signed bundle launched by the
system on someone's device. So configuration is either **baked in at build time** or
**fetched at runtime** from a server you control.

`xcconfig` is the build-time mechanism, and it is this project's `.env`.

Worth knowing if you came from Expo or React Native: `.env` there is not a runtime
environment either. Metro inlines `EXPO_PUBLIC_*` into the JS bundle at build time.
Same mechanism, different syntax — and the same consequence for secrets, below.

## Layout

```text
Config/
├── Shared.xcconfig           Common values. Tracked.
├── Debug.xcconfig            Debug overrides. Tracked.
├── Release.xcconfig          Release overrides. Tracked.
├── Secrets.example.xcconfig  Documents every key. Tracked.
└── Secrets.xcconfig          Your real values. Gitignored, optional.
```

`Shared.xcconfig` ends with `#include? "Secrets.xcconfig"`. The `?` makes the include
optional, which is what lets a fresh clone build before you have created the file.

Values reach the app through `Info.plist`, which carries `$(VAR)` substitutions, and
are read back by `AppConfig`.

## Getting started

```bash
cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig
```

Fill in what you have. Leave the rest blank.

**Every integration key is optional.** An absent or empty key selects the no-op
implementation of its client, so the app builds, runs, and tests green with no vendor
accounts at all. That property is enforced by `AppEnvironmentTests`; if you add an
integration, keep it true.

## Keys

| Key | Where to find it | Blank means |
|---|---|---|
| `DEVELOPMENT_TEAM` | developer.apple.com → Membership → Team ID | Signing must be set manually in Xcode |
| `APP_BUNDLE_ID` | You choose it | — (has a default) |
| `API_BASE_URL` | Your backend's base URL | `UserRemoteDataSource` returns sample data and makes no request |
| `REVENUECAT_API_KEY` | RevenueCat → Project settings → API keys → Apple App Store | Purchases no-op; nobody is entitled |
| `SENTRY_DSN` | Sentry → Settings → Projects → Client Keys | No crash reporting |
| `POSTHOG_API_KEY` | PostHog → Project settings → Project API key | No analytics |
| `POSTHOG_HOST` | Your PostHog region | Defaults to EU cloud |

## Two traps this layout already works around

**`//` starts a comment anywhere in a line, including mid-value.** Writing
`POSTHOG_HOST = https://eu.i.posthog.com` silently yields `https:`. The fix is to break
up the slash *pair* with an empty expansion — `$()` must sit **between** the two
slashes:

```
POSTHOG_HOST = https:/$()/eu.i.posthog.com    # correct
POSTHOG_HOST = https:$()//eu.i.posthog.com    # still truncates to "https:"
```

**Target-level build settings beat xcconfig.** A value hardcoded in the target's Build
Settings silently wins over the same key in an xcconfig, and nothing warns you. This
project therefore has no target-level `PRODUCT_BUNDLE_IDENTIFIER` or
`DEVELOPMENT_TEAM`. If you set one in Xcode's UI, you have overridden this file and
should expect the config layer to stop working for that key.

Verify what actually resolved:

```bash
xcodebuild -project Scaffold.xcodeproj -target Scaffold -showBuildSettings \
  | grep DEVELOPMENT_TEAM
```

## This is not a secret store

A gitignored `Secrets.xcconfig` keeps keys out of git history and away from
contributors. It does nothing for the shipped binary. Anything baked in through
`Info.plist` or a build setting is recoverable from the app package with `strings`, a
disassembler, or a proxy. OWASP MAS covers this as
[MASWE-0005](https://mas.owasp.org/MASWE/MASVS-AUTH/MASWE-0005/).

The keys in the table above are *publishable client keys* — RevenueCat's SDK key,
Sentry's DSN, PostHog's project key are all designed to ship inside clients, and
extraction is not a vulnerability for them.

Any key that authorizes real spend or reads user data is different, and does **not**
belong here regardless of gitignore. Put it behind your own backend: the server holds
the real credential, the app receives short-lived scoped tokens, and
[App Attest](https://developer.apple.com/documentation/devicecheck/establishing-your-app-s-integrity)
verifies the request came from a genuine build of your app.

The two mechanisms solve different problems. Gitignore protects the repository;
a backend proxy protects the credential. Neither substitutes for the other.
