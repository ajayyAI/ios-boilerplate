//
//  UserEntity+Model.swift
//  TemplateApp
//
//

import Foundation

extension UserModel {
    nonisolated init(userEntity: UserEntity) {
        email = userEntity.email
    }
}
