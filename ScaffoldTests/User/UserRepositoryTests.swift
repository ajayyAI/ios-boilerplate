//
//  UserRepositoryTests.swift
//  ScaffoldTests
//

import Foundation
import Testing
@testable import Scaffold

/// The repository's one decision: what a failed refresh shows. Falling back to the cache is
/// right for a profile and would be wrong for entitlement, so it is worth pinning down.
///
/// Driven through a real `HTTPClient` against a stubbed `URLProtocol`, so the request, the
/// status check and the cache are all the shipping code.
struct UserRepositoryTests {
    @Test func `a successful read is cached`() async throws {
        let store = InMemoryStore()

        _ = try await Self.repository(store: store, host: "api.test").getUser()

        #expect(store.value(forKey: .lastKnownUser) == User(email: StubURLProtocol.email))
    }

    @Test func `a failed read falls back to the cache`() async throws {
        let store = InMemoryStore()
        store.set(User(email: "cached@example.com"), forKey: .lastKnownUser)

        let user = try await Self.repository(store: store, host: "status-500.test").getUser()

        #expect(user.email == "cached@example.com")
    }

    /// Nothing cached means the error has to reach the screen. Swallowing it would render an
    /// empty state that looks like a user with no email.
    @Test func `a failed read with nothing cached throws`() async throws {
        let repository = try Self.repository(store: InMemoryStore(), host: "status-500.test")

        await #expect(throws: HTTPError.status(500)) {
            try await repository.getUser()
        }
    }

    @Test func `a later success replaces the cached user`() async throws {
        let store = InMemoryStore()
        store.set(User(email: "stale@example.com"), forKey: .lastKnownUser)

        let user = try await Self.repository(store: store, host: "api.test").getUser()

        #expect(user.email == StubURLProtocol.email)
        #expect(store.value(forKey: .lastKnownUser) == User(email: StubURLProtocol.email))
    }

    private static func repository(store: any KeyValueStore, host: String) throws -> APIUserRepository {
        let http = try HTTPClient(
            baseURL: #require(URL(string: "https://\(host)")),
            userAgent: "Test/1.0",
            session: StubURLProtocol.session(),
        )
        return APIUserRepository(http: http, store: store)
    }
}
