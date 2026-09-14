//
//  GetUserUseCase.swift
//  Scaffold
//

import Foundation

final nonisolated class GetUserUseCase: Sendable {
    private let userRepository: UserRepositoryProtocol

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    func invoke() async throws -> UserModel {
        try await userRepository.getUser()
    }
}
