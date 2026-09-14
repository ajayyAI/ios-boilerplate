//
//  SuperwallPurchaseClientTests.swift
//  ScaffoldTests
//

import Foundation
import SuperwallKit
import Testing
@testable import Scaffold

/// Pins the translation from the SDK's subscription status to the app's `Entitlement`.
///
/// Everything here runs against the pure mapping, never `Superwall.shared`: configuring the
/// SDK installs a process-wide singleton and opens a connection, which is precisely what a
/// unit test must not do.
///
/// The app module defaults to `MainActor` isolation, which isolates `Entitlement`'s
/// `Equatable` conformance. The test target has no such default, so it opts in.
@MainActor
struct SuperwallPurchaseClientTests {
    /// The one that matters. `.unknown` means the SDK has not decided yet — offline on a
    /// first launch it may never decide — and an answer in either direction would be a guess.
    @Test func `an unknown status is not an answer`() {
        #expect(SuperwallPurchaseClient.entitlement(for: .unknown, identifier: nil) == nil)
    }

    @Test func `an inactive status is not subscribed`() {
        #expect(SuperwallPurchaseClient.entitlement(for: .inactive, identifier: nil) == .notSubscribed)
    }

    @Test func `any active entitlement subscribes when no identifier is required`() {
        let status = SubscriptionStatus.active([SuperwallKit.Entitlement(id: "pro")])

        #expect(SuperwallPurchaseClient.entitlement(for: status, identifier: nil) == .subscribed(expiresAt: nil))
    }

    @Test func `a required identifier ignores other tiers`() {
        let status = SubscriptionStatus.active([SuperwallKit.Entitlement(id: "basic")])

        #expect(SuperwallPurchaseClient.entitlement(for: status, identifier: "pro") == .notSubscribed)
        #expect(SuperwallPurchaseClient.entitlement(for: status, identifier: "basic") == .subscribed(expiresAt: nil))
    }

    /// `.active` is the SDK's claim about the set, not about each member.
    @Test func `an inactive entitlement inside an active status does not subscribe`() throws {
        let status = try SubscriptionStatus.active([Self.entitlement(id: "pro", isActive: false)])

        #expect(SuperwallPurchaseClient.entitlement(for: status, identifier: nil) == .notSubscribed)
    }

    @Test func `the expiry is carried through`() throws {
        let expiry = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let status = try SubscriptionStatus.active([Self.entitlement(id: "pro", expiresAt: expiry)])

        #expect(SuperwallPurchaseClient.entitlement(for: status, identifier: nil) == .subscribed(expiresAt: expiry))
    }

    @Test func `a lifetime entitlement outranks a dated one`() throws {
        let expiry = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let status = try SubscriptionStatus.active([
            Self.entitlement(id: "monthly", expiresAt: expiry),
            Self.entitlement(id: "lifetime"),
        ])

        #expect(SuperwallPurchaseClient.entitlement(for: status, identifier: nil) == .subscribed(expiresAt: nil))
    }

    /// The SDK's memberwise initialiser is internal, so anything beyond an identifier is
    /// built the way the SDK itself receives it: decoded.
    private static func entitlement(
        id: String,
        isActive: Bool = true,
        expiresAt: Date? = nil,
    ) throws -> SuperwallKit.Entitlement {
        var fields: [String: Any] = ["identifier": id, "type": "SERVICE_LEVEL", "isActive": isActive]
        if let expiresAt {
            fields["expiresAt"] = expiresAt.timeIntervalSinceReferenceDate
        }
        let data = try JSONSerialization.data(withJSONObject: fields)
        return try JSONDecoder().decode(SuperwallKit.Entitlement.self, from: data)
    }
}
