//
//  RevenueCatPurchaseClient.swift
//  Scaffold
//

import Foundation
import RevenueCat

/// `PurchaseClient` backed by RevenueCat.
///
/// Constructed only when `AppConfig.revenueCatAPIKey` is present; without a key the
/// composition root keeps `NoOpPurchaseClient` and this type is never instantiated, so an
/// unconfigured clone never reaches the SDK.
final nonisolated class RevenueCatPurchaseClient: EntitlementRefreshing, Sendable {
    /// The entitlement identifier RevenueCat's own onboarding creates. Override it to match
    /// whatever the dashboard actually calls the paid tier — a mismatch here reads as "no
    /// subscribers", which looks exactly like a working paywall nobody buys.
    static let defaultEntitlementIdentifier = "premium"

    private let apiKey: String
    private let entitlementIdentifier: String

    init(apiKey: String, entitlementIdentifier: String = RevenueCatPurchaseClient.defaultEntitlementIdentifier) {
        self.apiKey = apiKey
        self.entitlementIdentifier = entitlementIdentifier
    }

    /// Configuration happens here rather than in `init` so tests and previews can construct
    /// the client without booting the SDK: `Purchases.configure` installs a process-wide
    /// singleton that cannot be torn down again.
    func start() {
        // Re-configuring replaces that singleton and restarts its network work. The app
        // delegate, a scene relaunch and a preview can all reach this in one process.
        guard !Purchases.isConfigured else { return }
        Purchases.configure(withAPIKey: apiKey)
    }

    /// Collapses a failed read to `.notSubscribed` because the protocol cannot throw.
    /// Callers that must tell "offline" from "not a subscriber" — the paywall gate being
    /// the one that matters — go through `refreshEntitlement()` instead.
    func entitlement() async -> Entitlement {
        await (try? refreshEntitlement()) ?? .notSubscribed
    }

    func refreshEntitlement() async throws -> Entitlement {
        guard Purchases.isConfigured else { return .notSubscribed }
        let customerInfo = try await Purchases.shared.customerInfo()
        return entitlement(in: customerInfo)
    }

    @discardableResult
    func restore() async throws -> Entitlement {
        guard Purchases.isConfigured else { return .notSubscribed }
        let customerInfo = try await Purchases.shared.restorePurchases()
        return entitlement(in: customerInfo)
    }

    func logIn(userID: String) async throws {
        guard Purchases.isConfigured else { return }
        _ = try await Purchases.shared.logIn(userID)
    }

    func logOut() async throws {
        guard Purchases.isConfigured else { return }
        _ = try await Purchases.shared.logOut()
    }

    /// `entitlements.active` is already filtered to entitlements RevenueCat considers live,
    /// so presence in the dictionary is the whole test.
    private func entitlement(in customerInfo: CustomerInfo) -> Entitlement {
        guard let active = customerInfo.entitlements.active[entitlementIdentifier] else {
            return .notSubscribed
        }
        return .subscribed(expiresAt: active.expirationDate)
    }
}
