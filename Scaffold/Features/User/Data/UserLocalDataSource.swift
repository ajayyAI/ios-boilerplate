//
//  UserLocalDataSource.swift
//  Scaffold
//

import Foundation

/// The last user the API returned, kept so a failed refresh has something to show.
///
/// `KeyValueStore` rather than SwiftData: this is one small value, and `UserDefaults`
/// is already a fast native store. Swap the injected store for the Keychain one if what
/// you cache here becomes sensitive.
final nonisolated class UserLocalDataSource: Sendable {
    private let store: any KeyValueStore

    init(store: any KeyValueStore) {
        self.store = store
    }

    func user() -> UserEntity? {
        store.value(forKey: .lastKnownUser)
    }

    func setUser(userEntity: UserEntity) {
        store.set(userEntity, forKey: .lastKnownUser)
    }
}

nonisolated extension StorageKey where Value == UserEntity {
    static var lastKnownUser: StorageKey<UserEntity> {
        .init("lastKnownUser")
    }
}
