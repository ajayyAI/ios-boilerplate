//
//  InMemoryStore.swift
//  ScaffoldTests
//

import Foundation
@testable import Scaffold

/// A `KeyValueStore` that forgets everything when the test ends.
final class InMemoryStore: KeyValueStore, @unchecked Sendable {
    private var storage: [String: Data] = [:]
    private let lock = NSLock()

    func value<Value: Codable>(forKey key: StorageKey<Value>) -> Value? {
        lock.withLock { storage[key.name] }.flatMap { try? JSONDecoder().decode(Value.self, from: $0) }
    }

    func set<Value: Codable>(_ value: Value, forKey key: StorageKey<Value>) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        lock.withLock { storage[key.name] = data }
    }

    func removeValue(forKey key: StorageKey<some Codable>) {
        lock.withLock { storage[key.name] = nil }
    }
}
