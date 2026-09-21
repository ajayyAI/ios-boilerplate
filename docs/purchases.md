# Purchases

Superwall owns the whole purchase path: StoreKit 2 transactions, restores, entitlement
state and the paywall itself. There is no custom `PurchaseController` and no
receipt-validation code in the app. The app's side is three small pieces:

| Piece | Where | Job |
|---|---|---|
| `PurchaseClient` | `Core/Purchases/` | The vendor-neutral seam. Tests and previews never see the SDK. |
| `SuperwallPurchaseClient` | `Core/Purchases/` | Maps Superwall's subscription status onto `Entitlement`. |
| `PaywallGate` | `Features/Paywall/` | Wraps paid content; presents the paywall for a `PaywallPlacement`. |

With `SUPERWALL_API_KEY` blank, `AppEnvironment` selects `NoOpPurchaseClient`: nobody is
entitled, the SDK is never configured, and no request leaves the device.

## Going live

1. **Dashboard.** Create the app at superwall.com and copy Settings → Keys → Public API
   Key into `SUPERWALL_API_KEY` in `Config/Secrets.xcconfig`.
2. **Products.** Add your App Store Connect product identifiers under Products and attach
   each to an entitlement. A single-tier app needs nothing more — the client accepts any
   active entitlement by default.
3. **Campaign.** Create a campaign, add the placement `premium_feature` (the raw value of
   `PaywallPlacement.premiumFeature`) and attach a paywall. Set the paywall's feature
   gating to **Gated**.
4. **Server notifications.** Connect App Store Server Notifications V2 in the dashboard so
   refunds, renewals and billing retries reach Superwall without the app being open.
5. **Test.** Attach a StoreKit configuration file to the scheme for local purchases.
   Webhooks and revenue tracking only fire from real sandbox purchases — TestFlight with a
   sandbox Apple ID — never from a StoreKit configuration file.

The paywall's design, copy, products, audience and experiments all live on the dashboard
and change without a release. The placement name is the only contract between the two.

## Gating content

```swift
PaywallGate(viewModel: PaywallGateViewModel(
    purchases: purchaseClient,
    crashReporter: crashReporter,
    isPaywallAvailable: environment.isPurchasingConfigured,
)) {
    PremiumContent()
}
```

Pass `hardPaywall: true` to present full screen and return to the upsell on dismissal
rather than to the app. Whether a paywall shows a close button is part of its design:
remove it in the editor for a paywall used behind a hard gate.

A second entry point gets its own case in `PaywallPlacement` and the same raw value in a
campaign. An app with tiers passes `entitlementIdentifier:` to `SuperwallPurchaseClient`
in `AppEnvironment`, so the gate unlocks on that tier only.

## Why the gate does its own read

Superwall's `register(placement:feature:)` runs the feature block whenever the campaign
says so — a non-gated paywall, a holdout group, or no audience match all let the user
through. That is the right tool for a soft upsell and the wrong default for content
someone pays for. The gate asks one question instead — is there an active entitlement —
and answers it fail-closed:

| Superwall status | Gate state | Shows |
|---|---|---|
| `.active`, matching entitlement | `.entitled` | The content |
| `.inactive` | `.notEntitled` | Upsell, then the paywall |
| `.unknown`, resolves within 10 s | whichever it resolves to | — |
| `.unknown` past the timeout | `.failed(retryable: true)` | Retry, never the content |

`.unknown` is the case that matters. The SDK needs both the device's transactions and
its own config to resolve a status, and a first launch with no network has neither. A
subscriber who has opened the app before resolves from cache with no round-trip.

A paywall the campaign skips, or one that fails to load, renders a message with a Close
button rather than an empty cover. Skips are logged; load failures go to the crash
reporter as `PaywallGate.presentPaywall`.

## Identity

Call `purchaseClient.logIn(userID:)` after sign-in and `logOut()` after sign-out. The
first ties paywall assignments and webhook events to your user ID; the second rotates
the anonymous identity. Entitlement follows the Apple ID, so neither changes access.

## Deliberately left to the app

- **Soft upsells.** For a feature that should stay usable when no paywall matches, call
  `Superwall.shared.register(placement:feature:)` from behind a new `PurchaseClient`
  method, not from a view.
- **Analytics forwarding.** Superwall measures its own paywall funnel. To mirror it into
  PostHog, implement `SuperwallDelegate.handleSuperwallEvent(withInfo:)` and map the
  events you need onto `AnalyticsEvent.Name` cases.
- **Webhooks, the Query API, web checkout.** Server-side or dashboard features; nothing in
  the app changes. Web checkout needs the [deep links recipe](recipes/deep-links.md).
