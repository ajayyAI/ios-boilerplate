//
//  SuperwallPurchaseClient.swift
//  Scaffold
//

import Foundation
import SuperwallKit

/// `PurchaseClient` backed by Superwall, which owns purchasing, restores and entitlement
/// state end to end — there is no custom `PurchaseController`.
///
/// Constructed only when `AppConfig.superwallAPIKey` is present; without a key the
/// composition root keeps `NoOpPurchaseClient` and this type is never instantiated, so an
/// unconfigured clone never reaches the SDK.
///
/// Main-actor isolated, unlike the other vendor clients: `Superwall` is not `Sendable` and
/// publishes its state for the main thread, so reading it from anywhere else is a race the
/// compiler would otherwise have to be talked out of.
final class SuperwallPurchaseClient: EntitlementRefreshing {
    /// How long a read waits for `.unknown` to resolve before it is reported as a failure.
    nonisolated static let defaultStatusTimeout: Duration = .seconds(10)

    private let apiKey: String
    private let entitlementIdentifier: String?
    private let statusTimeout: Duration

    /// - Parameter entitlementIdentifier: The dashboard entitlement that unlocks the gate.
    ///   `nil` accepts any active entitlement, which is right for a single-tier app and
    ///   cannot silently mismatch the dashboard. An app with tiers passes the identifier —
    ///   a typo there reads as "no subscribers", which looks exactly like a working paywall
    ///   nobody buys.
    nonisolated init(
        apiKey: String,
        entitlementIdentifier: String? = nil,
        statusTimeout: Duration = SuperwallPurchaseClient.defaultStatusTimeout,
    ) {
        self.apiKey = apiKey
        self.entitlementIdentifier = entitlementIdentifier
        self.statusTimeout = statusTimeout
    }

    /// Configuration happens here rather than in `init` so tests and previews can construct
    /// the client without booting the SDK: `Superwall.configure` installs a process-wide
    /// singleton that cannot be torn down again, and starts preloading paywalls at once.
    func start() {
        // The app delegate, a scene relaunch and a preview can all reach this in one process.
        guard !Superwall.isInitialized else { return }
        let options = SuperwallOptions()
        #if !DEBUG
            options.logging.level = .warn
        #endif
        Superwall.configure(apiKey: apiKey, options: options)
    }

    /// Collapses a failed read to `.notSubscribed` because the protocol cannot throw.
    /// Callers that must tell "offline" from "not a subscriber" — the paywall gate being
    /// the one that matters — go through `refreshEntitlement()` instead.
    func entitlement() async -> Entitlement {
        await (try? refreshEntitlement()) ?? .notSubscribed
    }

    /// Superwall reports `.unknown` until it has both the device's transactions and the
    /// product-to-entitlement mapping from its config. A first launch with no network can
    /// stay there indefinitely, and `.unknown` is not "not a subscriber" — so it is waited
    /// on, then thrown, never mapped to an answer.
    func refreshEntitlement() async throws -> Entitlement {
        guard Superwall.isInitialized else { return .notSubscribed }
        let identifier = entitlementIdentifier
        if let known = Self.entitlement(for: Superwall.shared.subscriptionStatus, identifier: identifier) {
            return known
        }

        let read = Task { () -> Entitlement? in
            for await status in Superwall.shared.$subscriptionStatus.values {
                if let known = Self.entitlement(for: status, identifier: identifier) {
                    return known
                }
            }
            // Cancelling the task ends the publisher's sequence, which lands here.
            return nil
        }
        let timeout = statusTimeout
        let deadline = Task {
            try? await Task.sleep(for: timeout)
            read.cancel()
        }
        defer { deadline.cancel() }

        let resolved = await withTaskCancellationHandler {
            await read.value
        } onCancel: {
            read.cancel()
        }
        try Task.checkCancellation()
        guard let resolved else {
            Log.purchases.error("Subscription status still unknown after \(timeout)")
            throw ScaffoldError(message: "We couldn't confirm your subscription. Check your connection and try again.")
        }
        return resolved
    }

    /// `.restored` means the request succeeded, not that anything came back, so the answer
    /// is still a read. The SDK shows its own alert when a restore finds nothing.
    @discardableResult
    func restore() async throws -> Entitlement {
        guard Superwall.isInitialized else { return .notSubscribed }
        switch await Superwall.shared.restorePurchases() {
        case .restored:
            return try await refreshEntitlement()
        case let .failed(error):
            throw error ?? ScaffoldError(message: "Your purchases couldn't be restored. Please try again.")
        }
    }

    func logIn(userID: String) async throws {
        guard Superwall.isInitialized else { return }
        Superwall.shared.identify(userId: userID)
    }

    /// Rotates the anonymous identity and clears paywall assignments. Entitlement follows
    /// the Apple ID rather than the account, so a subscriber stays subscribed after this.
    func logOut() async throws {
        guard Superwall.isInitialized else { return }
        Superwall.shared.reset()
    }

    /// `nil` for `.unknown`: the one status that is not an answer.
    ///
    /// Pure and `nonisolated` so the mapping the gate's safety rests on is testable
    /// without configuring the SDK.
    nonisolated static func entitlement(
        for status: SubscriptionStatus,
        identifier: String?,
    ) -> Entitlement? {
        switch status {
        case .unknown:
            return nil
        case .inactive:
            return .notSubscribed
        case let .active(entitlements):
            let matching = entitlements.filter { entitlement in
                entitlement.isActive && (identifier == nil || entitlement.id == identifier)
            }
            guard !matching.isEmpty else { return .notSubscribed }
            // A lifetime unlock has no expiry, and it outranks any dated entitlement
            // held alongside it.
            let expiries = matching.map(\.expiresAt)
            return .subscribed(expiresAt: expiries.contains(nil) ? nil : expiries.compactMap(\.self).max())
        }
    }
}
