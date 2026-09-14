//
//  PaywallGate.swift
//  Scaffold
//

import RevenueCat
import RevenueCatUI
import SwiftUI

/// Wraps content that requires an active subscription.
///
/// Four behaviours are why this is a reusable type rather than an `if` around a view:
///
/// - Gated content renders only in `.entitled`. A failed entitlement read shows a retry,
///   never the content. RevenueCatUI's own `presentPaywallIfNeeded` documents the opposite
///   choice — "if loading the `CustomerInfo` fails, the paywall won't be displayed" — which
///   means an offline device gets the paid experience for free.
/// - A failure offers a way forward instead of dead-ending.
/// - `hardPaywall` sends a dismissal back to the upsell screen rather than into the app.
/// - Entitlement is read through `PurchaseClient`, never `Purchases.shared`, so the whole
///   decision is testable without the SDK.
///
/// Wrapping the entire app in a `hardPaywall` gate requires a configured API key; with none
/// there is nothing to sell and nothing underneath, so the gate falls back to the
/// dismissible presentation. The template does not wrap its root view.
struct PaywallGate<Content: View>: View {
    @State private var viewModel: PaywallGateViewModel
    @State private var isPaywallPresented = false
    @Environment(\.dismiss) private var dismiss

    private let content: () -> Content

    init(viewModel: PaywallGateViewModel, @ViewBuilder content: @escaping () -> Content) {
        _viewModel = State(initialValue: viewModel)
        self.content = content
    }

    var body: some View {
        PaywallGateStateView(
            state: viewModel.state,
            isPaywallAvailable: viewModel.isPaywallAvailable,
            showPaywall: { isPaywallPresented = true },
            retry: { await viewModel.retry() },
            restore: { await viewModel.restore() },
            content: content,
        )
        .task { await viewModel.loadIfNeeded() }
        .onChange(of: viewModel.state, initial: true) { _, state in
            // Presentation follows state rather than a tap: a purchase completing inside the
            // paywall closes it, and a failed read replaces it with the retry screen instead
            // of leaving a paywall the user cannot act on.
            isPaywallPresented = state == .notEntitled && viewModel.isPaywallAvailable
        }
        .modifier(
            PaywallPresentation(
                isPresented: $isPaywallPresented,
                isHardPaywall: viewModel.isHardPaywallActive,
                onDismiss: paywallDismissed,
                paywall: { PaywallSheet(viewModel: viewModel) },
            ),
        )
        .accessibilityIdentifier("PaywallGate")
    }

    private func paywallDismissed() {
        // A hard paywall lands on the upsell screen underneath and stays there. Falling
        // through to `content` is impossible by construction, but leaving the gate would
        // drop the user into whatever presented it — which for a hard paywall is the app.
        guard !viewModel.isHardPaywallActive else { return }
        dismiss()
    }
}

/// Renders one state. A separate `View` type rather than a computed property so it forms
/// its own invalidation boundary and takes only the state it reads.
private struct PaywallGateStateView<Content: View>: View {
    let state: PaywallGateViewState
    let isPaywallAvailable: Bool
    let showPaywall: () -> Void
    let retry: () async -> Void
    let restore: () async -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        switch state {
        case .loading:
            ProgressView()
                .controlSize(.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("paywallGateLoading")
        case .entitled:
            content()
        case .notEntitled:
            PaywallUpsellView(isPaywallAvailable: isPaywallAvailable, showPaywall: showPaywall, restore: restore)
        case let .failed(error, retryable):
            PaywallGateFailureView(error: error, retryable: retryable, retry: retry, showPaywall: showPaywall)
        }
    }
}

/// The floor of the gate: shown beneath the paywall and after it is dismissed. For a hard
/// paywall there is nothing below this.
private struct PaywallUpsellView: View {
    @Environment(\.theme) private var theme

    let isPaywallAvailable: Bool
    let showPaywall: () -> Void
    let restore: () async -> Void

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            Image(systemName: "lock.fill")
                .font(.largeTitle)
                .foregroundStyle(theme.color.accent)

            Text("Premium feature")
                .font(theme.font.sectionTitle)
                .foregroundStyle(theme.color.textPrimary)

            if isPaywallAvailable {
                Text("Subscribe to unlock this.")
                    .font(theme.font.body)
                    .foregroundStyle(theme.color.textSecondary)

                VStack(spacing: theme.spacing.sm) {
                    Button("See plans", action: showPaywall)
                        .buttonStyle(.primary)
                        .accessibilityIdentifier("seePlansButton")

                    AsyncButton("Restore purchases") {
                        await restore()
                    }
                    .buttonStyle(.secondary)
                    .accessibilityIdentifier("restorePurchasesButton")
                }
                .padding(.top, theme.spacing.sm)
            } else {
                // The unconfigured clone. Premium stays locked — an absent key must never
                // read as "everyone is a subscriber" — but the developer looking at this is
                // usually the one who has to fix it, so say what is missing. The key goes in
                // `Config/Secrets.xcconfig`; see `docs/configuration.md`.
                Text("Purchases aren't available in this build.")
                    .font(theme.font.body)
                    .foregroundStyle(theme.color.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(theme.spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.color.background)
        .accessibilityIdentifier("paywallUpsell")
    }
}

/// Shown when the entitlement read failed. Never renders gated content: the user might be a
/// subscriber, and might equally be someone in airplane mode.
private struct PaywallGateFailureView: View {
    @Environment(\.theme) private var theme

    let error: PresentableError
    let retryable: Bool
    let retry: () async -> Void
    let showPaywall: () -> Void

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(theme.color.danger)

            Text("Couldn't check your subscription")
                .font(theme.font.sectionTitle)
                .foregroundStyle(theme.color.textPrimary)
                .multilineTextAlignment(.center)

            Text(error.message)
                .font(theme.font.body)
                .foregroundStyle(theme.color.textSecondary)
                .multilineTextAlignment(.center)

            if retryable {
                AsyncButton("Try again") {
                    await retry()
                }
                .buttonStyle(.primary)
                .accessibilityIdentifier("retryEntitlementButton")
                .padding(.top, theme.spacing.sm)
            } else {
                Button("See plans", action: showPaywall)
                    .buttonStyle(.primary)
                    .accessibilityIdentifier("seePlansButton")
                    .padding(.top, theme.spacing.sm)
            }
        }
        .padding(theme.spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.color.background)
        .accessibilityIdentifier("paywallGateFailure")
    }
}

/// The remote-configured paywall.
///
/// This is the only place in the feature that touches the SDK, and it never produces
/// entitlement — both callbacks hand back to the view model, which re-reads through
/// `PurchaseClient`. `PaywallView` resolves `Purchases.shared`, which traps with
/// `fatalError` when the SDK was never configured, so it is built only behind
/// `isConfigured`.
private struct PaywallSheet: View {
    let viewModel: PaywallGateViewModel

    var body: some View {
        if Purchases.isConfigured {
            PaywallView(displayCloseButton: true)
                .onPurchaseCompleted { _ in
                    Task { await viewModel.purchaseCompleted() }
                }
                .onRestoreCompleted { _ in
                    Task { await viewModel.restoreCompleted() }
                }
        } else {
            PaywallUnavailableView()
        }
    }
}

private struct PaywallUnavailableView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        Text("Purchases aren't available in this build.")
            .font(theme.font.body)
            .foregroundStyle(theme.color.textSecondary)
            .multilineTextAlignment(.center)
            .padding(theme.spacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.color.background)
            .accessibilityIdentifier("paywallUnavailable")
    }
}

/// Chooses the presentation style. A hard paywall covers the screen; a soft one is a sheet
/// the user can swipe away.
private struct PaywallPresentation<PaywallContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let isHardPaywall: Bool
    let onDismiss: () -> Void
    @ViewBuilder let paywall: () -> PaywallContent

    /// Branching in a `body` normally churns view identity, which is safe here only because
    /// `isHardPaywall` is fixed for the lifetime of a gate.
    func body(content: Content) -> some View {
        if isHardPaywall {
            content.fullScreenCover(isPresented: $isPresented, onDismiss: onDismiss, content: paywall)
        } else {
            content.sheet(isPresented: $isPresented, onDismiss: onDismiss, content: paywall)
        }
    }
}

#Preview("Entitled") {
    PaywallGate(viewModel: .preview(state: .entitled(expiresAt: nil))) {
        Text(verbatim: "Premium content")
    }
}

#Preview("Not entitled") {
    PaywallGate(viewModel: .preview(state: .notEntitled)) {
        Text(verbatim: "Premium content")
    }
}

#Preview("Not configured") {
    PaywallGate(viewModel: .preview(state: .notEntitled, hardPaywall: true, isPaywallAvailable: false)) {
        Text(verbatim: "Premium content")
    }
}

#Preview("Failed") {
    PaywallGate(
        viewModel: .preview(state: .failed(
            PresentableError(message: "The Internet connection appears to be offline."),
            retryable: true,
        )),
    ) {
        Text(verbatim: "Premium content")
    }
}
