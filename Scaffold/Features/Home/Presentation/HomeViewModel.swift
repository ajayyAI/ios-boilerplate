//
//  HomeViewModel.swift
//  Scaffold
//

import Foundation

@MainActor
@Observable
final class HomeViewModel {
    private(set) var state: HomeViewState = .empty

    private let userRepository: any UserRepository
    private let crashReporter: any CrashReporter

    init(userRepository: any UserRepository, crashReporter: any CrashReporter = NoOpCrashReporter()) {
        self.userRepository = userRepository
        self.crashReporter = crashReporter
    }

    func refresh() async {
        state = .loading
        do {
            let user = try await userRepository.getUser()
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
            userRepository: APIUserRepository(http: nil, store: UserDefaultsKeyValueStore()),
        )
        viewModel.state = state
        return viewModel
    }
}
