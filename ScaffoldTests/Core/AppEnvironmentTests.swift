//
//  AppEnvironmentTests.swift
//  ScaffoldTests
//

import Testing
@testable import Scaffold

/// Guards the invariant that makes a fresh clone safe: with no keys configured, every
/// client is a no-op and no vendor SDK is ever constructed.
///
/// The assertions are on concrete types rather than on behaviour because behaviour is
/// precisely what must not happen — a test that "proved" PostHog was wired by capturing
/// an event would have to start PostHog to do it. Both real clients defer SDK
/// initialisation past `init`, so constructing one here reaches no vendor.
///
/// The app module defaults to `MainActor` isolation, which makes `AppConfig`'s
/// initialisers main-actor isolated. The test target has no such default, so it opts in.
@MainActor
struct AppEnvironmentTests {
    /// What a clone with no `Secrets.xcconfig` sees: `AppConfig` normalises every absent
    /// or whitespace-only xcconfig value to `nil` before it reaches `AppEnvironment`.
    private static let unconfigured = AppConfig(revenueCatAPIKey: nil, sentryDSN: nil, postHogAPIKey: nil)

    @Test func `no keys selects the no-op analytics client`() {
        let environment = AppEnvironment(config: Self.unconfigured)

        #expect(environment.analyticsClient is NoOpAnalyticsClient)
    }

    @Test func `no keys selects the no-op crash reporter`() {
        let environment = AppEnvironment(config: Self.unconfigured)

        #expect(environment.crashReporter is NoOpCrashReporter)
    }

    @Test func `a PostHog key selects the PostHog analytics client`() {
        let config = AppConfig(revenueCatAPIKey: nil, sentryDSN: nil, postHogAPIKey: "phc_example")

        #expect(AppEnvironment(config: config).analyticsClient is PostHogAnalyticsClient)
    }

    @Test func `a Sentry DSN selects the Sentry crash reporter`() {
        let config = AppConfig(
            revenueCatAPIKey: nil,
            sentryDSN: "https://examplePublicKey@o0.ingest.sentry.io/0",
            postHogAPIKey: nil,
        )

        #expect(AppEnvironment(config: config).crashReporter is SentryCrashReporter)
    }

    /// Each key is read independently: configuring one vendor must not switch on another.
    @Test func `configuring one vendor leaves the other no-op`() {
        let config = AppConfig(revenueCatAPIKey: nil, sentryDSN: nil, postHogAPIKey: "phc_example")
        let environment = AppEnvironment(config: config)

        #expect(environment.analyticsClient is PostHogAnalyticsClient)
        #expect(environment.crashReporter is NoOpCrashReporter)
    }

    @Test func `a key value store is always available`() {
        let environment = AppEnvironment(config: Self.unconfigured)

        #expect(environment.keyValueStore is UserDefaultsKeyValueStore)
    }
}
