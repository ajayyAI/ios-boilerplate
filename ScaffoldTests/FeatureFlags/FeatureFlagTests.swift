//
//  FeatureFlagTests.swift
//  ScaffoldTests
//

import Testing
@testable import Scaffold

/// The app module defaults to `MainActor` isolation; the test target opts in.
@MainActor
struct FeatureFlagTests {
    /// The unconfigured clone, an offline device and a cold launch all read the same
    /// answer: the default written next to the flag.
    @Test func `the no-op client answers every flag with its default`() {
        let client = NoOpFeatureFlagClient()

        for flag in FeatureFlag.allCases {
            #expect(client.isEnabled(flag) == flag.defaultValue)
            #expect(client.payload(for: flag) == nil)
        }
    }
}
