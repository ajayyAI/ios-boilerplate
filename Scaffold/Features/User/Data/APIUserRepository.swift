//
//  APIUserRepository.swift
//  Scaffold
//

import Foundation

/// Fetches the user from your API and keeps the last good answer for when a refresh fails.
///
/// With no `API_BASE_URL` it serves a sample instead — the same rule the rest of the starter
/// follows, no key, no vendor — so a fresh clone runs and contacts nobody. Set the URL in
/// `Config/Secrets.xcconfig` and this makes a real request, with no other change.
///
/// The cache is a `KeyValueStore` rather than SwiftData: this is one small value. Swap the
/// injected store for the Keychain one if what you cache here becomes sensitive.
final nonisolated class APIUserRepository: UserRepository {
    private let http: HTTPClient?
    private let store: any KeyValueStore

    init(http: HTTPClient?, store: any KeyValueStore) {
        self.http = http
        self.store = store
    }

    /// Remote first, cache on success, fall back to the cache on failure.
    ///
    /// Falling back is safe *here* and would not be for entitlement: showing a stale email
    /// to someone offline costs nothing, whereas showing stale entitlement gives away the
    /// product. `PaywallGate` deliberately fails the other way.
    ///
    /// With nothing cached the error propagates, which is what the Home screen renders.
    func getUser() async throws -> User {
        do {
            let user = try await fetch()
            store.set(user, forKey: .lastKnownUser)
            return user
        } catch {
            guard let cached = store.value(forKey: .lastKnownUser) else { throw error }
            return cached
        }
    }

    private func fetch() async throws -> User {
        guard let http else {
            // The sleep is what makes the loading state visible on a clone with no backend.
            try await Task.sleep(for: .seconds(1))
            return User(email: "example@example.com")
        }
        return try await http.get("user")
    }
}

nonisolated extension StorageKey where Value == User {
    static var lastKnownUser: StorageKey<User> {
        .init("lastKnownUser")
    }
}
