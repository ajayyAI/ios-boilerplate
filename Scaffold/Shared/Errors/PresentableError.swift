//
//  PresentableError.swift
//  Scaffold
//

import Foundation

/// A domain error flattened to what the UI actually renders.
///
/// `Error` is not `Equatable`, so carrying one directly would forfeit the
/// invalidation skip above. Converting at the presentation boundary is the view
/// model's job anyway.
struct PresentableError: Error, Equatable {
    let message: String

    init(_ error: some Error) {
        message = error.localizedDescription
    }

    init(message: String) {
        self.message = message
    }
}

extension PresentableError: LocalizedError {
    var errorDescription: String? {
        message
    }
}
