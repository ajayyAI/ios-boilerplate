//
//  HomeViewModelTests.swift
//  ScaffoldTests
//

import Testing
@testable import Scaffold

@MainActor
struct HomeViewModelTests {
    @Test func `starts empty`() {
        let viewModel = HomeViewModel(userRepository: FakeUserRepository(result: .success(User(email: "a@b.com"))))

        #expect(viewModel.state == .empty)
    }

    @Test func `refresh publishes the loaded user`() async {
        let viewModel =
            HomeViewModel(userRepository: FakeUserRepository(result: .success(User(email: "home@example.com"))))

        await viewModel.refresh()

        #expect(viewModel.state == .data(userEmailTitle: "home@example.com"))
    }

    @Test func `refresh publishes errors`() async {
        let viewModel =
            HomeViewModel(userRepository: FakeUserRepository(result: .failure(ScaffoldError(message: "Failed"))))

        await viewModel.refresh()

        #expect(viewModel.state == .failed(PresentableError(message: "Failed")))
    }
}

private struct FakeUserRepository: UserRepository {
    let result: Result<User, Error>

    func getUser() async throws -> User {
        try result.get()
    }
}
