# Widgets

Home and Lock Screen widgets read data the app wrote. They run in a separate process,
so the only storage both can see is an App Group container.

## 1. App Group

1. developer.apple.com → Identifiers → App Groups → `group.<your bundle id>`.
2. `Config/Shared.xcconfig`: `APP_GROUP_ID = group.com.example.MyApp`.
3. `MyApp/MyApp.entitlements`: add

   ```xml
   <key>com.apple.security.application-groups</key>
   <array><string>$(APP_GROUP_ID)</string></array>
   ```

`AppEnvironment` already builds `UserDefaultsKeyValueStore(appGroupID:)`, so from this
point every `KeyValueStore` write lands in the shared suite. Existing values in the
standard defaults are not migrated; do that once at launch if you ship this to users
who already have data.

## 2. Extension target

File → New → Target → Widget Extension. Name it `MyAppWidgets`. Untick "Include Live
Activity" and "Include Configuration App Intent" unless you need them today.

Give the extension the same App Group entitlement, and set its `PRODUCT_BUNDLE_IDENTIFIER`
to `$(APP_BUNDLE_ID).widgets` so it follows the xcconfig.

## 3. Read the store

In the widget's timeline provider:

```swift
let store = UserDefaultsKeyValueStore(appGroupID: "group.com.example.MyApp")
let value = store.value(forKey: .someKey)
```

Share `KeyValueStore.swift`, `UserDefaultsKeyValueStore.swift` and the `StorageKey`
extensions with the extension target (File Inspector → Target Membership). Keep the
extension free of vendor SDKs: it has a tight memory budget and no need for analytics.

## 4. Refresh

After the app writes something the widget shows:

```swift
import WidgetKit
WidgetCenter.shared.reloadTimelines(ofKind: "MyAppWidget")
```

## 5. Ship

- Privacy: the extension needs its own `PrivacyInfo.xcprivacy` if it calls a
  required-reason API. Reading defaults through the store does (`CA92.1`).
- `build.yml` archives the whole scheme, so the extension is included once it is a
  dependency of the app target.
- Screenshots of widgets are optional on the App Store listing but reviewers reward them.
