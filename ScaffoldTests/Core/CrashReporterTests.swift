//
//  CrashReporterTests.swift
//  ScaffoldTests
//

import Foundation
import Testing
@testable import Scaffold

/// `report(_:context:)` is the funnel every caught error goes through, so what it
/// forwards and what it drops is pinned here.
@MainActor
struct CrashReporterTests {
    @Test func `a caught error is captured with a breadcrumb naming where it happened`() {
        let spy = SpyCrashReporter()

        spy.report(ScaffoldError(message: "boom"), context: "Home.refresh")

        #expect(spy.breadcrumbs == ["Home.refresh"])
        #expect(spy.captured.count == 1)
    }

    @Test func `cancellation is not a defect and is not captured`() {
        let spy = SpyCrashReporter()

        spy.report(CancellationError(), context: "Home.refresh")
        spy.report(URLError(.cancelled), context: "Home.refresh")

        #expect(spy.captured.isEmpty)
        #expect(spy.breadcrumbs.isEmpty)
    }

    @Test func `a timed-out request is still captured`() {
        let spy = SpyCrashReporter()

        spy.report(URLError(.timedOut), context: "Home.refresh")

        #expect(spy.captured.count == 1)
    }
}

/// Records calls. A class rather than a struct so the funnel's extension method, which
/// takes `self` by value, still writes somewhere the test can read.
final class SpyCrashReporter: CrashReporter, @unchecked Sendable {
    private(set) var captured: [Error] = []
    private(set) var breadcrumbs: [String] = []

    func start() {}
    func capture(_ error: Error) {
        captured.append(error)
    }

    func addBreadcrumb(_ message: String) {
        breadcrumbs.append(message)
    }

    func setUser(id: String?) {}
    func setTag(_ key: String, value: String?) {}
}
