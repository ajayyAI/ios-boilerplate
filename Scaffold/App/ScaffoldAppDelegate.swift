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
        Container.shared.crashReporter().start()
        Container.shared.purchaseClient().start()
        Container.shared.analyticsClient().track(AnalyticsEvent(.appLaunched))
        return true
    }
}
