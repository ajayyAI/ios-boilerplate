# Deep links

Universal links (`https://`) for anything that reaches users; a custom scheme only for
app-to-app handoff. Both arrive through the same SwiftUI modifier.

## 1. Associated domain

Signing & Capabilities → Associated Domains → `applinks:example.com`. Host
`/.well-known/apple-app-site-association` on that domain with your team ID and bundle
ID. Apple's CDN caches it; changes take up to a day.

## 2. Parse, never trust

`App/Navigation/DeepLink.swift`:

```swift
enum DeepLink: Equatable {
    case home
    case paywall

    /// `nil` for anything unrecognised. A URL is user input.
    init?(url: URL) {
        switch url.pathComponents.dropFirst().first {
        case nil, "": self = .home
        case "premium": self = .paywall
        default: return nil
        }
    }
}
```

Reject rather than guess. An unknown path lands on Home, not on the closest match.

## 3. Handle

In `RootView`:

```swift
.onOpenURL { url in
    guard let link = DeepLink(url: url) else { return }
    router.open(link)
}
```

Where `router` is whatever navigation state the app owns. Keep the mapping from
`DeepLink` to screens in one place; that is the file to read when a link goes wrong.

## 4. Hold links that arrive too early

A link tapped before onboarding finishes should open *after* it, not interrupt it.
Store the pending `DeepLink` in `@State` on the root and consume it when the
onboarding flag flips.

## 5. Track

Add `deepLinkOpened` to `AnalyticsEvent.Name` with the route as a property. It is the
only way to know which links people actually use.
