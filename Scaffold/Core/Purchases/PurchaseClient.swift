//
//  PurchaseClient.swift
//  Scaffold
//

import Foundation

/// Subscription entitlement and purchase state.
///
/// This protocol is the reason the paywall is testable: a real purchase cannot run
/// in CI, so every test drives entitlement through a fake conforming to this.
protocol PurchaseClient: Sendable {
    /// Configures the underlying SDK. Safe to call once at launch.
    func start()

    /// Current entitlement. Never throws; see `EntitlementRefreshing` for the read that can.
    func entitlement() async -> Entitlement

    /// Restores prior purchases for this Apple ID.
    @discardableResult
    func restore() async throws -> Entitlement
}

/// Whether the user currently has premium access.
///
/// `Equatable` so view state holding one can skip redundant invalidations.
enum Entitlement: Equatable, Sendable {
    case subscribed(expiresAt: Date?)
    case notSubscribed

    var isActive: Bool {
        if case .subscribed = self {
            return true
        }
        return false
    }
}

/// Used whenever no Superwall key is configured.
///
/// Reports `notSubscribed` rather than granting access: an unconfigured build must
/// not silently unlock paid features. `HARD_PAYWALL` behaviour is decided by the
/// gate, not here.
struct NoOpPurchaseClient: PurchaseClient {
    func start() {}
    func entitlement() async -> Entitlement {
        .notSubscribed
    }

    @discardableResult
    func restore() async throws -> Entitlement {
        .notSubscribed
    }
}
