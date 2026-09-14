//
//  UserEntity.swift
//  Scaffold
//

import Foundation

/// The wire shape, and what gets cached.
nonisolated struct UserEntity: Codable, Equatable, Sendable {
    let email: String
}
