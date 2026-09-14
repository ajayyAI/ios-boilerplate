//
//  ReviewPrompterTests.swift
//  ScaffoldTests
//

import Foundation
import Testing
@testable import Scaffold

/// The prompt is the one moment the app asks the user for something back, so the
/// budget is pinned: never early, never often, never past Apple's ceiling.
@MainActor
struct ReviewPrompterTests {
    private let install = Date(timeIntervalSince1970: 1_800_000_000)

    private func prompter(_ store: InMemoryStore = InMemoryStore()) -> ReviewPrompter {
        let prompter = ReviewPrompter(store: store)
        prompter.recordLaunch(now: install)
        return prompter
    }

    private func days(_ count: Int) -> Date {
        install.addingTimeInterval(TimeInterval(count) * 86400)
    }

    @Test func `does not ask before any value moment`() {
        let prompter = prompter()

        #expect(prompter.shouldAsk(now: days(10)) == false)
    }

    @Test func `does not ask on install day even after value moments`() {
        let prompter = prompter()
        for _ in 0 ..< 5 {
            prompter.recordValueMoment()
        }

        #expect(prompter.shouldAsk(now: days(1)) == false)
    }

    @Test func `asks once the user has had value and a couple of days`() {
        let prompter = prompter()
        for _ in 0 ..< ReviewPrompter.requiredValueMoments {
            prompter.recordValueMoment()
        }

        #expect(prompter.shouldAsk(now: days(ReviewPrompter.minimumDaysSinceInstall)))
    }

    @Test func `waits between asks`() {
        let prompter = prompter()
        for _ in 0 ..< 5 {
            prompter.recordValueMoment()
        }
        prompter.recordAsked(now: days(3))

        #expect(prompter.shouldAsk(now: days(4)) == false)
        #expect(prompter.shouldAsk(now: days(3 + ReviewPrompter.minimumDaysBetweenAsks)))
    }

    @Test func `stops at the lifetime maximum`() {
        let prompter = prompter()
        for _ in 0 ..< 10 {
            prompter.recordValueMoment()
        }
        for ask in 0 ..< ReviewPrompter.maximumAsks {
            prompter.recordAsked(now: days(3 + ask * 30))
        }

        #expect(prompter.shouldAsk(now: days(365)) == false)
    }

    @Test func `recordLaunch keeps the first install date`() {
        let store = InMemoryStore()
        let prompter = ReviewPrompter(store: store)
        prompter.recordLaunch(now: install)
        prompter.recordLaunch(now: days(30))

        #expect(store.value(forKey: .reviewFirstLaunchDate) == install)
    }
}
