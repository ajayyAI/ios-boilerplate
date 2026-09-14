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
///
/// The options below are the production set, not the minimum. Each one is either on
/// because a crash without it is hard to act on, or off because it costs quota or
/// privacy. Change a value here, not at the call site; there is exactly one call site.
final nonisolated class SentryCrashReporter: CrashReporter, Sendable {
    private let dsn: String
    private let environment: BuildEnvironment

    init(dsn: String, environment: BuildEnvironment = .current) {
        self.dsn = dsn
        self.environment = environment
    }

    /// The SDK is started here, not in `init`, so that building the composition root has
    /// no side effects. Nothing reaches Sentry until the app explicitly asks for it.
    func start() {
        SentrySDK.start { [dsn, environment] options in
            options.dsn = dsn
            options.environment = environment.name
            // `releaseName` already defaults to `bundleID@version+build`, which is what
            // the dSYM upload in CI tags, so it is left alone on purpose.
            options.debug = environment == .development

            // Tracing and profiling are sampled: 100% of a consumer app's traffic is
            // quota spent on data nobody reads. Profiles ride along with sampled traces
            // and cover app start, which is the one place users feel slowness first.
            options.tracesSampleRate = 0.2
            options.configureProfiling = {
                $0.sessionSampleRate = 0.1
                $0.lifecycle = .trace
                $0.profileAppStarts = true
            }

            // A hang is a crash the user chose not to wait for. The 2s default matches
            // the point at which people start tapping again.
            options.enableAppHangTracking = true
            options.appHangTimeoutInterval = 2
            options.enableWatchdogTerminationTracking = true
            // Off by default in the SDK; on here because it is the only source of
            // out-of-memory and launch-time diagnostics, and it costs nothing.
            options.enableMetricKit = true
            // Stitches `await` boundaries back into one stack trace. Without it every
            // async error looks like it came from the runtime.
            options.swiftAsyncStacktraces = true
            options.enablePersistingTracesWhenCrashing = true

            // Screenshots are masked by default; the view hierarchy is not attached
            // because it is large and rarely read.
            options.attachScreenshot = true
            options.attachViewHierarchy = false
            // Replay only for sessions that hit an error: the clip that explains a crash
            // is worth storing, ten minutes of someone scrolling is not. Text and images
            // stay masked, which is the SDK default and is what makes this shippable.
            options.sessionReplay.sessionSampleRate = 0
            options.sessionReplay.onErrorSampleRate = 1

            // IP addresses and similar are never sent. Sentry also needs "Prevent
            // Storing of IP Addresses" enabled in the project's Security & Privacy
            // settings; the SDK flag alone does not stop the server recording one.
            options.sendDefaultPii = false
            options.beforeSend = { event in
                event.request?.headers?["Authorization"] = nil
                event.request?.headers?["Cookie"] = nil
                return event
            }
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

    func setTag(_ key: String, value: String?) {
        SentrySDK.configureScope { scope in
            if let value {
                scope.setTag(value: value, key: key)
            } else {
                scope.removeTag(key: key)
            }
        }
    }
}
