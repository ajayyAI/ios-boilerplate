//
//  SentryCrashReporter.swift
//  Scaffold
//

import Foundation
import Sentry

/// `CrashReporter` backed by Sentry.
///
/// Only ever constructed when `AppConfig.sentryDSN` is present — `AppEnvironment` hands
/// out `NoOpCrashReporter` otherwise — so reaching this type already means a DSN exists.
final nonisolated class SentryCrashReporter: CrashReporter, Sendable {
    private let dsn: String

    init(dsn: String) {
        self.dsn = dsn
    }

    /// The SDK is started here, not in `init`, so that building the composition root has
    /// no side effects. Nothing reaches Sentry until the app explicitly asks for it.
    func start() {
        SentrySDK.start { [dsn] options in
            options.dsn = dsn
        }
    }

    func capture(_ error: Error) {
        SentrySDK.capture(error: error)
    }

    func addBreadcrumb(_ message: String) {
        let breadcrumb = Breadcrumb(level: .info, category: "app")
        breadcrumb.message = message
        SentrySDK.addBreadcrumb(breadcrumb)
    }

    func setUser(id: String?) {
        guard let id else {
            SentrySDK.setUser(nil)
            return
        }
        SentrySDK.setUser(User(userId: id))
    }
}
