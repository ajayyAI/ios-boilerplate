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
    func identify(userID: String, traits: [String: String])
    func track(_ event: AnalyticsEvent)
    func reset()
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
    }
}

/// Used whenever no analytics key is configured. Keeps a fresh clone green.
struct NoOpAnalyticsClient: AnalyticsClient {
    func identify(userID: String, traits: [String: String]) {}
    func track(_ event: AnalyticsEvent) {}
    func reset() {}
}
