//
//  FeatureFlagClient.swift
//  Scaffold
//

import Foundation

/// Remote switches, read at the point of use.
///
/// The protocol is how a screen asks "is this on?" without knowing which vendor
/// answers, and how a test sets the answer without a network.
protocol FeatureFlagClient: Sendable {
    func isEnabled(_ flag: FeatureFlag) -> Bool
    /// The flag's JSON payload as a string, for flags that carry configuration rather
    /// than a boolean. `nil` when the flag has none or is unknown.
    func payload(for flag: FeatureFlag) -> String?
    /// Re-fetches from the server, for example after `identify`, when the user's
    /// cohort may have changed.
    func reload() async
}

/// Every flag the app reads, with the value it takes when the server has not answered.
///
/// A closed set for the same reason as `AnalyticsEvent.Name`: a flag key typed at a
/// call site is one that drifts from the dashboard, and the default written next to
/// the key is what a cold launch, an offline device and the unconfigured clone all see.
enum FeatureFlag: String, CaseIterable, Sendable {
    case exampleNewHomeLayout = "new-home-layout"

    var defaultValue: Bool {
        switch self {
        case .exampleNewHomeLayout: false
        }
    }
}

/// Used whenever no analytics key is configured. Every flag answers with its default.
struct NoOpFeatureFlagClient: FeatureFlagClient {
    func isEnabled(_ flag: FeatureFlag) -> Bool {
        flag.defaultValue
    }

    func payload(for flag: FeatureFlag) -> String? {
        nil
    }

    func reload() async {}
}
