//
//  User.swift
//  Scaffold
//

import Foundation

/// One type for the wire, the cache and the screen, because the three shapes are identical.
/// Split out a `Data/` entity with a mapping only once the API's shape stops matching this.
nonisolated struct User: Codable, Equatable, Sendable {
    let email: String
}
