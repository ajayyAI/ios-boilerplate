//
//  ScaffoldAppDelegate.swift
//  Scaffold
//

import FactoryKit
import UIKit

final class ScaffoldAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil,
    ) -> Bool {
        // Vendor SDKs start here rather than in their initialisers, so constructing the
        // composition root stays free of side effects and tests can build the real clients
        // without booting anything. With no keys configured these resolve to no-ops and
        // nothing starts at all.
        //
        // Order matters: the crash reporter goes first so a crash in any later start is
        // itself reported.
        let crashReporter = Container.shared.crashReporter()
        let analytics = Container.shared.analyticsClient()
        crashReporter.start()
        analytics.start()
        Container.shared.purchaseClient().start()
        Container.shared.reviewPrompter().recordLaunch()

        // No SDK links a Sentry issue to a PostHog person on iOS, so the join key is
        // set by hand. Searching Sentry by this tag finds the session replay and funnel
        // for the person who crashed.
        crashReporter.setTag("posthog.distinct_id", value: analytics.distinctID)
        analytics.track(AnalyticsEvent(.appLaunched))
        return true
    }
}
