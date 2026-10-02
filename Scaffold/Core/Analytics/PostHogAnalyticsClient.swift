//
//  PostHogAnalyticsClient.swift
//  Scaffold
//

import Foundation
@preconcurrency import PostHog

/// `AnalyticsClient` and `FeatureFlagClient` backed by PostHog.
///
/// Only ever constructed when `AppConfig.postHogAPIKey` is present — `AppEnvironment`
/// hands out the no-op clients otherwise — so reaching this type already means a
/// project token exists.
///
/// One type serves both protocols because PostHog is one SDK with one identity: a flag
/// evaluated for a user and an event tracked for that user must agree on who the user
/// is, and that only holds if both go through the same instance.
///
/// `@preconcurrency import`: posthog-ios predates `Sendable` and annotates nothing.
/// The SDK guards `shared` with its own lock, so the import is the honest way to say
/// "we know, it is fine" rather than sprinkling `nonisolated(unsafe)` over every use.
final nonisolated class PostHogAnalyticsClient: AnalyticsClient, FeatureFlagClient, Sendable {
    private let projectToken: String
    private let host: String
    private let environment: BuildEnvironment

    private let setupLock = NSLock()
    /// Guarded by `setupLock`. `nonisolated(unsafe)` because the compiler cannot see that.
    private nonisolated(unsafe) var isSetUp = false

    init(apiKey: String, host: String, environment: BuildEnvironment = .current) {
        projectToken = apiKey
        self.host = host
        self.environment = environment
    }

    // MARK: AnalyticsClient

    func start() {
        _ = configuredSDK()
    }

    func identify(userID: String, traits: [String: String]) {
        configuredSDK().identify(userID, userProperties: traits)
    }

    func track(_ event: AnalyticsEvent) {
        configuredSDK().capture(event.name.rawValue, properties: event.properties)
    }

    func screen(_ screen: AnalyticsScreen) {
        configuredSDK().screen(screen.rawValue)
    }

    func reset() {
        configuredSDK().reset()
    }

    func setCollectionEnabled(_ isEnabled: Bool) {
        if isEnabled {
            configuredSDK().optIn()
        } else {
            configuredSDK().optOut()
        }
    }

    var distinctID: String? {
        configuredSDK().getDistinctId()
    }

    // MARK: FeatureFlagClient

    func isEnabled(_ flag: FeatureFlag) -> Bool {
        // A flag the server has not answered for yet falls back to the code default,
        // which is what keeps a cold launch deterministic.
        configuredSDK().getFeatureFlagResult(flag.rawValue)?.enabled ?? flag.defaultValue
    }

    func payload(for flag: FeatureFlag) -> String? {
        configuredSDK().getFeatureFlagResult(flag.rawValue)?.payload as? String
    }

    func reload() async {
        await withCheckedContinuation { continuation in
            configuredSDK().reloadFeatureFlags {
                continuation.resume()
            }
        }
    }

    // MARK: Setup

    /// Runs `setup` on first use rather than in `init`.
    ///
    /// Putting it in `init` would make merely *constructing* the composition root spin
    /// up PostHog's queue and timers. Deferring keeps `AppEnvironment` a pure mapping
    /// and lets tests assert which client was selected without a vendor SDK running.
    private func configuredSDK() -> PostHogSDK {
        setupLock.lock()
        defer { setupLock.unlock() }

        if !isSetUp {
            PostHogSDK.shared.setup(makeConfig())
            PostHogSDK.shared.register([
                "environment": environment.name,
                "app_version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
                "app_build": Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "",
            ])
            isSetUp = true
        }
        return PostHogSDK.shared
    }

    /// The production configuration. Each value is a decision; the defaults it departs
    /// from are noted so the next reader knows which lines are load-bearing.
    private func makeConfig() -> PostHogConfig {
        let config = PostHogConfig(projectToken: projectToken, host: host)
        config.debug = environment == .development

        // Person profiles cost money per identified user; anonymous events stay cheap
        // until `identify` is called, which is the PostHog default and the right one.
        config.personProfiles = .identifiedOnly
        config.captureApplicationLifecycleEvents = true
        // The UIKit swizzle sees `UIHostingController`, not screens. SwiftUI screens
        // report themselves through `AnalyticsClient.screen(_:)` instead.
        config.captureScreenViews = false
        config.captureElementInteractions = false

        // Flags are fetched at setup so `isEnabled` has an answer by the first screen;
        // the code default covers the gap before the response lands.
        config.preloadFeatureFlags = true
        config.sendFeatureFlagEvent = true

        // Off: Sentry owns crashes, and two crash handlers in one process fight over
        // the signal handlers. Leave this off unless Sentry is removed.
        config.errorTrackingConfig.autoCapture = false
        // Off until there is a survey to show; the SDK default is on.
        config.surveys = false
        // Off by default because a replay of a health or finance screen is a recording
        // of personal data. Turn it on per app, after deciding what to mask, and keep
        // both masks below; they are what make a replay safe to store.
        config.sessionReplay = false
        config.sessionReplayConfig.maskAllTextInputs = true
        config.sessionReplayConfig.maskAllImages = true
        return config
    }
}
