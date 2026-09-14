//
//  UserRepositoryProtocol.swift
//  Scaffold
//

import Foundation

nonisolated protocol UserRepositoryProtocol: Sendable {
    func getUser() async throws -> UserModel
}
