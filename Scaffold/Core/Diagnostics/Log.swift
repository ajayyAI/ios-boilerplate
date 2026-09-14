//
//  Log.swift
//  Scaffold
//

import Foundation
import os

/// One `Logger` per subsystem area, all under the app's bundle identifier.
///
/// `os.Logger` is the platform's structured logger: zero cost when nothing is
/// listening, visible in Console.app and Xcode, and interpolated values are redacted
/// in release builds unless marked `privacy: .public`. There is nothing to add on
/// top of it, so this file only fixes the category names so they do not drift.
///
/// Logs are for developers reading a device. Anything a human needs to act on in
/// production goes through `CrashReporter.report(_:context:)`, which records a
/// breadcrumb and captures the error.
nonisolated enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "app"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let network = Logger(subsystem: subsystem, category: "network")
    static let purchases = Logger(subsystem: subsystem, category: "purchases")
    static let analytics = Logger(subsystem: subsystem, category: "analytics")
    static let storage = Logger(subsystem: subsystem, category: "storage")
}
