//
//  PaywallGateTests.swift
//  ScaffoldTests
//

import Foundation
import Testing
@testable import Scaffold

/// The gate decides who gets the paid product, so the two failure modes worth naming are
/// asymmetric but both fatal: unlock without a subscription and the app is free; lock out a
/// subscriber whose network blipped and the refund arrives instead.
///
/// The app module defaults to `MainActor` isolation, so `PurchaseClient` is main-actor
/// isolated at the protocol surface. The test target has no such default, so it opts in.
@MainActor
struct PaywallGateTests {
    @Test func `starts in loading before the first read`() {
        let viewModel = PaywallGateViewModel(purchases: FakePurchaseClient())

        #expect(viewModel.state == .loading)
        #expect(viewModel.state.isEntitled == false)
    }

    @Test func `an active entitlement passes through to the content`() async {
        let expiry = Date(timeIntervalSince1970: 1_800_000_000)
        let viewModel = PaywallGateViewModel(
            purchases: FakePurchaseClient(results: [.success(.subscribed(expiresAt: expiry))]),
        )

        await viewModel.load()

        #expect(viewModel.state == .entitled(expiresAt: expiry))
        #expect(viewModel.state.isEntitled)
    }

    @Test func `no entitlement shows the paywall`() async {
        let viewModel = PaywallGateViewModel(purchases: FakePurchaseClient(results: [.success(.notSubscribed)]))

        await viewModel.load()

        #expect(viewModel.state == .notEntitled)
        #expect(viewModel.state.isEntitled == false)
    }

    /// The one that gives the product away if it regresses.
    @Test func `a failed read does not grant access`() async {
        let viewModel = PaywallGateViewModel(purchases: FakePurchaseClient(results: [.failure(offlineError)]))

        await viewModel.load()

        #expect(viewModel.state.isEntitled == false)
        #expect(viewModel.state == .failed(PresentableError(message: "Offline"), retryable: true))
    }

    /// The one that locks out paying users if it regresses.
    @Test func `retrying after a failure succeeds`() async {
        let client = FakePurchaseClient(results: [.failure(offlineError), .success(.subscribed(expiresAt: nil))])
        let viewModel = PaywallGateViewModel(purchases: client)

        await viewModel.load()
        #expect(viewModel.state.isEntitled == false)

        await viewModel.retry()

        #expect(viewModel.state == .entitled(expiresAt: nil))
        #expect(client.entitlementReadCount == 2)
    }

    @Test func `a failed read is retryable rather than a dead end`() async {
        let viewModel = PaywallGateViewModel(purchases: FakePurchaseClient(results: [.failure(offlineError)]))

        await viewModel.load()

        #expect(viewModel.state == .failed(PresentableError(message: "Offline"), retryable: true))
    }

    @Test func `entitlement is re-read after a restore`() async {
        let client = FakePurchaseClient(results: [.success(.notSubscribed)])
        client.restoreResult = .success(.subscribed(expiresAt: nil))
        let viewModel = PaywallGateViewModel(purchases: client)

        await viewModel.load()
        #expect(viewModel.state == .notEntitled)

        await viewModel.restore()

        #expect(viewModel.state == .entitled(expiresAt: nil))
        #expect(client.restoreCount == 1)
        // Two reads, not one: the gate re-reads instead of trusting the restore's return
        // value, so purchase, restore and retry all converge on the same decision.
        #expect(client.entitlementReadCount == 2)
    }

    @Test func `a completed purchase re-reads entitlement`() async {
        let client = FakePurchaseClient(results: [.success(.notSubscribed), .success(.subscribed(expiresAt: nil))])
        let viewModel = PaywallGateViewModel(purchases: client)

        await viewModel.load()
        #expect(viewModel.state == .notEntitled)

        await viewModel.purchaseCompleted()

        #expect(viewModel.state == .entitled(expiresAt: nil))
        #expect(client.entitlementReadCount == 2)
    }

    @Test func `a completed restore re-reads entitlement`() async {
        let client = FakePurchaseClient(results: [.success(.notSubscribed), .success(.subscribed(expiresAt: nil))])
        let viewModel = PaywallGateViewModel(purchases: client)

        await viewModel.load()

        await viewModel.restoreCompleted()

        #expect(viewModel.state == .entitled(expiresAt: nil))
    }

    @Test func `a failed restore does not grant access and is not retryable`() async {
        let client = FakePurchaseClient(results: [.success(.notSubscribed)])
        client.restoreResult = .failure(ScaffoldError(message: "No purchases"))
        let viewModel = PaywallGateViewModel(purchases: client)

        await viewModel.restore()

        #expect(viewModel.state.isEntitled == false)
        #expect(viewModel.state == .failed(PresentableError(message: "No purchases"), retryable: false))
    }

    @Test func `loadIfNeeded does not re-read once entitlement is known`() async {
        let client = FakePurchaseClient(results: [.success(.subscribed(expiresAt: nil))])
        let viewModel = PaywallGateViewModel(purchases: client)

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        #expect(client.entitlementReadCount == 1)
    }

    // MARK: The unconfigured clone

    @Test func `an unconfigured build locks premium rather than granting it`() async {
        let viewModel = PaywallGateViewModel(purchases: NoOpPurchaseClient(), isPaywallAvailable: false)

        await viewModel.load()

        #expect(viewModel.state == .notEntitled)
        #expect(viewModel.state.isEntitled == false)
    }

    /// `NoOpPurchaseClient` cannot fail, so it must not be dressed up as an error state the
    /// user is asked to retry forever.
    @Test func `an unconfigured build reports no entitlement rather than a failure`() async {
        let viewModel = PaywallGateViewModel(purchases: NoOpPurchaseClient())

        await viewModel.load()

        #expect(viewModel.state == .notEntitled)
    }

    @Test func `a hard paywall is downgraded when there is no paywall to show`() {
        let unconfigured = PaywallGateViewModel(
            purchases: NoOpPurchaseClient(),
            hardPaywall: true,
            isPaywallAvailable: false,
        )
        let configured = PaywallGateViewModel(
            purchases: FakePurchaseClient(),
            hardPaywall: true,
            isPaywallAvailable: true,
        )

        #expect(unconfigured.isHardPaywallActive == false)
        #expect(configured.isHardPaywallActive)
    }

    private var offlineError: ScaffoldError {
        ScaffoldError(message: "Offline")
    }
}

/// Drives entitlement without the SDK. The queue lets a test express "fails, then succeeds",
/// which is the shape of every retry case; the last element repeats once exhausted so a test
/// that only cares about the steady state says it once.
@MainActor
private final class FakePurchaseClient: EntitlementRefreshing {
    private(set) var entitlementReadCount = 0
    private(set) var restoreCount = 0
    var restoreResult: Result<Entitlement, Error> = .success(.notSubscribed)

    private var pending: [Result<Entitlement, Error>]
    private var current: Result<Entitlement, Error> = .success(.notSubscribed)

    init(results: [Result<Entitlement, Error>] = []) {
        pending = results
    }

    func start() {}

    func entitlement() async -> Entitlement {
        await (try? refreshEntitlement()) ?? .notSubscribed
    }

    func refreshEntitlement() async throws -> Entitlement {
        entitlementReadCount += 1
        if !pending.isEmpty {
            current = pending.removeFirst()
        }
        return try current.get()
    }

    @discardableResult
    func restore() async throws -> Entitlement {
        restoreCount += 1
        let entitlement = try restoreResult.get()
        // A real restore changes what the next read reports. Mirroring that is what lets the
        // re-read test distinguish "the gate read again" from "the gate trusted this value".
        pending.append(.success(entitlement))
        return entitlement
    }

    func logIn(userID: String) async throws {}

    func logOut() async throws {}
}
