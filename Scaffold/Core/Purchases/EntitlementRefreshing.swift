//
//  EntitlementRefreshing.swift
//  Scaffold
//

import Foundation

/// A `PurchaseClient` that can report *why* it has no entitlement.
///
/// `PurchaseClient.entitlement()` cannot throw, so a transport failure and a genuine "not
/// a subscriber" arrive as the same value. A caller that cannot tell those apart has to
/// pick one wrong behaviour: fail open and give the product away to anyone who turns off
/// Wi-Fi, or fail closed and show a paywall to a paying customer with no explanation. This
/// refinement buys a third option — surface the failure and offer a retry.
///
/// Clients that genuinely cannot fail deliberately do not conform. `NoOpPurchaseClient` is
/// the one that matters: with no key configured there is no network call to fail, and its
/// honest `.notSubscribed` should not be dressed up as an error.
protocol EntitlementRefreshing: PurchaseClient {
    /// Current entitlement, throwing rather than collapsing a failure into `.notSubscribed`.
    func refreshEntitlement() async throws -> Entitlement
}

extension PurchaseClient {
    /// Throwing entitlement read for callers that must distinguish failure from
    /// `.notSubscribed`, falling back to the non-throwing answer for clients that cannot
    /// fail.
    ///
    /// The dynamic cast is deliberate: `PurchaseClient` is the published contract and this
    /// refinement is additive, so conformers written against the original protocol keep
    /// working unchanged.
    func refreshedEntitlement() async throws -> Entitlement {
        guard let refreshing = self as? any EntitlementRefreshing else {
            return await entitlement()
        }
        return try await refreshing.refreshEntitlement()
    }
}
