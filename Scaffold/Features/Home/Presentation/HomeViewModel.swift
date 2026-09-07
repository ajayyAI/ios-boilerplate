//
//  HomeViewModel.swift
//  Scaffold
//

import Foundation

@MainActor
@Observable
final class HomeViewModel {
    private(set) var state: HomeViewState = .empty

    private let getUser: GetUserUseCase

    init(getUser: GetUserUseCase) {
        self.getUser = getUser
    }

    func refresh() async {
        state = .loading
        do {
            let user = try await getUser.invoke()
            state = .data(userEmailTitle: user.email)
        } catch {
            state = .failed(PresentableError(error))
        }
    }
}

extension HomeViewModel {
    /// Seeds a view model in a fixed state for `#Preview`.
    static func preview(state: HomeViewState) -> HomeViewModel {
        let viewModel = HomeViewModel(
            getUser: GetUserUseCase(
                userRepository: UserRepository(
                    userLocalDataSource: UserLocalDataSource(store: UserDefaultsKeyValueStore()),
                    userRemoteDataSource: UserRemoteDataSource(http: nil),
                ),
            ),
        )
        viewModel.state = state
        return viewModel
    }
}
