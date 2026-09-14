# Recipes

Capabilities the starter deliberately does not ship, because most apps need only some
of them, with the steps to add each one to an app built on it. Every recipe plugs into
a seam the starter already has, so it is a checklist, not a design exercise.

| Recipe | Seam it uses |
|---|---|
| [Widgets](widgets.md) | `APP_GROUP_ID` + `UserDefaultsKeyValueStore(appGroupID:)` |
| [Push notifications](push-notifications.md) | `ScaffoldAppDelegate`, `AnalyticsClient` |
| [HealthKit](healthkit.md) | `Core/` protocol + no-op, `AppEnvironment` |
| [Deep links](deep-links.md) | `RootView`, `.onOpenURL` |

Not here on purpose: **watchOS**. If an app needs it, it is a product decision large
enough to plan on its own.
