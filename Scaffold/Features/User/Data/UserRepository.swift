//
//  UserRepository.swift
//  Scaffold
//

import Foundation

final nonisolated class UserRepository: UserRepositoryProtocol, Sendable {
    private let userLocalDataSource: UserLocalDataSource
    private let userRemoteDataSource: UserRemoteDataSource

    init(userLocalDataSource: UserLocalDataSource, userRemoteDataSource: UserRemoteDataSource) {
        self.userLocalDataSource = userLocalDataSource
        self.userRemoteDataSource = userRemoteDataSource
    }

    /// Remote first, cache on success, fall back to the cache on failure.
    ///
    /// Falling back is safe *here* and would not be for entitlement: showing a stale email
    /// to someone offline costs nothing, whereas showing stale entitlement gives away the
    /// product. `PaywallGate` deliberately fails the other way.
    ///
    /// With nothing cached the error propagates, which is what the Home screen renders.
    func getUser() async throws -> UserModel {
        do {
            let userEntity = try await userRemoteDataSource.getUser()
            userLocalDataSource.setUser(userEntity: userEntity)
            return UserModel(userEntity: userEntity)
        } catch {
            guard let cached = userLocalDataSource.user() else { throw error }
            return UserModel(userEntity: cached)
        }
    }
}
