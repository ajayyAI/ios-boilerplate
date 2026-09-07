//
//  UserRemoteDataSource.swift
//  Scaffold
//

import Foundation

/// Fetches the user from your API, or serves a sample when there is no API configured.
///
/// The sample branch is the same rule the rest of the starter follows — no key, no vendor —
/// so a fresh clone runs and contacts nobody. Set `API_BASE_URL` in `Config/Secrets.xcconfig`
/// and this makes a real request instead, with no other change.
final nonisolated class UserRemoteDataSource: Sendable {
    private let http: HTTPClient?

    init(http: HTTPClient?) {
        self.http = http
    }

    func getUser() async throws -> UserEntity {
        guard let http else {
            // The sleep is what makes the loading state visible on a clone with no backend.
            try await Task.sleep(for: .seconds(1))
            return UserEntity(email: "example@example.com")
        }
        return try await http.get("user")
    }
}
