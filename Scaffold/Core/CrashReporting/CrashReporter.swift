//
//  CrashReporter.swift
//  Scaffold
//

import Foundation

/// A crash and error sink.
protocol CrashReporter: Sendable {
    func start()
    func capture(_ error: Error)
    func addBreadcrumb(_ message: String)
    func setUser(id: String?)
    /// Attaches a searchable key to every subsequent event. `nil` removes it.
    func setTag(_ key: String, value: String?)
}

extension CrashReporter {
    /// The one way a caught error leaves the app.
    ///
    /// View models catch errors to render them, and a caught error is invisible to the
    /// crash reporter unless something forwards it. This is that something: a breadcrumb
    /// saying where it happened, then the capture. Cancellation is skipped because a
    /// user leaving a screen mid-request is not a defect.
    func report(_ error: Error, context: String) {
        guard !error.isCancellation else { return }
        Log.app.error("\(context, privacy: .public): \(error.localizedDescription, privacy: .public)")
        addBreadcrumb(context)
        capture(error)
    }
}

extension Error {
    /// `Task` cancellation and a cancelled `URLSession` request. Both mean the work was
    /// abandoned on purpose, not that it failed.
    var isCancellation: Bool {
        if self is CancellationError {
            return true
        }
        if let urlError = self as? URLError, urlError.code == .cancelled {
            return true
        }
        return false
    }
}

/// Used whenever no DSN is configured. Keeps a fresh clone green.
struct NoOpCrashReporter: CrashReporter {
    func start() {}
    func capture(_ error: Error) {}
    func addBreadcrumb(_ message: String) {}
    func setUser(id: String?) {}
    func setTag(_ key: String, value: String?) {}
}
