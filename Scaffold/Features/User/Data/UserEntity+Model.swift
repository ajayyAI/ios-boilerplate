//
//  UserEntity+Model.swift
//  Scaffold
//

import Foundation

extension UserModel {
    nonisolated init(userEntity: UserEntity) {
        email = userEntity.email
    }
}
