//
//  UserRemoteDataSource.swift
//  TemplateApp
//
//

import Foundation

nonisolated final class UserRemoteDataSource: Sendable {
    func getUser() async throws -> UserEntity {
        try await Task.sleep(for: .seconds(1.0))
        return UserEntity(email: "example@example.com")
    }
}
