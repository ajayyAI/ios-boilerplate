//
//  UserRepository.swift
//  TemplateApp
//
//

import Foundation

nonisolated final class UserRepository: UserRepositoryProtocol, Sendable {
    private let userLocalDataSource: UserLocalDataSource
    private let userRemoteDataSource: UserRemoteDataSource

    init(userLocalDataSource: UserLocalDataSource, userRemoteDataSource: UserRemoteDataSource) {
        self.userLocalDataSource = userLocalDataSource
        self.userRemoteDataSource = userRemoteDataSource
    }

    func getUser() async throws -> UserModel {
        let userEntity = try await userRemoteDataSource.getUser()
        userLocalDataSource.setUser(userEntity: userEntity)
        let user = UserModel(userEntity: userEntity)
        return user
    }
}
