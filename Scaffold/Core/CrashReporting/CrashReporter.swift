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
}

/// Used whenever no DSN is configured. Keeps a fresh clone green.
struct NoOpCrashReporter: CrashReporter {
    func start() {}
    func capture(_ error: Error) {}
    func addBreadcrumb(_ message: String) {}
    func setUser(id: String?) {}
}
