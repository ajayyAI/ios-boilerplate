//
//  KeychainKeyValueStore.swift
//  Scaffold
//

import Foundation
import Security

/// `KeyValueStore` backed by the Keychain, for values that must not sit in a plist.
///
/// Values are boxed in a single-element array before encoding for the same reason as
final nonisolated class KeychainKeyValueStore: KeyValueStore, Sendable {
    private let service: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(service: String = Bundle.main.bundleIdentifier ?? "KeychainKeyValueStore") {
        self.service = service
    }

    func value<Value: Codable>(forKey key: StorageKey<Value>) -> Value? {
        var query = baseQuery(forName: key.name)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        // A key that was never written is a normal read, not a failure, so
        // `errSecItemNotFound` falls through to `nil` like any other non-success status.
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else {
            return nil
        }

        return try? decoder.decode(Value.self, from: data)
    }

    func set<Value: Codable>(_ value: Value, forKey key: StorageKey<Value>) {
        guard let data = try? encoder.encode(value) else { return }

        let query = baseQuery(forName: key.name)
        // `SecItemAdd` reports `errSecDuplicateItem` instead of overwriting, so the update
        // runs first and the add only covers the case where nothing is stored yet.
        let updateStatus = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        guard updateStatus == errSecItemNotFound else { return }

        var item = query
        item[kSecValueData as String] = data
        // Without this the item is unreadable while the device is locked, which silently
        // breaks any background work that needs it.
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(item as CFDictionary, nil)
    }

    func removeValue(forKey key: StorageKey<some Codable>) {
        // Deleting an absent item reports `errSecItemNotFound`; ignoring the status is what
        // makes removal idempotent.
        SecItemDelete(baseQuery(forName: key.name) as CFDictionary)
    }

    private func baseQuery(forName name: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: name,
        ]
    }
}
