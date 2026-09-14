# HealthKit

Follows the starter's integration rule: a protocol and a no-op in `Core/`, a branch in
`AppEnvironment`, and a test that the unconfigured build selects the no-op.

## 1. Capability and strings

Signing & Capabilities → HealthKit. Then in `Info.plist`:

```xml
<key>NSHealthShareUsageDescription</key>
<string>Reads your step count to show daily progress.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>Saves water you log so other apps can see it.</string>
```

Say exactly what is read and why. Review rejects vague strings.

## 2. Protocol

`Core/Health/HealthStore.swift`:

```swift
protocol HealthStore: Sendable {
    func requestAuthorization() async throws
    func steps(on day: Date) async throws -> Int
}

struct NoOpHealthStore: HealthStore {
    func requestAuthorization() async throws {}
    func steps(on day: Date) async throws -> Int { 0 }
}
```

`Core/Health/HKHealthStoreAdapter.swift` wraps `HKHealthStore`. Guard on
`HKHealthStore.isHealthDataAvailable()`, which is false on iPad and in most
simulators, and select the no-op there so previews and tests never touch HealthKit.

## 3. Wire it

Add `healthStore` to `AppEnvironment` and `Container`, and the selection test to
`AppEnvironmentTests`.

## 4. Privacy

Health data must never reach Sentry or PostHog. Never put a reading in an event
property, a breadcrumb or a log line; the closed `AnalyticsEvent` set makes that a
review-time check. In App Store Connect, declare Health & Fitness → Health, linked to
the user if you sync it to your backend.

## 5. Background delivery

`HKObserverQuery` plus `enableBackgroundDelivery` wakes the app on new samples. Add
Background Modes → Background fetch, and keep the handler short: read, write to the
store, reload widget timelines, done.
