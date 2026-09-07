//
//  PaywallGateViewModel.swift
//  Scaffold
//

import Foundation

/// Owns the entitlement decision behind `PaywallGate`.
///
/// Every path that can change entitlement — first load, retry, purchase, restore — ends in
/// the same `readEntitlement()` call. One read is the only thing that can produce
/// `.entitled`, which keeps the rule "content unlocks exactly when a successful read said
/// so" in a single place instead of spread across four callbacks.
@MainActor
@Observable
final class PaywallGateViewModel {
    private(set) var state: PaywallGateViewState = .loading

    /// When true, dismissing the paywall returns to the upsell screen rather than to the
    /// app. See `isHardPaywallActive` for the one case where it is ignored.
    let hardPaywall: Bool

    /// False when the build carries no store configuration, so there is no paywall to
    /// present. This affects presentation only — entitlement is unchanged and gated content
    /// stays locked either way.
    let isPaywallAvailable: Bool

    private let purchases: any PurchaseClient

    init(purchases: any PurchaseClient, hardPaywall: Bool = false, isPaywallAvailable: Bool = true) {
        self.purchases = purchases
        self.hardPaywall = hardPaywall
        self.isPaywallAvailable = isPaywallAvailable
    }

    /// A hard paywall with nothing to sell is a dead end, so an unconfigured build gets the
    /// dismissible presentation instead. This is a concession on *navigation*, not on
    /// access: `state` can still only be `.entitled` after a successful read.
    var isHardPaywallActive: Bool {
        hardPaywall && isPaywallAvailable
    }

    /// What the gate calls from `.task`. That closure re-runs whenever the view's identity
    /// changes, and re-reading on every appearance would flash a spinner over content the
    /// user has already unlocked.
    func loadIfNeeded() async {
        guard state == .loading else { return }
        await load()
    }

    func load() async {
        state = .loading
        await readEntitlement()
    }

    func retry() async {
        await load()
    }

    /// Called when the paywall reports a completed purchase. The callback carries a
    /// `CustomerInfo`, but trusting it would let the SDK decide entitlement behind the
    /// client's back, and the identifier mapping lives in the client.
    func purchaseCompleted() async {
        await readEntitlement()
    }

    /// Called when the paywall reports a completed restore. Completion means the request
    /// succeeded, not that anything was restored, so the answer still comes from a read.
    func restoreCompleted() async {
        await readEntitlement()
    }

    /// The gate's own restore affordance, for the screen shown when the paywall is dismissed.
    func restore() async {
        state = .loading
        do {
            try await purchases.restore()
        } catch {
            state = .failed(PresentableError(error), retryable: false)
            return
        }
        // Re-reads rather than using the restore's return value so purchase, restore and
        // retry all converge on one entitlement read.
        await readEntitlement()
    }

    private func readEntitlement() async {
        do {
            switch try await purchases.refreshedEntitlement() {
            case let .subscribed(expiresAt):
                state = .entitled(expiresAt: expiresAt)
            case .notSubscribed:
                state = .notEntitled
            }
        } catch {
            // Fail closed. A read that unlocked the app on error would hand the product to
            // anyone willing to go offline.
            state = .failed(PresentableError(error), retryable: true)
        }
    }
}

extension PaywallGateViewModel {
    /// Seeds a view model in a fixed state for `#Preview`.
    static func preview(
        state: PaywallGateViewState,
        hardPaywall: Bool = false,
        isPaywallAvailable: Bool = true,
    ) -> PaywallGateViewModel {
        let viewModel = PaywallGateViewModel(
            purchases: NoOpPurchaseClient(),
            hardPaywall: hardPaywall,
            isPaywallAvailable: isPaywallAvailable,
        )
        viewModel.state = state
        return viewModel
    }
}
