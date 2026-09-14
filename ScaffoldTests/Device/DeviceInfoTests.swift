//
//  DeviceInfoTests.swift
//  ScaffoldTests
//

import Foundation
import Testing
@testable import Scaffold

/// `DeviceInfo` has two halves worth guarding: a pure formatter, and a `uname` read that
/// slices a padded C char array. The formatter is asserted exactly; the syscall can only be
/// asserted on shape, since the value differs per simulator and per host machine.
struct DeviceInfoTests {
    private static let sample = DeviceInfo(
        appName: "Example",
        appVersion: "1.2.0",
        buildNumber: "42",
        systemName: "iOS",
        systemVersion: "18.0",
        hardwareIdentifier: "iPhone17,1",
    )

    @Test func `user agent joins every field in header order`() {
        #expect(Self.sample.userAgent == "Example/1.2.0 (42; iOS/18.0; iPhone17,1)")
    }

    /// The `machine` tuple is NUL-padded to its fixed width. Cutting at the wrong place
    /// yields a string that looks right in a debugger but carries trailing NULs into every
    /// header it is interpolated into.
    @Test func `hardware identifier carries no padding`() {
        let identifier = DeviceInfo.hardwareIdentifier()

        #expect(!identifier.isEmpty)
        #expect(!identifier.contains("\0"))
        #expect(identifier == identifier.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    @Test func `current populates every field`() {
        let info = DeviceInfo.current()

        #expect(!info.appName.isEmpty)
        #expect(!info.appVersion.isEmpty)
        #expect(!info.buildNumber.isEmpty)
        #expect(!info.systemName.isEmpty)
        #expect(!info.systemVersion.isEmpty)
        #expect(!info.hardwareIdentifier.isEmpty)
    }

    /// Info.plist lookups are optional at every step, so a misconfigured app gets a marker
    /// rather than a trap. An empty directory is a valid `Bundle` with no keys at all.
    @Test func `absent info plist keys read as unknown`() throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let info = try DeviceInfo.current(bundle: #require(Bundle(url: directory)))

        #expect(info.appName == "unknown")
        #expect(info.appVersion == "unknown")
        #expect(info.buildNumber == "unknown")
    }
}
