//
//  AppConfig.swift
//  Scaffold
//

import Foundation

/// Build-time configuration, read from the Info.plist entries that xcconfig
/// substitutes into.
///
/// iOS has no runtime environment to read, so configuration is baked in at build
/// time. `Config/*.xcconfig` supplies the values; `Info.plist` carries them as
/// `$(VAR)` substitutions; this type reads them back.
///
/// Every integration key is optional. An absent or empty key selects the no-op
/// implementation of its client, so a fresh clone with no `Secrets.xcconfig`
/// builds, runs, and tests green without any vendor account.
///
/// This is not a secret store. Anything here ships inside the binary and is
/// recoverable with `strings`. Keys that authorize real spend or real data belong
/// behind a backend proxy with short-lived tokens — see `docs/configuration.md`.
nonisolated struct AppConfig: Sendable {
    let apiBaseURL: URL?
    let revenueCatAPIKey: String?
    let sentryDSN: String?
    let postHogAPIKey: String?
    let postHogHost: String

    static let postHogDefaultHost = "https://eu.i.posthog.com"

    init(bundle: Bundle = .main) {
        self.init(
            apiBaseURL: Self.value(for: .apiBaseURL, in: bundle).flatMap(URL.init(string:)),
            revenueCatAPIKey: Self.value(for: .revenueCatAPIKey, in: bundle),
            sentryDSN: Self.value(for: .sentryDSN, in: bundle),
            postHogAPIKey: Self.value(for: .postHogAPIKey, in: bundle),
            postHogHost: Self.value(for: .postHogHost, in: bundle) ?? Self.postHogDefaultHost,
        )
    }

    init(
        apiBaseURL: URL? = nil,
        revenueCatAPIKey: String?,
        sentryDSN: String?,
        postHogAPIKey: String?,
        postHogHost: String = AppConfig.postHogDefaultHost,
    ) {
        self.apiBaseURL = apiBaseURL
        self.revenueCatAPIKey = revenueCatAPIKey
        self.sentryDSN = sentryDSN
        self.postHogAPIKey = postHogAPIKey
        self.postHogHost = postHogHost
    }

    /// Info.plist keys populated from xcconfig. Adding a case here means adding the
    /// matching entry to `Info.plist` and `Config/Secrets.example.xcconfig`.
    enum Key: String {
        case apiBaseURL = "APIBaseURL"
        case revenueCatAPIKey = "RevenueCatAPIKey"
        case sentryDSN = "SentryDSN"
        case postHogAPIKey = "PostHogAPIKey"
        case postHogHost = "PostHogHost"
    }

    /// Treats whitespace-only values as absent. An unset xcconfig variable
    /// substitutes to an empty string rather than removing the plist entry, so
    /// "present but empty" is the normal shape of "not configured".
    private static func value(for key: Key, in bundle: Bundle) -> String? {
        guard let raw = bundle.object(forInfoDictionaryKey: key.rawValue) as? String else {
            return nil
        }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
