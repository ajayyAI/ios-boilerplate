# Push notifications

Start with APNs directly. A push provider (OneSignal, Firebase) is worth adding when
you need segmentation or a campaign UI, not before.

## 1. Capability

Signing & Capabilities → Push Notifications. Xcode adds `aps-environment` to
`MyApp.entitlements`. Also add Background Modes → Remote notifications if you send
silent pushes.

## 2. Ask at the right moment

Never on first launch. Ask after the user has done the thing the notification is about:

```swift
let center = UNUserNotificationCenter.current()
let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
```

Track the answer: add `notificationPermissionAnswered` to `AnalyticsEvent.Name` with a
`granted` property. The grant rate is the health metric for this flow.

## 3. Register and hand the token to your backend

In `ScaffoldAppDelegate`:

```swift
func application(_ application: UIApplication,
                 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let token = deviceToken.map { String(format: "%02x", $0) }.joined()
    // POST to your backend. The token is per install; store it against the user.
}
```

Call `UIApplication.shared.registerForRemoteNotifications()` after authorization is
granted.

## 4. Handle taps

Set `UNUserNotificationCenter.current().delegate` in `didFinishLaunching` and implement
`userNotificationCenter(_:didReceive:withCompletionHandler:)`. Treat the payload as
untrusted input: parse it into a typed route, and reuse the deep-link handling from
[deep-links.md](deep-links.md).

## 5. Sending

For a backend, the APNs HTTP/2 API with a `.p8` key is a few dozen lines in any
language. For manual testing, Xcode can drag an `.apns` file onto the simulator.
