//
//  TemplateAppError.swift
//  TemplateApp
//
//

import Foundation

nonisolated struct TemplateAppError: Error, Sendable {
    let message: String
}

extension TemplateAppError: LocalizedError {
    var errorDescription: String? { message }
}
