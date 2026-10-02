//
//  AnalyticsClient.swift
//  Scaffold
//

import Foundation

/// A product analytics sink.
///
/// The protocol exists so tests can assert what a flow reports without a network
/// call or a vendor account, and so an unconfigured build reports nothing at all.
protocol AnalyticsClient: Sendable {
    /// Configures the underlying SDK. Safe to call once at launch.
    func start()
    func identify(userID: String, traits: [String: String])
    func track(_ event: AnalyticsEvent)
    /// A screen appearing. SwiftUI has no view controller to swizzle, so screens name
    /// themselves; the closed set is `AnalyticsScreen`.
    func screen(_ screen: AnalyticsScreen)
    func reset()
    /// A user-facing "share usage data" switch. Off means nothing is queued or sent
    /// until it is turned on again; the choice persists across launches.
    func setCollectionEnabled(_ isEnabled: Bool)
    /// The vendor's identifier for this install, for joining with other tools. `nil`
    /// when there is no vendor.
    var distinctID: String? { get }
}

/// A tracked event.
///
/// `name` is a closed set rather than a free string: an analytics schema that
/// anyone can add to silently is one nobody can query later.
struct AnalyticsEvent: Equatable, Sendable {
    let name: Name
    let properties: [String: String]

    init(_ name: Name, properties: [String: String] = [:]) {
        self.name = name
        self.properties = properties
    }

    enum Name: String, Sendable {
        case appLaunched = "app_launched"
        case paywallShown = "paywall_shown"
        case paywallDismissed = "paywall_dismissed"
        case purchaseCompleted = "purchase_completed"
        case purchaseRestored = "purchase_restored"
        case reviewPromptShown = "review_prompt_shown"
    }
}

/// Screens worth a funnel step. Same closed-set rule as `AnalyticsEvent.Name`.
enum AnalyticsScreen: String, Sendable {
    case home = "Home"
    case paywall = "Paywall"
}

/// Used whenever no analytics key is configured. Keeps a fresh clone green.
struct NoOpAnalyticsClient: AnalyticsClient {
    func start() {}
    func identify(userID: String, traits: [String: String]) {}
    func track(_ event: AnalyticsEvent) {}
    func screen(_ screen: AnalyticsScreen) {}
    func reset() {}
    func setCollectionEnabled(_ isEnabled: Bool) {}
    var distinctID: String? {
        nil
    }
}
