//
//  ReviewPrompter.swift
//  Scaffold
//

import Foundation

/// Decides when to ask for an App Store rating.
///
/// The system caps prompts at three per year and may show none; what it does not do is
/// stop an app from *asking* at the wrong moment. This type holds the budget: never on
/// the first day, never twice in a fortnight, never more than three times, and only
/// after the user has done something worth rating. Asking on a value moment is what
/// separates a five-star prompt from a one-star review.
///
/// The decision is pure so it is testable; the actual prompt is SwiftUI's
/// `@Environment(\.requestReview)`, called from a view when ``shouldAsk`` is true.
nonisolated struct ReviewPrompter: Sendable {
    /// Positive moments before the first ask. Three is a habit forming, not a trial.
    static let requiredValueMoments = 3
    static let minimumDaysSinceInstall = 2
    static let minimumDaysBetweenAsks = 14
    /// Apple's own ceiling; asking past it is silently ignored anyway.
    static let maximumAsks = 3

    private let store: any KeyValueStore

    init(store: any KeyValueStore) {
        self.store = store
    }

    /// Call once per launch. Records the install date on first launch.
    func recordLaunch(now: Date = .now) {
        guard store.value(forKey: .reviewFirstLaunchDate) == nil else { return }
        store.set(now, forKey: .reviewFirstLaunchDate)
    }

    /// Something went well for the user: a goal hit, a task finished, a purchase made.
    func recordValueMoment() {
        let count = store.value(forKey: .reviewValueMomentCount) ?? 0
        store.set(count + 1, forKey: .reviewValueMomentCount)
    }

    /// Whether to request a review right now.
    func shouldAsk(now: Date = .now) -> Bool {
        let askCount = store.value(forKey: .reviewAskCount) ?? 0
        guard askCount < Self.maximumAsks else { return false }

        let moments = store.value(forKey: .reviewValueMomentCount) ?? 0
        guard moments >= Self.requiredValueMoments else { return false }

        guard let firstLaunch = store.value(forKey: .reviewFirstLaunchDate),
              now.timeIntervalSince(firstLaunch) >= Self.days(Self.minimumDaysSinceInstall)
        else { return false }

        let lastAsk = store.value(forKey: .reviewLastAskDate) ?? .distantPast
        return now.timeIntervalSince(lastAsk) >= Self.days(Self.minimumDaysBetweenAsks)
    }

    /// Call immediately after requesting the review, whether or not the system showed it.
    func recordAsked(now: Date = .now) {
        store.set(now, forKey: .reviewLastAskDate)
        store.set((store.value(forKey: .reviewAskCount) ?? 0) + 1, forKey: .reviewAskCount)
    }

    private static func days(_ count: Int) -> TimeInterval {
        TimeInterval(count) * 86400
    }
}

nonisolated extension StorageKey where Value == Date {
    static var reviewFirstLaunchDate: StorageKey<Date> {
        .init("review.firstLaunchDate")
    }

    static var reviewLastAskDate: StorageKey<Date> {
        .init("review.lastAskDate")
    }
}

nonisolated extension StorageKey where Value == Int {
    static var reviewValueMomentCount: StorageKey<Int> {
        .init("review.valueMomentCount")
    }

    static var reviewAskCount: StorageKey<Int> {
        .init("review.askCount")
    }
}
