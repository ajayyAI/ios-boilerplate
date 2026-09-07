//
//  AppEnvironment.swift
//  Scaffold
//

import Foundation

/// The composition root: maps build-time configuration onto one implementation of each
/// cross-cutting client.
///
/// The mapping is total — every key is either present, selecting the vendor client, or
/// absent, selecting the no-op one — and it is the single place that decision is made.
/// Scattering `if apiKey != nil` across call sites is how a clone with no keys ends up
/// talking to a vendor anyway.
///
/// Nothing here starts an SDK. Selection and initialisation are deliberately separate:
/// constructing an `AppEnvironment` opens no connection, reads no device identifiers and
/// schedules no timers, which is what lets tests build the real clients to assert wiring.
nonisolated struct AppEnvironment: Sendable {
    let config: AppConfig
    let analyticsClient: any AnalyticsClient
    let crashReporter: any CrashReporter
    let keyValueStore: any KeyValueStore
    let purchaseClient: any PurchaseClient

    /// Whether there is anything to sell. Distinct from entitlement: a build with no
    /// RevenueCat key has no purchasable product, so a hard paywall would be a dead end
    /// with no exit. The gate downgrades to a dismissible presentation in that case.
    let isPurchasingConfigured: Bool

    init(config: AppConfig) {
        self.config = config
        analyticsClient = Self.makeAnalyticsClient(config: config)
        crashReporter = Self.makeCrashReporter(config: config)
        keyValueStore = UserDefaultsKeyValueStore()
        purchaseClient = Self.makePurchaseClient(config: config)
        isPurchasingConfigured = config.revenueCatAPIKey != nil
    }

    private static func makeAnalyticsClient(config: AppConfig) -> any AnalyticsClient {
        guard let apiKey = config.postHogAPIKey else {
            return NoOpAnalyticsClient()
        }
        return PostHogAnalyticsClient(apiKey: apiKey, host: config.postHogHost)
    }

    private static func makePurchaseClient(config: AppConfig) -> any PurchaseClient {
        guard let apiKey = config.revenueCatAPIKey else {
            return NoOpPurchaseClient()
        }
        return RevenueCatPurchaseClient(apiKey: apiKey)
    }

    private static func makeCrashReporter(config: AppConfig) -> any CrashReporter {
        guard let dsn = config.sentryDSN else {
            return NoOpCrashReporter()
        }
        return SentryCrashReporter(dsn: dsn)
    }
}
