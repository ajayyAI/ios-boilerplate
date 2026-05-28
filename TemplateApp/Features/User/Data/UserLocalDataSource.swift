//
//  UserLocalDataSource.swift
//  TemplateApp
//
//

import Foundation

nonisolated final class UserLocalDataSource: Sendable {
    func setUser(userEntity: UserEntity) {
        // store in DB or UserDefaults here: use UserDefaults for simple key-values, for more complex objects, use a database like CoreData or SwiftData
    }
}
