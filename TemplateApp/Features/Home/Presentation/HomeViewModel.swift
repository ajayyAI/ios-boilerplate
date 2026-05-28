//
//  HomeViewModel.swift
//  TemplateApp
//
//

import Foundation

@MainActor
@Observable
final class HomeViewModel {
    var state: HomeViewState = .empty
    private let getUser: GetUserUseCase

    init(getUser: GetUserUseCase) {
        self.getUser = getUser
    }

    func refresh() async {
        do {
            state = .loading
            try await loadUser()
        } catch {
            state = .error(error)
        }
    }

    private func loadUser() async throws {
        let user = try await getUser.invoke()
        state = .data(userEmailTitle: user.email)
    }
}

extension HomeViewModel {
    static func preview() -> HomeViewModel {
        HomeViewModel(
            getUser: GetUserUseCase(
                userRepository: UserRepository(
                    userLocalDataSource: UserLocalDataSource(),
                    userRemoteDataSource: UserRemoteDataSource()
                )
            )
        )
    }
}
