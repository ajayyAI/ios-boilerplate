//
//  UserRepository.swift
//  Scaffold
//

import Foundation

/// The seam between screens and wherever users come from: view models depend on this, tests
/// hand them a fake, and swapping the backend touches only the `Data/` implementation.
nonisolated protocol UserRepository: Sendable {
    func getUser() async throws -> User
}
