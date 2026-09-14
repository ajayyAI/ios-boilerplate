//
//  PaywallGateViewState.swift
//  Scaffold
//

import Foundation

/// What the paywall gate is currently showing.
///
/// Only `.entitled` renders gated content. `.loading` and `.failed` withhold it, and there
/// is deliberately no case meaning "probably entitled" — the absence of that case is what
/// stops an offline entitlement read from unlocking the product.
///
/// `Equatable` for the same reason as `HomeViewState`: the `@Observable` macro's generated
/// setter only skips redundant invalidations when it can compare the old and new value.
enum PaywallGateViewState: Equatable {
    case loading
    case entitled(expiresAt: Date?)
    case notEntitled
    /// `retryable` is false when repeating the same call cannot change the answer — a
    /// restore that already reached the store and came back empty. The gate then offers the
    /// paywall rather than a retry button, so neither branch dead-ends.
    case failed(PresentableError, retryable: Bool)

    /// Whether gated content may be shown. Exists so a caller — or a test — asks the
    /// question in one place instead of re-deriving it from the cases and getting it wrong.
    var isEntitled: Bool {
        if case .entitled = self {
            return true
        }
        return false
    }
}
