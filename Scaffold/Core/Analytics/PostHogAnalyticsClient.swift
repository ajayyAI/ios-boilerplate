//
//  PostHogAnalyticsClient.swift
//  Scaffold
//

import Foundation
import PostHog

/// `AnalyticsClient` backed by PostHog.
///
/// Only ever constructed when `AppConfig.postHogAPIKey` is present — `AppEnvironment`
/// hands out `NoOpAnalyticsClient` otherwise — so reaching this type already means a
/// project token exists.
final nonisolated class PostHogAnalyticsClient: AnalyticsClient, Sendable {
    private let projectToken: String
    private let host: String

    private let setupLock = NSLock()
    /// Guarded by `setupLock`. `nonisolated(unsafe)` because the compiler cannot see that.
    private nonisolated(unsafe) var isSetUp = false

    init(apiKey: String, host: String) {
        projectToken = apiKey
        self.host = host
    }

    func identify(userID: String, traits: [String: String]) {
        configuredSDK().identify(userID, userProperties: traits)
    }

    func track(_ event: AnalyticsEvent) {
        configuredSDK().capture(event.name.rawValue, properties: event.properties)
    }

    func reset() {
        configuredSDK().reset()
    }

    /// Runs `setup` on first use rather than in `init`.
    ///
    /// `AnalyticsClient` has no `start()`, so `init` is the only other place setup could
    /// go — and that would make merely *constructing* the composition root spin up
    /// PostHog's queue and timers. Deferring keeps `AppEnvironment` a pure mapping and
    /// lets tests assert which client was selected without a vendor SDK ever running.
    private func configuredSDK() -> PostHogSDK {
        setupLock.lock()
        defer { setupLock.unlock() }

        if !isSetUp {
            PostHogSDK.shared.setup(PostHogConfig(projectToken: projectToken, host: host))
            isSetUp = true
        }
        return PostHogSDK.shared
    }
}
