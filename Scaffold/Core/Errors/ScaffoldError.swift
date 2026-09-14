//
//  ScaffoldError.swift
//  Scaffold
//

import Foundation

nonisolated struct ScaffoldError: Error, Sendable {
    let message: String
}

extension ScaffoldError: LocalizedError {
    var errorDescription: String? {
        message
    }
}
