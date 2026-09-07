//
//  StorageTests.swift
//  ScaffoldTests
//

import Foundation
import Security
import Testing
@testable import Scaffold

/// The app module defaults to `MainActor` isolation, so `KeyValueStore` and `StorageKey`
/// are main-actor isolated at the protocol surface even though both stores are
/// `nonisolated`. The test target has no such default, so it opts in explicitly.
@MainActor
struct StorageTests {
    @Test(arguments: StoreKind.allCases)
    func `round trips a bool`(kind: StoreKind) throws {
        try kind.withStore { store in
            store.set(true, forKey: .hasCompletedOnboarding)

            #expect(store.value(forKey: .hasCompletedOnboarding) == true)
        }
    }

    @Test(arguments: StoreKind.allCases)
    func `round trips a string`(kind: StoreKind) throws {
        try kind.withStore { store in
            let key = StorageKey<String>("sessionToken")

            store.set("abc123", forKey: key)

            #expect(store.value(forKey: key) == "abc123")
        }
    }

    @Test(arguments: StoreKind.allCases)
    func `round trips a codable struct`(kind: StoreKind) throws {
        try kind.withStore { store in
            let key = StorageKey<StoredPreferences>("preferences")
            let preferences = StoredPreferences(theme: "dark", launchCount: 3)

            store.set(preferences, forKey: key)

            #expect(store.value(forKey: key) == preferences)
        }
    }

    @Test(arguments: StoreKind.allCases)
    func `missing key reads as nil`(kind: StoreKind) throws {
        try kind.withStore { store in
            #expect(store.value(forKey: StorageKey<String>("neverWritten")) == nil)
        }
    }

    @Test(arguments: StoreKind.allCases)
    func `set overwrites an existing value`(kind: StoreKind) throws {
        try kind.withStore { store in
            let key = StorageKey<StoredPreferences>("preferences")

            store.set(StoredPreferences(theme: "light", launchCount: 1), forKey: key)
            store.set(StoredPreferences(theme: "dark", launchCount: 2), forKey: key)

            #expect(store.value(forKey: key) == StoredPreferences(theme: "dark", launchCount: 2))
        }
    }

    @Test(arguments: StoreKind.allCases)
    func `remove deletes the value and repeats harmlessly`(kind: StoreKind) throws {
        try kind.withStore { store in
            store.set(true, forKey: .hasCompletedOnboarding)

            store.removeValue(forKey: StorageKey<Bool>.hasCompletedOnboarding)
            store.removeValue(forKey: StorageKey<Bool>.hasCompletedOnboarding)

            #expect(store.value(forKey: .hasCompletedOnboarding) == nil)
        }
    }
}

enum StoreKind: CaseIterable, Sendable {
    case userDefaults
    case keychain

    /// Each run gets its own suite or service name so the tests never touch `.standard`,
    /// never touch the host app's keychain items, and never see each other's writes.
    @MainActor
    func withStore(_ body: (any KeyValueStore) throws -> Void) throws {
        let namespace = "com.example.Scaffold.storagetests.\(UUID().uuidString)"

        switch self {
        case .userDefaults:
            let defaults = try #require(UserDefaults(suiteName: namespace))
            defer { defaults.removePersistentDomain(forName: namespace) }
            try body(UserDefaultsKeyValueStore(defaults: defaults))

        case .keychain:
            defer { deleteKeychainItems(service: namespace) }
            try body(KeychainKeyValueStore(service: namespace))
        }
    }
}

private func deleteKeychainItems(service: String) {
    SecItemDelete([
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
    ] as CFDictionary)
}

private struct StoredPreferences: Codable, Equatable {
    let theme: String
    let launchCount: Int
}
