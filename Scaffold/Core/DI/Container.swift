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

    var crashReporter: Factory<any CrashReporter> {
        Factory(self) { self.appEnvironment().crashReporter }
    }

    var keyValueStore: Factory<any KeyValueStore> {
        Factory(self) { self.appEnvironment().keyValueStore }
    }

    var purchaseClient: Factory<any PurchaseClient> {
        Factory(self) { self.appEnvironment().purchaseClient }
    }

    // MARK: User

    var userRepository: Factory<UserRepositoryProtocol> {
        Factory(self) {
            UserRepository(
                userLocalDataSource: self.userLocalDataSource(),
                userRemoteDataSource: self.userRemoteDataSource(),
            )
        }
    }

    var getUserUseCase: Factory<GetUserUseCase> {
        Factory(self) {
            GetUserUseCase(userRepository: self.userRepository())
        }
    }

    var userRemoteDataSource: Factory<UserRemoteDataSource> {
        Factory(self) { UserRemoteDataSource(http: self.httpClient()) }
    }

    /// `nil` until `API_BASE_URL` is set, which is what puts the data source on sample data.
    var httpClient: Factory<HTTPClient?> {
        Factory(self) {
            self.appEnvironment().config.apiBaseURL.map {
                HTTPClient(baseURL: $0, userAgent: DeviceInfo.current().userAgent)
            }
        }
    }

    var userLocalDataSource: Factory<UserLocalDataSource> {
        Factory(self) { UserLocalDataSource(store: self.keyValueStore()) }
    }
}
