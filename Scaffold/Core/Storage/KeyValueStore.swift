//
//  KeyValueStore.swift
//  Scaffold
//

import Foundation

/// Typed key-value persistence.
///
/// `nonisolated` because storage has no business being main-actor bound: repositories and
/// data sources read it off the main thread, and both backing stores are thread-safe.
///
/// iOS needs no third-party fast-storage dependency: `UserDefaults` is already a
/// fast native synchronous store, and Keychain covers anything secret. Structured
/// data belongs in SwiftData rather than here.
nonisolated protocol KeyValueStore: Sendable {
    func value<Value: Codable>(forKey key: StorageKey<Value>) -> Value?
    func set<Value: Codable>(_ value: Value, forKey key: StorageKey<Value>)
    func removeValue(forKey key: StorageKey<some Codable>)
}

/// A namespaced, type-carrying storage key.
///
/// The phantom `Value` is what stops a `Bool` being written where an `Int` is read;
/// the compiler rejects it rather than the value silently failing to decode.
nonisolated struct StorageKey<Value: Codable>: Sendable {
    let name: String

    init(_ name: String) {
        self.name = name
    }
}

nonisolated extension StorageKey where Value == Bool {
    static var hasCompletedOnboarding: StorageKey<Bool> {
        .init("hasCompletedOnboarding")
    }
}
