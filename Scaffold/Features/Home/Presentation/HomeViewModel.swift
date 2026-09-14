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
    private let crashReporter: any CrashReporter

    init(getUser: GetUserUseCase, crashReporter: any CrashReporter = NoOpCrashReporter()) {
        self.getUser = getUser
        self.crashReporter = crashReporter
    }

    func refresh() async {
        state = .loading
        do {
            let user = try await getUser.invoke()
            state = .data(userEmailTitle: user.email)
        } catch {
            // Rendering the error is for the user; reporting it is for whoever has to
            // fix it. A caught error that is only rendered is invisible in production.
            crashReporter.report(error, context: "Home.refresh")
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
