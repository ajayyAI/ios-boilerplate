# Observability

Two vendors, one rule: **a caught error is reported, and an unconfigured build reports
nothing.** Sentry owns crashes, hangs and performance; PostHog owns product analytics,
feature flags and session replay. Neither starts without a key.

## Sentry

Configured in [`Core/CrashReporting/SentryCrashReporter.swift`](../Scaffold/Core/CrashReporting/SentryCrashReporter.swift).
Every option is commented in place. The decisions:

| Decision | Value | Why |
|---|---|---|
| `environment` | `development` / `production` from `BuildEnvironment` | A crash in a debug build is a different problem from one in the App Store build |
| `releaseName` | SDK default, `bundleID@version+build` | Matches what `sentry-cli` tags the dSYMs with |
| `tracesSampleRate` | 0.2 | 100% of traffic is quota spent on data nobody reads |
| profiling | 10% of sampled traces, plus app start | App start is where users feel slowness first |
| app hangs | on, 2s | A hang is a crash the user chose not to wait for |
| MetricKit | on | The only source of out-of-memory and launch diagnostics; SDK default is off |
| async stack traces | on | Otherwise every `await` boundary looks like the runtime crashed |
| screenshots | on, masked | View hierarchy off: large and rarely read |
| session replay | errors only, masked | The clip that explains a crash is worth storing; a scroll session is not |
| `sendDefaultPii` | off | Also enable "Prevent Storing of IP Addresses" in the Sentry project; the SDK flag alone does not stop the server recording one |

### Reporting an error

```swift
} catch {
    crashReporter.report(error, context: "Home.refresh")
    state = .failed(PresentableError(error))
}
```

`report` logs, adds a breadcrumb and captures. It drops `CancellationError` and cancelled
`URLError`s, because a user leaving a screen mid-request is not a defect. View models
take `crashReporter` by initializer; the default is the no-op, so tests stay silent.

### Symbols

`build.yml` uploads dSYMs with `sentry-cli debug-files upload --wait` after every
archive. Set three repository secrets and it runs; leave them unset and the step is
skipped:

| Secret | Where |
|---|---|
| `SENTRY_AUTH_TOKEN` | Sentry → Settings → Auth Tokens, scope `project:releases` + `project:write` |
| `SENTRY_ORG` | The org slug in the URL |
| `SENTRY_PROJECT` | The project slug |

Since Xcode 14, App Store Connect no longer lets you download dSYMs, so the CI copy is
the only one.

## PostHog

Configured in [`Core/Analytics/PostHogAnalyticsClient.swift`](../Scaffold/Core/Analytics/PostHogAnalyticsClient.swift).
One instance serves `AnalyticsClient` and `FeatureFlagClient`, so a flag evaluated for
a user and an event tracked for that user agree on who the user is.

| Decision | Value | Why |
|---|---|---|
| `personProfiles` | `.identifiedOnly` | Profiles cost per user; anonymous events stay cheap until `identify` |
| `captureScreenViews` | off | The UIKit swizzle sees `UIHostingController`, not screens. Call `analytics.screen(.home)` |
| feature flags | preloaded at setup | `isEnabled` has an answer by the first screen; the code default covers the gap |
| crash autocapture | off | Sentry owns crashes; two handlers fight over the signal handlers |
| surveys | off | SDK default is on |
| session replay | off, masks on | A replay of a health or finance screen is a recording of personal data. Enable per app after deciding what to mask |
| super properties | `environment`, `app_version`, `app_build` | Every event is filterable by build without a join |

### Events and flags are closed sets

`AnalyticsEvent.Name`, `AnalyticsScreen` and `FeatureFlag` are enums. An analytics
schema anyone can add to silently is one nobody can query later, and a flag key typed at
a call site is one that drifts from the dashboard. Add a case, and for a flag write the
default next to it: that default is what a cold launch, an offline device and the
unconfigured clone all see.

### Linking the two

No SDK links a Sentry issue to a PostHog person on iOS. The app delegate sets the
PostHog distinct ID as a Sentry tag (`posthog.distinct_id`) at launch. Search Sentry by
that tag to find the funnel and replay for the person who crashed. Call `identify` and
`setUser` together, with the same opaque ID, when a user signs in.

### Consent

`AnalyticsClient.setCollectionEnabled(false)` opts the device out and persists it. Wire
it to a "Share usage data" switch in Settings. Crash reporting is not covered by it;
crash data is diagnostic, not behavioural, and is declared as such in the privacy
manifest.

## Privacy manifest and nutrition labels

[`PrivacyInfo.xcprivacy`](../Scaffold/PrivacyInfo.xcprivacy) declares what both SDKs
collect once configured, all **not linked** and **not for tracking**. In App Store
Connect, answer:

- Diagnostics → Crash Data, Performance Data, Other Diagnostic Data (Sentry)
- Usage Data → Product Interaction, Other Usage Data (PostHog)

Both purposes Analytics and App Functionality, not linked, not tracking. Two things
change that: sending an email address (add Contact Info, linked) or a real user ID
(add Identifiers → User ID, linked).

## Logs

`Log.app`, `Log.network`, `Log.purchases`, `Log.analytics`, `Log.storage` are
`os.Logger`s under the bundle identifier. Interpolated values are redacted in release
unless marked `privacy: .public`. Logs are for a developer reading a device; anything
that must reach a human in production goes through `report`.
