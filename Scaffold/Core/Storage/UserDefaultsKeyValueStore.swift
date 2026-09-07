//
//  UserDefaultsKeyValueStore.swift
//  Scaffold
//

import Foundation

/// `KeyValueStore` backed by `UserDefaults`.
///
/// Everything is stored as JSON `Data` rather than as a native plist type, so one
/// code path covers every `Codable` shape instead of a switch over the handful of
/// types `UserDefaults` understands natively.
final nonisolated class UserDefaultsKeyValueStore: KeyValueStore, Sendable {
    // `UserDefaults` is documented as thread-safe, but its Objective-C header carries no
    // `Sendable` annotation for the compiler to read.
    private nonisolated(unsafe) let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func value<Value: Codable>(forKey key: StorageKey<Value>) -> Value? {
        guard let data = defaults.data(forKey: key.name) else { return nil }
        return try? decoder.decode(Value.self, from: data)
    }

    func set<Value: Codable>(_ value: Value, forKey key: StorageKey<Value>) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key.name)
    }

    func removeValue(forKey key: StorageKey<some Codable>) {
        defaults.removeObject(forKey: key.name)
    }
}
