//
//  Container.swift
//  Scaffold
//

import FactoryKit
import Foundation

extension Container: @retroactive AutoRegistering {
    public func autoRegister() {
        // Every client below is a singleton unless it overrides the scope. Resolving the
        // composition root twice would build a second Sentry and a second PostHog.
        manager.defaultScope = .singleton
    }
}

extension Container {
    // MARK: Environment

    /// Resolved once by the default singleton scope, so every client below comes from the
    /// same configuration read and no vendor client is constructed twice.
    var appEnvironment: Factory<AppEnvironment> {
        Factory(self) { AppEnvironment(config: AppConfig()) }
    }

    var analyticsClient: Factory<any AnalyticsClient> {
        Factory(self) { self.appEnvironment().analyticsClient }
    }

    var featureFlagClient: Factory<any FeatureFlagClient> {
        Factory(self) { self.appEnvironment().featureFlagClient }
    }

    var crashReporter: Factory<any CrashReporter> {
        Factory(self) { self.appEnvironment().crashReporter }
    }

    var keyValueStore: Factory<any KeyValueStore> {
        Factory(self) { self.appEnvironment().keyValueStore }
    }

    var purchaseClient: Factory<any PurchaseClient> {
        Factory(self) { self.appEnvironment().purchaseClient }
    }

    var reviewPrompter: Factory<ReviewPrompter> {
        Factory(self) { ReviewPrompter(store: self.keyValueStore()) }
    }

    // MARK: User

    var userRepository: Factory<any UserRepository> {
        Factory(self) { APIUserRepository(http: self.httpClient(), store: self.keyValueStore()) }
    }

    /// `nil` until `API_BASE_URL` is set, which is what puts the repository on sample data.
    var httpClient: Factory<HTTPClient?> {
        Factory(self) {
            self.appEnvironment().config.apiBaseURL.map {
                HTTPClient(baseURL: $0, userAgent: DeviceInfo.current().userAgent)
            }
        }
    }
}
